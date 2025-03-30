#!/bin/bash

set  -e

if [ -z "$EXTERNAL_IP" ]; then
  echo "Error: EXTERNAL_IP undefined"
  exit 1
fi

export EXTERNAL_IP

envsubst '${EXTERNAL_IP} ${INTERFACE_HTTPS_PORT} ${UPSTREAM_SERVER} ${UPSTREAM_PORT} ${SERVER_NAME} ${KEY_FILENAME} ${CERT_FILENAME}' < /etc/nginx/nginx.template > /etc/nginx/nginx.conf

nginx -g 'daemon off;'