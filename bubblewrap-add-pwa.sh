#!/usr/bin/bash

[ "$UID" -eq 0 ] || exec sudo "$0" "$@"

if [ -z "$1" ]
  then
    echo "Usage: bubblewrap-add-wpa.sh [manifest-url]"
    exit
fi

BUBBLEWRAP_IMAGE=$(grep '^FROM .*\/bubblewrap:.*$' Dockerfile | awk '{print $2}')
KEYSTORE_VOLUME=()
if [[ -f "keystore.p12" ]]; then
  KEYSTORE_VOLUME=(-v "$(pwd)"/keystore.p12:/app/android.keystore)
fi

docker run -it \
  --rm \
  --network host \
  -v ./app-manifests/.tmp:/app \
  "${KEYSTORE_VOLUME[@]}" \
  "$BUBBLEWRAP_IMAGE" init \
    --manifest="$1" \
    --directory="/app"

APP_NAME=$(cat ./app-manifests/.tmp/twa-manifest.json | jq -r '.launcherName' | tr '[:upper:]' '[:lower:]')

cp ./app-manifests/.tmp/twa-manifest.json ./app-manifests/"$APP_NAME".json

if [[ ! -f "keystore.p12" ]]; then
  cp ./app-manifests/.tmp/android.keystore ./keystore.p12
  echo "KEYSTORE_B64=$(base64 -w 0 keystore.p12)"
fi

rm -rf ./app-manifests/.tmp