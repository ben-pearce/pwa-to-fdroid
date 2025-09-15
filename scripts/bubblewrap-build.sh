#!/bin/bash

export KEY_ALIAS
export BUBBLEWRAP_KEYSTORE_PASSWORD
export BUBBLEWRAP_KEY_PASSWORD

KEY_ALIAS=$(cat /run/secrets/key_alias)
BUBBLEWRAP_KEYSTORE_PASSWORD=$(cat /run/secrets/keystore_password)
BUBBLEWRAP_KEY_PASSWORD=$(cat /run/secrets/key_password)

for file in /app-manifests/*.json; do
    app_name=$(basename "$file" .json)
    mkdir -p /app/"$app_name"
    ln -sf "$file" /app/"$app_name"/twa-manifest.json
    cd /app/"$app_name" || exit
    bubblewrap update --skipVersionUpgrade
    echo y | bubblewrap build --signingKeyPath /repo/keystore.p12 --signingKeyAlias "$KEY_ALIAS"
    fingerprint=$(keytool -list -keystore /repo/keystore.p12 -storetype PKCS12 -storepass "$BUBBLEWRAP_KEYSTORE_PASSWORD" | grep -A 1 'SHA-256' | sed 's/.*(SHA-256): //')
    bubblewrap fingerprint --manifest="$(pwd)"/twa-manifest.json add "$fingerprint"
    bubblewrap fingerprint --manifest="$(pwd)"/twa-manifest.json generateAssetLinks
    cp app-release-signed.apk /repo/repo/"$app_name".apk
    mkdir -p /repo/repo/"$app_name"
    cp assetlinks.json /repo/repo/"$app_name"/assetlinks.json
done
