# 多阶段构建 Dockerfile for NestJS AI Stream Service (pnpm monorepo)

# 构建阶段
FROM node:18-alpine AS builder

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

# 构建 stream-serve 应用
RUN pnpm --filter stream-serve run build

# 生产阶段
FROM node:18-alpine AS production

# 设置工作目录
WORKDIR /app

# 安装必要的工具和 pnpm
RUN apk add --no-cache wget && \
    npm install -g pnpm

# 复制 monorepo 配置文件
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./

# 复制 stream-serve package.json
COPY stream-serve/package.json ./stream-serve/

# 安装生产依赖（只安装 stream-serve 需要的）
RUN pnpm --filter stream-serve install --prod --frozen-lockfile

# 从构建阶段复制编译后的代码
COPY --from=builder /app/stream-serve/dist ./stream-serve/dist

# 复制 public 文件（如果有的话）
COPY --from=builder /app/stream-serve/public ./stream-serve/public

# 设置工作目录到 stream-serve
WORKDIR /app/stream-serve

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
