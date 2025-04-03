FROM nginx:1.26.1-alpine-slim

# Install only what's necessary
RUN apk add --no-cache curl

# Create nginx user and group safely
ARG NGINX_CONF_GID
RUN addgroup -g nginx && \
    adduser -D -G nginx -s /sbin/nologin nginx

# Copy entrypoint and set correct permissions
COPY entrypoint.sh /entrypoint.sh
RUN chmod 700 /entrypoint.sh && \
    chown nginx:nginx /entrypoint.sh

# Copy NGINX config template
COPY nginx.conf.template /etc/nginx/nginx.template

# Prepare log files
RUN touch /var/log/nginx/audit_platform_error.log && \
    touch /var/log/nginx/audit_platform_access.log && \
    chown -R nginx:nginx /var/log/nginx/

# Prepare required directories and permissions
RUN touch /var/run/nginx.pid && \
    mkdir -p /var/cache/nginx && \
    mkdir -p /www/certs/ && \
    chown -R nginx:nginx /var/run/nginx.pid /var/cache/nginx /etc/nginx /www/certs

# Run as non-root user
USER nginx

# Entrypoint
ENTRYPOINT [ "/entrypoint.sh" ]