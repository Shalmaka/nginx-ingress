FROM nginx:1.26.1-alpine-slim

RUN apk add --no-cache curl

ARG NGINX_CONF_GID

RUN addgroup -g ${NGINX_CONF_GID} nginx && adduser nginx

COPY entrypoint.sh /entrypoint.sh
RUN chmod 700 /entrypoint.sh && \
    chown nginx:nginx /entrypoint.sh

COPY nginx.conf.template /etc/nginx/nginx.conf.template

# Log
RUN touch /var/log/nginx/audit_platform_error.log && \
    touch /var/log/nginx/audit_platform_access.log && \
    chown -R nginx:nginx /var/log/nginx/audit_platform_error.log && \
    chown -R nginx:nginx /var/log/nginx/audit_platform_access.log

# Security
RUN touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid /var/cache/nginx /etc/nginx/nginx.conf

RUN mkdir -p /www/certs/

USER nginx

ENTRYPOINT [ "/entrypoint.sh" ]