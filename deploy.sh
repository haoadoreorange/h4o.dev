#!/bin/sh
set -eu

archive() (
  OPTIND=1
  while getopts 'kn' opt; do
    case "$opt" in
      k) # keep original
        cpPR='cp -PR'
        ;;
      n) # callers no-archive passthrough, keep rm -> no separate `rm` call
        archive=
        ;;
    esac
  done
  shift $((OPTIND - 1))

  sudo=$(check_sudo "${1:?}")
  bak="$(dirname "$1")/.archive" && ${sudo-} mkdir -p "$bak"
  [ ! -L "$1" ] && [ ! -e "$1" ] && return

  if [ "${archive-true}" ]; then
    base=$(basename "$1")
    # shellcheck disable=SC2086 # split `cp -PR`
    ${sudo-} ${cpPR:-mv} "$1" "$bak/$base.$(date +%s).$(head -c1 /dev/urandom | od -An -tx1 | tr -d ' \n')"
    # Keep last 10 copies
    # shellcheck disable=SC2016 # expand inside -c, not here
    ${sudo-} sh -c 'ls -dt "$1"* 2>/dev/null' _ "$bak/$base." | tail -n +11 | while read -r f; do
      ${sudo-} rm -rf "$f"
    done
  elif [ ! "${cpPR-}" ]; then
    ${sudo-} rm -rf "$1"
  fi
)

check_sudo() (
  [ "$(id -u)" -eq 0 ] && return #root
  [ -e "${1:?}" ] && [ ! -r "$1" ] && echo 'sudo' && return
  dir=$(dirname "$1")
  while [ ! -d "$dir" ]; do
    dir=$(dirname "$dir")
  done
  if [ ! -w "$dir" ]; then
    echo 'sudo'
  fi
)

sudo apt-get update
sudo apt-get upgrade -y
if ! type certbot >/dev/null 2>&1; then
  echo
  echo '── Install nginx from official repo ───────────────────────────────────'
  sudo apt-get install -y curl gnupg2 ca-certificates lsb-release debian-archive-keyring
  {
    curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] https://nginx.org/packages/debian $(lsb_release -cs) nginx" | sudo tee /etc/apt/sources.list.d/nginx.list
    printf 'Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n' | sudo tee /etc/apt/preferences.d/99nginx
  } >/dev/null
  sudo apt-get update
  sudo apt-get install -y nginx certbot python3-certbot-nginx rsync
fi
echo

## Wrap stdin server blocks in http {} boilerplate and write to nginx.conf
write_nginx_conf() (
  echo '── Write nginx.conf ───────────────────────────────────────────────────'
  archive /etc/nginx/nginx.conf
  sudo tee /etc/nginx/nginx.conf >/dev/null <<EOF
user             nginx;
worker_processes auto; # default: 1
events           {}    # required block; uses epoll with 1024 connections/worker by default

http {
    include      /etc/nginx/mime.types;    # maps extensions to Content-Type (without it everything is text/plain)
    default_type application/octet-stream; # unknown extensions trigger download (default: text/plain, displays garbage)
    sendfile     on;                       # kernel zero-copy file transfer (default: off, uses slower read+write)
    tcp_nopush   on;                       # batch headers+body into one packet; requires sendfile (default: off)
    gzip         on;                       # compress responses to save bandwidth (default: off)
    gzip_types   text/css application/javascript text/xml application/xml text/plain; # text/html always gzipped; this adds css/js/xml

$(cat)
}
EOF
  sudo nginx -t
  sudo systemctl enable nginx
  sudo systemctl restart nginx
  echo
)

if ! sudo certbot certificates -d h4o.dev 2>/dev/null | grep -qF 'Certificate Name'; then
  write_nginx_conf <<'EOF' # http-only config so certbot can verify domain and issue certs
    server {
        server_name h4o.dev;
        listen [::]:80;
        listen 80;
    }

    server {
        server_name www.h4o.dev;
        listen [::]:80;
        listen 80;
        return 301 $scheme://h4o.dev$request_uri;
    }
EOF

  echo "── Let's Encrypt ────────────────────────────────────────────────────────"
  sudo certbot --nginx -d h4o.dev -d www.h4o.dev -m blog@h4o.dev --non-interactive --agree-tos
fi

webroot=/usr/share/nginx/html && sudo mkdir -p "$webroot"
sudo chown "$USER" "$webroot"                            # user must have rw for make to create directory
sudo usermod -aG nginx "$USER"                           # user must be in group for make to chown
sed "s|$\$webroot|$webroot|g" <<'EOF' | write_nginx_conf # sed because nginx vars ($host, $uri) conflict with shell expansion
    server {
        server_name h4o.dev;

        listen [::]:443 ssl; # managed by Certbot
        listen 443 ssl;      # managed by Certbot
        ssl_certificate     /etc/letsencrypt/live/h4o.dev/fullchain.pem; # managed by Certbot
        ssl_certificate_key /etc/letsencrypt/live/h4o.dev/privkey.pem;   # managed by Certbot
        include             /etc/letsencrypt/options-ssl-nginx.conf;     # managed by Certbot
        ssl_dhparam         /etc/letsencrypt/ssl-dhparams.pem;           # managed by Certbot

        root $$webroot/h4o.dev;
        rewrite ^/(.+)/$ /$1 permanent; # strip trailing slash: /blog/ → 301 → /blog
        try_files $uri $uri.html $uri/index.html =404; # /blog → blog, blog.html, blog/index.html
    }

    server {
        server_name www.h4o.dev;

        listen [::]:443 ssl; # managed by Certbot
        listen 443 ssl;      # managed by Certbot

        return 301 $scheme://h4o.dev$request_uri;
    }

    server {
        listen [::]:80 default_server;
        listen 80 default_server;

        if ($host = h4o.dev) {
    	    return 301 https://$host$request_uri;   # managed by Certbot
        }
        if ($host = www.h4o.dev) {
    	    return 301 https://h4o.dev$request_uri; # managed by Certbot
        }
        return 404; # managed by Certbot
    }
EOF
