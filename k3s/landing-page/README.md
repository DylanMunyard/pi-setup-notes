# Build the Docker image
```
docker buildx build \
--platform linux/arm64 \
-t dylanmunyard/pi-landing-page:0.1 . \
--push
```

# What is it
An NGINX container serving a static web page found in [www](www). \
Served over port 8097 in the cluster, and is the default backend to the haproxy.

Folowed https://docs.nginx.com/nginx/admin-guide/web-server/serving-static-content/