#!/bin/sh

if [ "${HTTP_AUTH_PASSWORD_FILE}" != "" ]; then
  HTTP_AUTH_PASSWORD=$(cat $HTTP_AUTH_PASSWORD_FILE)
fi

if [ "${HTTP_AUTH_PASSWORD}" != "" ]; then
  sed -i "s/#auth_basic/auth_basic/g;" /etc/nginx/nginx.conf
  rm -rf /etc/nginx/.htpasswd
  echo -n $HTTP_AUTH_LOGIN:$(openssl passwd -apr1 $HTTP_AUTH_PASSWORD) >> /etc/nginx/.htpasswd
  echo "Basic auth is on for user ${HTTP_AUTH_LOGIN}..."
else
  echo "Basic auth is off (HTTP_AUTH_PASSWORD not provided)"
fi

nginx -g "daemon off;"