# Build the Docker image
```
docker buildx build \
--platform linux/arm64 \
-t dylanmunyard/ha-proxy-pi:0.7 . \
--push
```

Push it `docker push `

To test if `haproxy.cfg` is valid before pushing, run the image interactively using the haproxy command: \
```
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
docker run --it --rm --name ha-proxy-local dylanmunyard/ha-proxy-pi:0.3 haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg
```

## Note about haproxy.cfg
It has to terminate with a new line, or you get this in the log:
```bash
[ALERT] 055/162401 (1) : parsing [/usr/local/etc/haproxy/haproxy.cfg:51]: Missing LF on last line, file might have been truncat │
[ALERT] 055/162401 (1) : Error(s) found in configuration file : /usr/local/etc/haproxy/haproxy.cfg 
```

# Configuring SSL
Followed: https://www.digitalocean.com/community/tutorials/how-to-secure-haproxy-with-let-s-encrypt-on-ubuntu-14-04

__NOTE:__ This uses the SSL certificate that was created by letsencrypt. [Instructions](EDGE.md).

Combine the private and public key into one file:
```bash
mkdir /etc/haproxy/certs
DOMAIN='elbanyo.net' sudo -E bash -c 'cat /etc/letsencrypt/live/$DOMAIN/fullchain.pem /etc/letsencrypt/live/$DOMAIN/privkey.pem > /etc/haproxy/certs/$DOMAIN.pem'
```

# Deployment
[haproxy.cfg](haproxy.cfg) listens on port 443 in the container and is configured
to sign requests with the elbanyo.net.pem private key pair. \
Since this is sensitive information we __must not__ bake them into the Docker image. \
So the certificate is created as a ConfigMap resource, then mounted into the container
using a volumeMount.. 

1. Apply the namespace only `kubectl apply -f namespace.yaml`
2. Create the ConfigMap containing the certificate data
`kubectl create cm ha-proxy-certs --from-file=/etc/haproxy/certs/elbanyo.net.pem -n ha-proxy`
3. Deploy everything else `kubectl apply -f deployment.yaml -f service.yaml`

# Reverse Proxy
To achieve pretty URLS like localhost/emby, instead of kube-master:8096
I've set up an HAProxy with reverse proxy settings:

tldr; summary:
- in `/etc/hosts/` add subdomain aliases for each service: \
  `127.0.1.1	teamcity.localhost`
- `bind` is the port to access it (localhost:8080). 
- then add `use_backend` lines for each service in the cluster

```
global:
  tune.ssl.default-dh-param 2048
  option forwardfor
  option http-server-close
  
frontend k3s
  # Set the proxy mode to http (layer 7) or tcp (layer 4)
  mode http
  
  # Receive HTTP traffic on all IP addresses assigned to the server at port 8080
  bind *:8080
  
  #
  
  use_backend emby if { req.hdr(host) -i emby.localhost:8080 }
  
  use_backend teamcity if { req.hdr(host) -i teamcity.localhost:8080 }
  
  use_backend arm-core if { req.hdr(host) -i arm-core.localhost:8080 }
  
  use_backend dashboard if { req.hdr(host) -i dashboard.localhost:8080 }
  
  # Choose the default pool of backend servers
  default_backend emby
  
backend emby
  mode http
  balance roundrobin
  
  # Enable HTTP health checks
  option httpchk
  
  server level1 192.168.86.220:8096 check
  
backend teamcity
  mode http
  balance roundrobin
  
  # Enable HTTP health checks
  option httpchk
  http-check expect status 401
  
  server level1 192.168.86.220:8111 check
  
backend arm-core
  mode http
  balance roundrobin
  
  # Enable HTTP health checks
  option httpchk GET /api
  
  server level1 192.168.86.220:17883 check
  
backend dashboard
  mode http
  balance roundrobin
  
  # Enable HTTP health checks
  option ssl-hello-chk
  
  server level1 192.168.86.220:18443 check
  http-request add-header Authorization "Bearer <token>"
```

The `<token>` for Kubernetes dashboard comes from `kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}"` 