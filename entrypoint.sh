#!/bin/ash

# Fail fast on error, undefined variable, or broken pipe
set -euo pipefail

# Required for all setups
REQUIRED_VARS="EXTERNAL_IP SERVER_NAME UPSTREAM_SERVER UPSTREAM_PORT"

# If HTTPS is enabled, require certificate variables
if [ -n "${INTERFACE_HTTPS_PORT:-}" ]; then
  REQUIRED_VARS="$REQUIRED_VARS CERT_FILENAME KEY_FILENAME"
fi

# Validate all required variables are present
for var in $REQUIRED_VARS; do
  eval "value=\$$var"
  if [ -z "$value" ]; then
    echo "Error: Environment variable '$var' is not defined"
    exit 1
  fi
done

# Build listen directives
HTTP_LISTEN_DIRECTIVE=""
HTTPS_LISTEN_DIRECTIVE=""
SSL_CONFIG_DIRECTIVE=""

if [ -n "${INTERFACE_HTTP_PORT:-}" ]; then
  HTTP_LISTEN_DIRECTIVE="listen ${EXTERNAL_IP}:${INTERFACE_HTTP_PORT};"
fi

if [ -n "${INTERFACE_HTTPS_PORT:-}" ]; then
  HTTPS_LISTEN_DIRECTIVE="listen ${EXTERNAL_IP}:${INTERFACE_HTTPS_PORT} ssl;"
  SSL_CONFIG_DIRECTIVE="
    ssl_certificate       /usr/share/nginx/certs/${CERT_FILENAME};
    ssl_certificate_key   /usr/share/nginx/certs/${KEY_FILENAME};
    ssl_protocols         TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ecdh_curve        secp521r1:secp384r1:prime256v1;
    ssl_session_tickets   off;
    ssl_session_cache     none;
    ssl_buffer_size       4k;"
fi

# Export for envsubst
export HTTP_LISTEN_DIRECTIVE HTTPS_LISTEN_DIRECTIVE SSL_CONFIG_DIRECTIVE \
       EXTERNAL_IP UPSTREAM_SERVER UPSTREAM_PORT SERVER_NAME \
       CERT_FILENAME KEY_FILENAME

# Generate nginx.conf
envsubst '${HTTP_LISTEN_DIRECTIVE} ${HTTPS_LISTEN_DIRECTIVE} ${SSL_CONFIG_DIRECTIVE} ${EXTERNAL_IP} ${UPSTREAM_SERVER} ${UPSTREAM_PORT} ${SERVER_NAME} ${CERT_FILENAME} ${KEY_FILENAME}' \
  < /etc/nginx/nginx.template > /etc/nginx/conf.d/server.conf

# Start nginx
exec nginx -g 'daemon off;'
