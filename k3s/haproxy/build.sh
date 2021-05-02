#!/bin/bash

if [ -z $1 ]; then
    echo "build.sh tag_number"
    echo "e.g. build.sh 0.9 will create image dylanmunyard/ha-proxy-pi:0.9"
    exit 1
fi

docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

docker buildx build \
--platform linux/arm64 \
-t "dylanmunyard/ha-proxy-pi:$1" . \
--push

sed -i "s|image: dylanmunyard.*|image: dylanmunyard/ha-proxy-pi:${1}|g" deployment.yaml
kubectl apply -f deployment.yaml