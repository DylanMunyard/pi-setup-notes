# Reverse Proxy
To achieve pretty URLS like localhost/emby, instead of kube-master:8096
I've set up an HAProxy with reverse proxy settings:

tldr; summary:
- in `/etc/hosts/` add subdomain aliases for each service: \
  `127.0.1.1	teamcity.localhost`
- `bind` is the port to access it (localhost:8080). 
- then add `use_backend` lines for each service in the cluster

```config
frontend k3s

# Set the proxy mode to http (layer 7) or tcp (layer 4)
mode http

# Receive HTTP traffic on all IP addresses assigned to the server at port 80
bind *:8080

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