#!/bin/sh

# Fail fast on error, undefined variable, or broken pipe
set -euo pipefail

# List of required environment variables
REQUIRED_VARS="EXTERNAL_IP INTERFACE_HTTPS_PORT UPSTREAM_SERVER UPSTREAM_PORT SERVER_NAME CERT_FILENAME KEY_FILENAME"

# Validate all required environment variables
for var in $REQUIRED_VARS; do
  if [ -z "${!var:-}" ]; then
    echo "Error: Environment variable '$var' is not defined"
    exit 1
  fi
done

# Generate nginx.conf from template
envsubst '${EXTERNAL_IP} ${INTERFACE_HTTPS_PORT} ${UPSTREAM_SERVER} ${UPSTREAM_PORT} ${SERVER_NAME} ${KEY_FILENAME} ${CERT_FILENAME}' \
  < /etc/nginx/nginx.template > /etc/nginx/nginx.conf

# Start NGINX in the foreground
exec nginx -g 'daemon off;'
