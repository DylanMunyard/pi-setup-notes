# Adding internet ingress to Pi services

## Use a domain name
https://cloud.google.com/dns/docs/tutorials/create-domain-tutorial#set-up-domain \
__Relevant steps__
- Step 1 - Purchased elbanyo.net
- Step 4 - Set up the domain to be managed by Google Cloud DNS. 
  > Why? Will come with edge protection against things like DDOS. Also integrates nicely with load balancer used to expose Pi to web. 
- Step 5 - Update DNS settings in Google Domain to reference Google Cloud DNS.

## Configure a load balancer
Load balancer is the 'front end' for the Pi. Requests to elbanyo.net will 
arrive at the load balancer. It will simply forward on the request to the Pi, by opening a
secure connection to the Pi. 

- Edit the load balancer, and specify the Frontend configuration as follows:
  
  | __Setting__ |  __Value__  |
  |:-----|--------:|
  | Protocol | HTTPS |
  | Port | 443 |
  | Certificate | Create a certificate |

- The load balancer supports up to 14 SSL certificates, and serves the one according to the requested domain name.<br /> 
E.g. if a request comes in for teamcity.elbanyo.net, it serves the SSL certificate with teamcity
in the common name.<br />
Create one certificate per sub-domain. I don't think it's possible to update an SSL certificate once it's created, 
  so new domains can't be added easily. Therefore to help create track I've decided to create one certificate per sub domain.
  
In summary, the load balancer serves up the SSL certificate to the requesting client. \
The LB terminates the connection, and opens a new one with the Pi at 
`ratden.elbanyo.net` over port 445. 445 is opened on the Google Nest and forwards
to port 8443 on the Pi. 8443 corresponds to the service port of [HAProxy](k3s/haproxy/PROXY.md). <br />
HAProxy is configured to only accept SSL connections on 443 (inside the container), and serves it's own certificate signed by letsencrypt for `*.elbanyo.net`.

## Generate an SSL certificate for the domain
Followed https://www.geeksforgeeks.org/using-certbot-manually-for-ssl-certificates/
```
sudo certbot certonly \
--manual \
--agree-tos \
--preferred-challenges dns-01 \
--server https://acme-v02.api.letsencrypt.org/directory \
--register-unsafely-without-email \
--rsa-key-size 4096 \
-d *.elbanyo.net -d elbanyo.net 
```

This is going to ask me to verify I own the domain name by adding DNS TXT records:

| DNS Name |  Type  | Text |
|:-----|--------:|:------|
|  _acme-challenge.elbanyo.net. | TXT | Copy and paste from the output of `certbot`. |

certbot will verify the domain twice, once for each domains (wildcard and the non-wildcard). 

In Google Cloud DNS you can't add multiple TXT records for the same DNS name 
(even though in certbot it says this is permitted by DNS standards). 

So when verifying the second domain, simply override the existing TXT record. 
HOWEVER make sure TTL was set to 0 seconds on the first verification, otherwise the 
second request will get the cached response for the first request.

Once verified, certbot writes the pub / priv pair to `/etc/letsencrypt/live/elbanyo.net`

## Configure HAProxy to use SSL certificate
Continue reading [proxy instructions](k3s/haproxy/PROXY.md)