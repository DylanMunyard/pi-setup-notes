# SSL renewal 
`job.yaml` is a Kube job that runs certbot/google-dns using TXT validation in GCP. 

Followed this guide: https://russt.me/2018/04/wildcard-lets-encrypt-certificates-with-certbot/

Store the .json creds as a secret: `kubectl create secret generic certbot-gcp-access --from-file=gcp-access.json=elbanyo-dcf4bff0c92c.json -n certbot`