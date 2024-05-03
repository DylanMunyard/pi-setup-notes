# HAProxy
Reverse proxy operating on the edge (munyard.dev), proxies to the stuff running inside network.

## 1. Deploy the namespace
`kubectl apply -f namespace.yaml`

## 2. Deploy certbot SSL renewal
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
