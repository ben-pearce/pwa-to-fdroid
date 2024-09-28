sudo docker run --rm -v ./app-manifests/.tmp:/app -ti ghcr.io/googlechromelabs/bubblewrap:latest init --manifest="$1" --directory="/app"
sudo cp ./app-manifests/.tmp/twa-manifest.json ./app-manifests/$(cat ./app-manifests/.tmp/twa-manifest.json | jq -r '.launcherName' | tr '[:upper:]' '[:lower:]').json
sudo rm -rf ./app-manifests/.tmp