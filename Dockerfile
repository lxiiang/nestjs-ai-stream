# 简化版 Dockerfile for NestJS AI Stream Service

FROM node:18-alpine

# 设置工作目录
WORKDIR /app

# 安装 pnpm
RUN npm install -g pnpm

# 复制 stream-serve 项目文件
COPY stream-serve/package.json ./
COPY stream-serve/pnpm-lock.yaml* ./

# 安装依赖
RUN pnpm install --frozen-lockfile

# 复制源代码
COPY stream-serve/ ./

# 构建应用
RUN pnpm run build

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
