# haproxy custom image
```
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

docker buildx build \
--platform linux/arm64 \
-t dylanmunyard/ha-proxy-pi:0.9 . \
--push
```