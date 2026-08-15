#!/bin/sh
set -e

mkdir -p "$DSH_HOME"

mkdir -p /workspace

dsh web &

if [ -n "$DSH_AUTH_USER" ] && [ -n "$DSH_AUTH_PASS" ]; then
    printf '%s:%s\n' "$DSH_AUTH_USER" "$(openssl passwd -apr1 "$DSH_AUTH_PASS")" > /etc/nginx/.htpasswd
fi

if [ ! -f /etc/nginx/nginx.conf ]; then
    HOST="${DSH_WEB_HOST:-0.0.0.0}"
    PORT="${DSH_WEB_PORT:-3081}"
    AUTH_CONF=""
    WS_BLOCKS=""
    if [ -f /etc/nginx/.htpasswd ]; then
        AUTH_CONF='auth_basic "dsh"; auth_basic_user_file /etc/nginx/.htpasswd;'
        WS_BLOCKS='location = /api/events.mux {
            auth_basic "dsh";
            auth_basic_user_file /etc/nginx/.htpasswd;
            error_page 401 =403;
            proxy_pass http://127.0.0.1:3080;
            proxy_set_header Host 127.0.0.1:3081;
            proxy_set_header Origin "";
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
        }
        location = /api/events.host {
            auth_basic "dsh";
            auth_basic_user_file /etc/nginx/.htpasswd;
            error_page 401 =403;
            proxy_pass http://127.0.0.1:3080;
            proxy_set_header Host 127.0.0.1:3081;
            proxy_set_header Origin "";
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
        }'
    fi

    cat > /etc/nginx/nginx.conf <<NGINXEOF
worker_processes 1;
events { worker_connections 1024; }
http {
    include /etc/nginx/mime.types;
    access_log off;
    server {
        listen ${HOST}:${PORT};
        server_name _;
        ${WS_BLOCKS}
        location / {
            $AUTH_CONF
            proxy_pass http://127.0.0.1:3080;
            proxy_set_header Host 127.0.0.1:3081;
            proxy_set_header Origin "";
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
        }
    }
}
NGINXEOF
fi

i=0
while ! curl -sS -o /dev/null http://127.0.0.1:3080/; do
    i=$((i+1))
    [ "$i" -ge 30 ] && break
    sleep 2
done

exec nginx -g 'daemon off;'
