# Synology Cloudflare DDNS Script 📜

这个版本用来解决某大内网只有公网IPV6 没有公网IPV4的问题
众所周知 如果同时上报IPV4和V6 双栈会选择延迟较低的那个(或者其他规则 总之获取不到准确的地址) 而对外显示的IPV4基本上都是NAT过的 

脚本用法和之前一致 区别是没有获得IPV4的解析 只上报IPV6

## How to use

### Access Synology via SSH

1. Login to your DSM
2. Go to Control Panel > Terminal & SNMP > Enable SSH service
3. Use your client to access Synology via SSH.
4. Use your Synology admin account to connect.

### Run commands in Synology

1. Download `cloudflareddns.sh` from this repository to `/sbin/cloudflareddns.sh`

```
wget https://raw.githubusercontent.com/sirstrone/SynologyCloudflareDDNS_IPV6Only/master/cloudflareddns.sh -O /sbin/cloudflareddns.sh 
```

It is not a must, you can put I whatever you want. If you put the script in other name or path, make sure you use the right path.

2. Give others execute permission

```
chmod +x /sbin/cloudflareddns.sh
```

3. Add `cloudflareddns.sh` to Synology

```
cat >> /etc.defaults/ddns_provider.conf << 'EOF'
[Cloudflare]
        modulepath=/sbin/cloudflareddns.sh
        queryurl=https://www.cloudflare.com
        website=https://www.cloudflare.com
E*.
```

`queryurl` does not matter because we are going to use our script but it is needed.

### Get Cloudflare parameters

1. Go to your domain overview page and copy your zone ID.
2. Go to your profile > **API Tokens** > **Create Token**. It should have the permissions of `Zone > DNS > Edit`. Copy the api token.

### Setup DDNS

1. Login to your DSM
2. Go to Control Panel > External Access > DDNS > Add
3. Enter the following:
   - Service provider: `Cloudflare`
   - Hostname: `www.example.com`
   - Username/Email: `<Zone ID>`
   - Password Key: `<API Token>`
