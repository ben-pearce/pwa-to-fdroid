ARG KEY_ALIAS="fdroid"
ARG KEYSTORE_PASSWORD=""
ARG KEY_PASSWORD=""

FROM registry.gitlab.com/fdroid/docker-executable-fdroidserver:latest
ARG KEY_ALIAS
ARG KEYSTORE_PASSWORD
ARG KEY_PASSWORD

COPY config/fdroid.yml /repo/config.yml
COPY ./*.p12 /repo/
RUN sed -i "s|KEY_ALIAS|$KEY_ALIAS|g" /repo/config.yml
RUN sed -i "s|KEYSTORE_PASSWORD|$KEYSTORE_PASSWORD|g" /repo/config.yml
RUN sed -i "s|KEY_PASSWORD|$KEY_PASSWORD|g" /repo/config.yml
RUN chmod 0600 /repo/config.yml
RUN . /etc/profile.d/bsenv.sh && GRADLE_USER_HOME=${home_vagrant}/.gradle ; if [ -f "keystore.p12" ]; then \
    ${fdroidserver}/fdroid update -c ; \
  else \
    ${fdroidserver}/fdroid update --create-key -c ; \
  fi

FROM ghcr.io/googlechromelabs/bubblewrap:latest
ARG KEY_ALIAS
ARG KEYSTORE_PASSWORD
ARG KEY_PASSWORD
COPY --from=0 /repo /repo

COPY app-manifests /app-manifests
COPY scripts/bubblewrap-build.sh /scripts/bubblewrap-build.sh

ENV BUBBLEWRAP_KEYSTORE_PASSWORD=$KEYSTORE_PASSWORD
ENV BUBBLEWRAP_KEY_PASSWORD=$KEY_PASSWORD

RUN chmod +x /scripts/bubblewrap-build.sh ; /scripts/bubblewrap-build.sh

FROM registry.gitlab.com/fdroid/docker-executable-fdroidserver:latest
COPY --from=1 /repo /repo

RUN . /etc/profile.d/bsenv.sh && GRADLE_USER_HOME=${home_vagrant}/.gradle ${fdroidserver}/fdroid update -c