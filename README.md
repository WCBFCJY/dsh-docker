# DSH Docker

基于 Node 24 的 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (DSH)容器镜像,内置 nginx 反向代理,解决 Web UI 的浏览器信任校验问题。

## 工作原理

- dsh 主程序默认监听 `127.0.0.1:3080`,作为后台进程运行;
- nginx 监听 `DSH_WEB_HOST:DSH_WEB_PORT`(默认 `0.0.0.0:3081`),把流量转发到 `127.0.0.1:3080`;
- 转发时改写 `Host: 127.0.0.1:3081`、删除 `Origin`、透传 WebSocket(`Upgrade`/`Connection`);
- DSH 的浏览器信任栅栏校验 HTTP `Host` 头(特权接口强制 loopback,`--trusted-host` 不生效),改写后外部访问也能通过校验。

## 快速开始

### Docker Compose

```yaml
services:
  dsh:
    image: ghcr.io/wcbfcjy/dsh-docker:latest
    container_name: dsh
    restart: unless-stopped
    init: true
    ports:
      - "3081:3081"
    volumes:
      - ~/.dsh:/app/.dsh
      - ~/workspace:/workspace
    environment:
    # 配置访问地址与端口
      - DSH_WEB_HOST=0.0.0.0
      - DSH_WEB_PORT=3081
    # 启用 Basic Auth（账号密码同时设置才启用）
      - DSH_AUTH_USER=admin
      - DSH_AUTH_PASS=your_password
    # 修改配置目录(默认 /app/.dsh,如不需要改可不设)
    # - DSH_HOME=/app/.dsh
    security_opt:
      - no-new-privileges:true
```

启动后浏览器访问 `http://服务器IP:3081`。

## 环境变量

| 变量 | 必填 | 默认值 | 说明 |
|---|---|---|---|
| `DSH_WEB_HOST` | 否 | `0.0.0.0` | nginx 监听地址(仅 IPv4 字面量) |
| `DSH_WEB_PORT` | 否 | `3081` | nginx 监听端口,改动需同步端口映射 |
| `DSH_AUTH_USER` | 否 | - | Basic Auth 用户名,与密码同时设置才启用 |
| `DSH_AUTH_PASS` | 否 | - | Basic Auth 密码,与用户名同时设置才启用 |
| `DSH_HOME` | 否 | `/app/.dsh` | DSH 配置目录 |

注意:`DSH_AUTH_USER` 与 `DSH_AUTH_PASS` 必须同时设置才启用 Basic Auth,缺一不可。启用后密码以 APR1 哈希形式存于 `/etc/nginx/.htpasswd`,不落明文。

## 自定义 nginx 配置

挂载自定义配置后,容器检测到 `/etc/nginx/nginx.conf` 已存在,不再生成默认配置,完全使用你的:

```yaml
volumes:
  - ~/my-nginx.conf:/etc/nginx/nginx.conf
```

自定义配置需自行包含转发逻辑:`proxy_pass http://127.0.0.1:3080`、`Host: 127.0.0.1:3080`、删除 `Origin`、WebSocket 透传。Basic Auth 的 `/etc/nginx/.htpasswd` 仍会按环境变量生成,可直接引用。

## 数据持久化

- `/app/.dsh` — DSH 配置、profiles、会话状态(建议挂载卷)
- `/workspace` — 工作区,Agent 可操作的项目目录
- 镜像 dsh 通过 `npm install -g @deepseek-ai/dsh` 安装,为构建时的 npm `latest` 版本;

## License

[MIT](LICENSE)
