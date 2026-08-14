#!/bin/sh
set -e

mkdir -p "$DSH_HOME"

mkdir -p /workspace

dsh web &
DSH_PID=$!

exec socat "TCP-LISTEN:${DSH_WEB_PORT:-3080},bind=${DSH_WEB_HOST:-0.0.0.0},fork,reuseaddr" TCP:127.0.0.1:3080
