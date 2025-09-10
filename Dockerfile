# 多阶段构建 Dockerfile for NestJS AI Stream Service (Monorepo)

# 第一阶段：构建阶段
FROM node:18-alpine AS builder

# 设置工作目录
WORKDIR /app

# 安装 pnpm
RUN npm install -g pnpm

# 复制 monorepo 根目录配置文件
COPY package.json pnpm-workspace.yaml ./
COPY pnpm-lock.yaml* ./

# 复制 stream-serve 的 package.json
COPY stream-serve/package.json ./stream-serve/

# 安装所有 workspace 依赖
RUN pnpm install --frozen-lockfile

# 复制 stream-serve 源代码
COPY stream-serve/ ./stream-serve/

# 切换到 stream-serve 目录并构建应用
WORKDIR /app/stream-serve
RUN pnpm run build

# 清理开发依赖，只保留生产依赖
RUN pnpm prune --prod

# 第二阶段：运行阶段
FROM node:18-alpine AS runner

# 设置工作目录
WORKDIR /app

# 从构建阶段复制必要文件
COPY --from=builder /app/stream-serve/dist ./dist
COPY --from=builder /app/stream-serve/node_modules ./node_modules
COPY --from=builder /app/stream-serve/public ./public
COPY --from=builder /app/stream-serve/package.json ./package.json

# 设置环境变量
ENV NODE_ENV=production
ENV PORT=3000

# 暴露端口
EXPOSE 3000

# 启动应用
CMD ["node", "dist/main"]

# 标签信息
LABEL maintainer="your-email@example.com"
LABEL version="1.0.0"
LABEL description="NestJS AI Stream Service with Alibaba Bailian (Monorepo)"
