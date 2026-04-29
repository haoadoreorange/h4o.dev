#!/bin/sh
set -eu

echo '── Installing nginx from official repo ─────────────────────────────────────────'
sudo apt update
sudo apt upgrade -y
sudo apt install -y curl gnupg2 ca-certificates lsb-release debian-archive-keyring
curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] https://nginx.org/packages/debian `lsb_release -cs` nginx" | sudo tee /etc/apt/sources.list.d/nginx.list
printf 'Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n' | sudo tee /etc/apt/preferences.d/99nginx
sudo apt update
sudo apt install -y nginx certbot python3-certbot-nginx rsync

echo '── Creating webroot ────────────────────────────────────────────────────────────'
webroot='/usr/share/nginx/html'
sudo mkdir -p "$webroot"
sudo usermod -aG nginx "$USER"
sudo chown "$USER":nginx "$webroot"

write_nginx_conf() {
echo '── Writing nginx.conf ──────────────────────────────────────────────────────────'
    sudo tee /etc/nginx/nginx.conf > /dev/null << EOF
user  nginx;
worker_processes  auto;

events {}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    tcp_nopush      on;
    gzip            on;
    gzip_types      text/css application/javascript text/xml application/xml text/plain;

$1

    include /etc/nginx/conf.d/*.conf;
}
EOF
    sudo nginx -t
    sudo systemctl enable nginx
    sudo systemctl restart nginx
}

write_nginx_conf \
'    server {
        server_name h4o.dev;
        listen 80;
        listen [::]:80;
    }

    server {
        server_name www.h4o.dev;
        listen 80;
        listen [::]:80;
        return 301 $scheme://h4o.dev$request_uri;
    }'

echo "── Let's Encrypt ───────────────────────────────────────────────────────────────"
echo 'Run this in another SSH session:'
echo '  sudo certbot --nginx -d h4o.dev -d www.h4o.dev --non-interactive --agree-tos --register-unsafely-without-email'
echo 'Press Enter when done...'
read -r _ < /dev/tty

write_nginx_conf "$(sed "s|%WEBROOT%|$webroot|g" << 'EOF'
    server {
        server_name h4o.dev;

        listen [::]:443 ssl; # managed by Certbot
        listen 443 ssl; # managed by Certbot
        ssl_certificate /etc/letsencrypt/live/h4o.dev/fullchain.pem; # managed by Certbot
        ssl_certificate_key /etc/letsencrypt/live/h4o.dev/privkey.pem; # managed by Certbot
        include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
        ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot

        root %WEBROOT%/;
        rewrite ^/(.+)/$ /$1 permanent;
        try_files $uri $uri.html $uri/index.html =404;
    }
    server {
        server_name www.h4o.dev;

        listen [::]:443 ssl; # managed by Certbot
        listen 443 ssl; # managed by Certbot

        return 301 $scheme://h4o.dev$request_uri;
    }
    server {
        listen [::]:80 default_server;
        listen 80 default_server;
        if ($host = h4o.dev) {
    	    return 301 https://$host$request_uri;
        } # managed by Certbot
        if ($host = www.h4o.dev) {
    	    return 301 https://h4o.dev$request_uri;
        } # managed by Certbot
        return 404; # managed by Certbot
    }
EOF
)"
