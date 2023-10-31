#!/bin/bash
set -e;

ipv6Regex="(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))"

# DSM Config
username="$1"
password="$2"
hostname="$3"
ipAddr="$4"

recType6="AAAA"

# Fetch and filter IPv6, if Synology won't provide it
ip6fetch=$(ip -6 addr show eth0 | grep -oP "$ipv6Regex" || true)
ip6Addr=$(if [ -z "$ip6fetch" ]; then echo ""; else echo "${ip6fetch:0:$((${#ip6fetch})) - 7}"; fi) # in case of NULL, echo NULL

if [[ -z "$ip6Addr" ]]; then
	echo "No IPv6 address found."
	exit 1
fi

# Cloudflare API-Calls for listing and updating DNS entries
listDnsv6Api="https://api.cloudflare.com/client/v4/zones/${username}/dns_records?type=${recType6}&name=${hostname}"
createDnsApi="https://api.cloudflare.com/client/v4/zones/${username}/dns_records"

# List existing DNS records
resv6=$(curl -s -X GET "$listDnsv6Api" -H "Authorization: Bearer $password" -H "Content-Type:application/json");
resv6Success=$(echo "$resv6" | jq -r ".success");

if [[ $resv6Success != "true" ]]; then
    echo "badauth";
    exit 1;
fi

recordIdv6=$(echo "$resv6" | jq -r ".result[0].id");
recordIpv6=$(echo "$resv6" | jq -r ".result[0].content");
recordProxv6=$(echo "$resv6" | jq -r ".result[0].proxied");

# Update or create DNS record
if [[ $recordIpv6 = "$ip6Addr" ]]; then
    echo "nochg";
    exit 0;
elif [[ $recordIdv6 = "null" ]]; then
    # IPv6 Record not exists, create new record
    res6=$(curl -s -X POST "$createDnsApi" -H "Authorization: Bearer $password" -H "Content-Type:application/json" --data "{\"type\":\"$recType6\",\"name\":\"$hostname\",\"content\":\"$ip6Addr\",\"proxied\":false}")
else
    # IPv6 Record exists, update existing record
    update6DnsApi="https://api.cloudflare.com/client/v4/zones/${username}/dns_records/${recordIdv6}"
    res6=$(curl -s -X PUT "$update6DnsApi" -H "Authorization: Bearer $password" -H "Content-Type:application/json" --data "{\"type\":\"$recType6\",\"name\":\"$hostname\",\"content\":\"$ip6Addr\",\"proxied\":false}")
fi

res6Success=$(echo "$res6" | jq -r ".success")

if [[ $res6Success = "true" ]]; then
    echo "good";
else
    echo "badauth";
fi
