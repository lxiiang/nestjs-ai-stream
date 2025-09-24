# 多阶段构建 Dockerfile for NestJS AI Stream Service + Vue Client (pnpm monorepo)

# 构建阶段
FROM node:20-alpine AS builder

# 设置工作目录
WORKDIR /app

# 安装 pnpm
RUN npm install -g pnpm

# 复制 monorepo 配置文件
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./

# 复制所有 package.json 文件
COPY stream-serve/package.json ./stream-serve/
COPY web-client/package.json ./web-client/

# 安装所有依赖（monorepo 模式）
RUN pnpm install --frozen-lockfile

# 复制源代码
COPY stream-serve/ ./stream-serve/
COPY web-client/ ./web-client/

# 构建前端应用
RUN pnpm --filter web-client run build

# 构建后端应用
RUN pnpm --filter stream-serve run build

# 生产阶段
FROM node:20-alpine AS production

# 安装 nginx 用于服务前端静态文件
RUN apk add --no-cache nginx wget

# 设置工作目录
WORKDIR /app

# 安装 pnpm
RUN npm install -g pnpm

# 复制 monorepo 配置文件
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./

# 复制 stream-serve package.json
COPY stream-serve/package.json ./stream-serve/

# 安装生产依赖（只安装 stream-serve 需要的）
RUN pnpm --filter stream-serve install --prod --frozen-lockfile

# 从构建阶段复制编译后的后端代码
COPY --from=builder /app/stream-serve/dist ./stream-serve/dist

# 从构建阶段复制前端构建产物
COPY --from=builder /app/web-client/dist /var/www/html

# 复制 nginx 配置文件
COPY nginx.conf /etc/nginx/nginx.conf

# 创建 nginx 运行目录和日志目录
RUN mkdir -p /run/nginx /var/log/nginx

# 设置工作目录到 stream-serve
WORKDIR /app/stream-serve

# 设置环境变量
ENV NODE_ENV=production
ENV PORT=3000

# 暴露端口（nginx 80端口用于前端，3000端口用于后端API）
EXPOSE 80 3000

# 直接启动 nginx 和 Node.js 应用
CMD ["sh", "-c", "nginx && exec node dist/main.js"]

