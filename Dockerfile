FROM pwa-to-fdroid/builder AS builder
FROM nginx:1.27.1-alpine

COPY --from=builder /repo/repo /usr/share/nginx/html/repo

COPY templates/nginx/default.conf /etc/nginx/conf.d/default.conf

COPY scripts/nginx-entrypoint.sh /root/entrypoint.sh
RUN chmod +x /root/entrypoint.sh

RUN apk add openssl

ENTRYPOINT [ "/root/entrypoint.sh" ]