# HAProxy
Reverse proxy operating on the edge (munyard.dev), proxies to the stuff running inside network.

## Generate a self signed certificate
Set SSL/TLS mode to 'Full' (not strict!). Allows CloudFlare to accept self signed certificate.

Generate the SSL cert:

```sh
kubectl create namespace cert-manager
kubectl apply --validate=false -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.3/cert-manager.yaml


cat ss-issuer.yaml << EOF 
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer
spec:
  selfSigned: {}
EOF

kubectl apply -f ss-issuer.yaml

cat > ss-certificate.yaml << EOF 
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: munyard-dev-tls
  namespace: ha-proxy
spec:
  secretName: munyard-dev-tls
  dnsNames:
  - "munyard.dev"
  issuerRef:
    name: selfsigned-issuer
    kind: ClusterIssuer
EOF

kubectl apply -f ss-certificate.yaml
```

## (Obsolete) Generate signed certificate
(Back when we hosted on GCP)
ewal
The SSL cert for munyard.dev is auto renewed by the [cronjob.yaml](cronjob.yaml). Followed this guide: https://russt.me/2018/04/wildcard-lets-encrypt-certificates-with-certbot/

- Create a secret from the GCP credentials `kubectl create secret generic gcp-credentials --from-file credentials.json=./elbanyo-c215a55008fe.json --namespace ha-proxy`
- Deploy the cronjob `kubectl apply -f cronjob.yaml`

### What does it do
The CronJob runs at midnight on the first day of Feb, April, June, August, October, December. 

It uses certbot to request an SSL certificate for munyard.dev and all sub domains. 

After the certificate is issued, the CronJob will deploy the certificate to a ConfigMap called `ha-proxy-certs` which is mounted by the ha-proxy container to access the SSL certificate.

## 3. Deploy ha-proxy config
`kubectl apply -f config.yaml`

Config needs to end with a empty newline.

# 4. Deploy ha-proxy
`kubectl apply -f deployment.yaml`
