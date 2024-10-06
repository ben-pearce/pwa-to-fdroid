#!/usr/bin/sudo bash

if [ -z "$1" ]
  then
    echo "Usage: bubblewrap-add-wpa.sh [manifest-url]"
    exit
fi

docker run --rm -v ./app-manifests/.tmp:/app -ti ghcr.io/googlechromelabs/bubblewrap:latest init --manifest="$1" --directory="/app"
cp ./app-manifests/.tmp/twa-manifest.json ./app-manifests/$(cat ./app-manifests/.tmp/twa-manifest.json | jq -r '.launcherName' | tr '[:upper:]' '[:lower:]').json
rm -rf ./app-manifests/.tmp