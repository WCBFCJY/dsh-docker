#!/bin/sh
set -e

mkdir -p "$DSH_HOME"

mkdir -p /workspace

if [ $# -eq 0 ]; then
    exec dsh web --host "${DSH_WEB_HOST:-0.0.0.0}" --port "${DSH_WEB_PORT:-3080}"
fi

exec "$@"
