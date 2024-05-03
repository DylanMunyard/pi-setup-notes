# Serving SSL certificate  
The SSL certificate for munyard.dev is mapped from a ConfigMap into `/certs`. 

From the Plex UI > Settings > Network set the path of Custom certificate location to `/certs/elbanyo.pks`

Generate the p12 from the LetsEncryp PEM:

`openssl pkcs12 -export -out elbanyo.p12 -in fullchain.pem -inkey privkey.pem`

Import into the cluster as a ConfigMap:

`kubectl create cm banners-cert --from-file=elbanyo.p12 -n plex-server`