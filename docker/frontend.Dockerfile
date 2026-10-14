FROM nginx:1.30.5-alpine3.24
RUN apk add --no-cache openssl apache2-utils
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY docker/frontend-entrypoint.sh /usr/local/bin/frontend-entrypoint.sh
COPY frontend/ /usr/share/nginx/html/
COPY docs/ /usr/share/nginx/docs/
COPY other-site/ /usr/share/nginx/other/
RUN chmod +x /usr/local/bin/frontend-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/frontend-entrypoint.sh"]
