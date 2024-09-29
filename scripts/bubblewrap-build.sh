for file in /app-manifests/*.json; do
    mkdir -p /app/$(basename $file .json)
    ln -sf $file /app/$(basename $file .json)/twa-manifest.json
    cd /app/$(basename $file .json)
    bubblewrap update
    echo y | bubblewrap build --signingKeyPath /repo/keystore.p12 --signingKeyAlias $KEY_ALIAS
    fingerprint=$(keytool -list -keystore /repo/keystore.p12 -storetype PKCS12 -storepass $KEYSTORE_PASSWORD  | grep -A 1 'SHA-256' | sed 's/.*(SHA-256): //')
    bubblewrap fingerprint --manifest=$(pwd)/twa-manifest.json add $fingerprint
    bubblewrap fingerprint --manifest=$(pwd)/twa-manifest.json generateAssetLinks
    cp app-release-signed.apk /repo/repo/$(basename $file .json).apk
    mkdir -p /repo/repo/$(basename $file .json)
    cp assetlinks.json /repo/repo/$(basename $file .json)/assetlinks.json
done