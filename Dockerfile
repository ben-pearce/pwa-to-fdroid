ARG ANDROGUARD_VERSION="4.1.3"
ARG ANDROGUARD_URL="https://github.com/androguard/androguard/archive/refs/tags/v${ANDROGUARD_VERSION}.tar.gz"
ARG FDROID_REPO_URL="https://fdroid.example.com/repo"
ARG FDROID_REPO_NAME="F-Droid Repository"
ARG FDROID_ARCHIVE_URL="https://fdroid.benpearce.io/archive"
ARG FDROID_ARCHIVE_NAME="F-Droid Repository Archive"

FROM registry.gitlab.com/fdroid/docker-executable-fdroidserver:latest@sha256:2ad114edee50aad92fcc83fe7d801d8922780a021db070ae9f4c49f6f647c037 AS fdroid
ARG ANDROGUARD_VERSION
ARG ANDROGUARD_URL

RUN apt-get update && apt-get -y install python3-pip
RUN curl -s -L ${ANDROGUARD_URL} | tar xfz - -C .
RUN pip install ./androguard-${ANDROGUARD_VERSION} --break-system-packages

FROM fdroid AS repository-base
ARG FDROID_REPO_URL
ARG FDROID_REPO_NAME
ARG FDROID_ARCHIVE_URL
ARG FDROID_ARCHIVE_NAME

COPY templates/fdroid/config.yml /repo/config.yml
COPY ./*.p12 /repo/
RUN sed -i "s|FDROID_REPO_URL|$FDROID_REPO_URL|g" /repo/config.yml
RUN sed -i "s|FDROID_REPO_NAME|$FDROID_REPO_NAME|g" /repo/config.yml
RUN sed -i "s|FDROID_ARCHIVE_URL|$FDROID_ARCHIVE_URL|g" /repo/config.yml
RUN sed -i "s|FDROID_ARCHIVE_NAME|$FDROID_ARCHIVE_NAME|g" /repo/config.yml
RUN --mount=type=secret,id=key_alias \
        sed -i "s|KEY_ALIAS|"$(cat /run/secrets/key_alias)"|g" /repo/config.yml
RUN --mount=type=secret,id=keystore_password \
        sed -i "s|KEYSTORE_PASSWORD|"$(cat /run/secrets/keystore_password)"|g" /repo/config.yml
RUN --mount=type=secret,id=key_password \
        sed -i "s|KEY_PASSWORD|"$(cat /run/secrets/key_password)"|g" /repo/config.yml
RUN chmod 0600 /repo/config.yml
RUN . /etc/profile.d/bsenv.sh && GRADLE_USER_HOME=${home_vagrant}/.gradle ; ${fdroidserver}/fdroid update -c

FROM ghcr.io/googlechromelabs/bubblewrap:1.24.1@sha256:bbe57abc1f6c81ff2a10ac110188b0f0a39bbb82d92146562070f9f7ce52293b AS bubblewrap
COPY --from=repository-base /repo /repo

COPY app-manifests /app-manifests
COPY scripts/bubblewrap-build.sh /scripts/bubblewrap-build.sh

RUN chmod +x /scripts/bubblewrap-build.sh
RUN --mount=type=secret,id=key_alias \
    --mount=type=secret,id=keystore_password \ 
    --mount=type=secret,id=key_password \
    /scripts/bubblewrap-build.sh

FROM fdroid AS repository
COPY --from=bubblewrap /repo /repo
RUN . /etc/profile.d/bsenv.sh && GRADLE_USER_HOME=${home_vagrant}/.gradle ${fdroidserver}/fdroid update -c

FROM nginx:1.29.3-alpine@sha256:b3c656d55d7ad751196f21b7fd2e8d4da9cb430e32f646adcf92441b72f82b14

COPY --from=repository /repo/repo /usr/share/nginx/html/repo

COPY templates/nginx/default.conf /etc/nginx/conf.d/default.conf
COPY scripts/nginx-entrypoint.sh /root/entrypoint.sh
RUN chmod +x /root/entrypoint.sh

RUN apk add openssl

ENTRYPOINT [ "/root/entrypoint.sh" ]