# 多阶段构建 Dockerfile for NestJS AI Stream Service

# 构建阶段
FROM node:18-alpine AS builder

# 设置工作目录
WORKDIR /app

# 安装 pnpm
RUN npm install -g pnpm

# 复制 package 文件
COPY stream-serve/package.json ./
COPY stream-serve/pnpm-lock.yaml* ./

# 安装所有依赖（包括 devDependencies，用于构建）
RUN pnpm install --frozen-lockfile

# 复制源代码
COPY stream-serve/ ./

# 构建应用
RUN pnpm run build:server

# 生产阶段
FROM node:18-alpine AS production

# 设置工作目录
WORKDIR /app

# 安装必要的工具和 pnpm
RUN apk add --no-cache wget && \
    npm install -g pnpm

# 复制 package 文件
COPY stream-serve/package.json ./
COPY stream-serve/pnpm-lock.yaml* ./

# 只安装生产依赖
RUN pnpm install --frozen-lockfile --prod

# 从构建阶段复制编译后的代码
COPY --from=builder /app/dist ./dist

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
