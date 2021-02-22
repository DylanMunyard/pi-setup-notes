# Running TeamCity Server on a Pi
I forked https://github.com/JetBrains/teamcity-docker-images, and added support for ARM
https://github.com/DylanMunyard/teamcity-docker-images/commit/7e9a718598793a5b49e487ca6065182ce743b55f

The only change was to add `openjdk-8-jre` to the `apt-get` list, and to delete
Amazon Corretto JRE from the Dockerfile. The AWS JRE doesn't support ARM architectures yet. 

Clone `https://github.com/DylanMunyard/teamcity-docker-images.git`

Run the following commands from the cloned repo
- `git checkout arm64`
- `curl -o teamcity.tar.gz https://download-cf.jetbrains.com/teamcity/TeamCity-2020.2.2.tar.gz && tar xvzf teamcity.tar.gz -C context && rm -f teamcity.tar.gz`
- `./generate.sh`

This places a ready to build Dockerfile under 
`generated/linux/Server/Ubuntu/20.04-openjdk`

Then use `buildx` to build it for Arm \
```bash
docker buildx build \
    -f "generated/linux/Server/Ubuntu/20.04-openjdk/Dockerfile" \
    --platform linux/arm64 \
    -t dylanmunyard/teamcity-server:arm "context" \
    --load
```

To push the image to Dockerhub:
`docker push dylanmunyard/teamcity-server:arm`

## Observations
I think Java uses JIT, because for the first few minutes TC is using up
all four cores at 100%. 

![100% CPU usage](diagnostics.png)

But after clicking around, it reduces to about 1.5Mi (1 and a half cores)