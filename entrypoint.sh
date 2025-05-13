#!/bin/ash

set -euo pipefail

if [ "${CUSTOM_CONFIG:-false}" = "true" ]; then
    echo "[INFO] CUSTOM_CONFIG is true: using custom configuration files in /etc/nginx/conf.d/"
    # Check if there is at least one .conf file in the directory
    if ! ls /etc/nginx/conf.d/*.conf 1> /dev/null 2>&1; then
        echo "[ERROR] No .conf files found in /etc/nginx/conf.d/ with CUSTOM_CONFIG=true"
        exit 1
    fi
else
    echo "[INFO] CUSTOM_CONFIG is not true: generating configuration from template"
    # Required for all setups (only when generating config)
    REQUIRED_VARS="EXTERNAL_IP SERVER_NAME UPSTREAM_SERVER UPSTREAM_PORT"
    if [ -n "${INTERFACE_HTTPS_PORT:-}" ]; then
      REQUIRED_VARS="$REQUIRED_VARS CERT_FILENAME KEY_FILENAME"
    fi

    for var in $REQUIRED_VARS; do
      eval "value=\$$var"
      if [ -z "$value" ]; then
        echo "[ERROR] Environment variable '$var' is not defined"
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

    export HTTP_LISTEN_DIRECTIVE HTTPS_LISTEN_DIRECTIVE SSL_CONFIG_DIRECTIVE \
           EXTERNAL_IP UPSTREAM_SERVER UPSTREAM_PORT SERVER_NAME \
           CERT_FILENAME KEY_FILENAME

    echo "[INFO] Generating /etc/nginx/conf.d/server.conf from template"
    envsubst '${HTTP_LISTEN_DIRECTIVE} ${HTTPS_LISTEN_DIRECTIVE} ${SSL_CONFIG_DIRECTIVE} ${EXTERNAL_IP} ${UPSTREAM_SERVER} ${UPSTREAM_PORT} ${SERVER_NAME} ${CERT_FILENAME} ${KEY_FILENAME}' \
      < /etc/nginx/nginx.template > /etc/nginx/conf.d/server.conf
fi

echo "[INFO] NGINX started with the following configuration:"
cat /etc/nginx/conf.d/server.conf
echo "[INFO] NGINX version: $(nginx -v 2>&1)"
echo "[INFO] NGINX configuration test:"
nginx -T
echo "[INFO] NGINX configuration test completed successfully"
exec nginx -g 'daemon off;'
# vim: set ft=sh ts=2 sw=2 et: