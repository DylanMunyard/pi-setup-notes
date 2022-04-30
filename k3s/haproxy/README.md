# HAProxy
Reverse proxy operating on the edge (dylanmyard.dev), proxies to the stuff running inside network.

# Deploy the namespace
`kubectl apply -f namespace.yaml`

# haproxy.cfg
Deploy haproxy.cfg to cluster as config map

`kubectl create cm ha-proxy-cfg --from-file=haproxy.cfg -n ha-proxy`

The file needs to end with a empty newline.

# SSL
Followed this guide: https://russt.me/2018/04/wildcard-lets-encrypt-certificates-with-certbot/

```bash
docker run \
    -u root \
    -v "$PWD:/var/log/"  \
    -v "/home/dylan/Downloads:/gcp" \
    -v "$PWD:/etc/letsencrypt" \
    certbot/dns-google certonly --dns-google --dns-google-credentials /gcp/elbanyo-e7173437338c.json -d dylanmyard.dev,plex.dylanmyard.dev,qb.dylanmyard.dev,www.dylanmyard.dev --agree-tos --email dmunyard@gmail.com --non-interactive
```

Combine the private and public key into one file:
```bash
export DOMAIN='dylanmyard.dev' 
cat $PWD/live/$DOMAIN/fullchain.pem $PWD/live/$DOMAIN/privkey.pem > $DOMAIN.pem
```

## Deploy to Kube
1. Create the ConfigMap containing the certificate data \
`kubectl create cm ha-proxy-certs --from-file=$DOMAIN.pem -n ha-proxy`
2. Deploy the rest \
`kubectl apply -f deployment.yaml -f service.yaml`