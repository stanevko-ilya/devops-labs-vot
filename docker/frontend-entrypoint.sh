#!/bin/sh
set -eu

mkdir -p /etc/nginx/certs /etc/nginx/security
if [ ! -s /etc/nginx/certs/lab.crt ] || [ ! -s /etc/nginx/certs/lab.key ]; then
    openssl req -x509 -newkey rsa:2048 -nodes -sha256 -days 30 \
      -keyout /etc/nginx/certs/lab.key -out /etc/nginx/certs/lab.crt \
      -subj '/CN=lab.localhost' \
      -addext 'subjectAltName=DNS:lab.localhost,DNS:other.localhost'
    chmod 600 /etc/nginx/certs/lab.key
fi

if [ ! -s /etc/nginx/security/.htpasswd ]; then
    password="$(openssl rand -hex 12)"
    htpasswd -bcB /etc/nginx/security/.htpasswd admin "$password"
    echo "Lab admin credentials: admin / $password"
fi

exec nginx -g 'daemon off;'
