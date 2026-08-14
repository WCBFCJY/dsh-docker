#!/bin/sh
set -e

# 确保配置目录存在(挂载的卷可能是空目录)
mkdir -p "$DSH_HOME"

# 确保工作区目录存在
mkdir -p /workspace

exec "$@"
