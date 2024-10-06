#!/usr/bin/bash

if [ -z "$1" ]
  then
    echo "Usage: docker-publish-image.sh [repository-url]"
    exit
fi

docker login "${1%%/*}"

if [ ! -s ".keystore-password" ]
then
  install -m 600 <(openssl rand -base64 32) .keystore-password
fi

docker build \
  --build-arg KEYSTORE_PASSWORD=$(cat .keystore-password) \
  --build-arg KEY_PASSWORD=$(cat .keystore-password) \
  -t pwa-to-fdroid .

docker tag pwa-to-fdroid $1:latest
docker push $1:latest

if git describe --tags --abbrev=0 &>/dev/null;
  then
    docker tag pwa-to-fdroid $1:$(git describe --tags --abbrev=0)
    docker push $1:$(git describe --tags --abbrev=0)
fi

docker rmi -f $(docker images --filter=reference="*pwa-to-fdroid" -q)