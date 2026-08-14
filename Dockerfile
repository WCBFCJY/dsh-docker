FROM node:24-trixie-slim

WORKDIR /workspace

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git ca-certificates openssl tmux \
        python3 python3-pip python3-venv \
        curl jq wget htop \
        build-essential \
        ffmpeg sqlite3 \
        unzip zip tree \
        nano file less \
        ripgrep procps yq nginx \
    && rm -rf /var/lib/apt/lists/* \
    && rm -f /etc/nginx/nginx.conf \
    && ln -sf /usr/bin/python3 /usr/bin/python \
    && rm -f /usr/lib/python3*/EXTERNALLY-MANAGED

RUN npm install -g @deepseek-ai/dsh \
    && npm cache clean --force

RUN mkdir -p /app/.dsh /workspace

COPY docker-entrypoint.sh /usr/local/bin/dsh-entrypoint
RUN chmod +x /usr/local/bin/dsh-entrypoint

ENV NODE_ENV=production \
    DSH_HOME=/app/.dsh \
    DSH_WEB_HOST=0.0.0.0 \
    DSH_WEB_PORT=3081

EXPOSE 3081

ENTRYPOINT ["dsh-entrypoint"]
