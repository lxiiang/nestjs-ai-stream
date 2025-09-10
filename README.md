# NestJS AI Stream Monorepo

这是一个使用 pnpm workspace 管理的 monorepo 项目，包含 NestJS 后端服务和 Vue3 前端应用。

## 项目结构

```
nestjs-ai-stream/
├── stream-serve/          # NestJS 后端服务
├── web-client/           # Vue3 前端应用 (Vite + TypeScript)
├── package.json          # 根目录配置
├── pnpm-workspace.yaml   # pnpm workspace 配置
└── README.md
```

## 安装依赖

```bash
# 安装所有项目的依赖
pnpm install
```

## 开发命令

```bash
# 同时启动前后端开发服务器
pnpm run dev

# 只启动前端开发服务器
pnpm run dev:web

# 只启动后端开发服务器
pnpm run dev:server
```

## 构建命令

```bash
# 构建所有项目
pnpm run build

# 只构建前端
pnpm run build:web

# 只构建后端
pnpm run build:server
```

## 项目详情

### 后端服务 (stream-serve)

- 框架: NestJS
- 端口: 3000 (默认)
- 位置: `./stream-serve/`

### 前端应用 (web-client)

- 框架: Vue3 + TypeScript
- 构建工具: Vite
- 端口: 5173 (默认)
- 位置: `./web-client/`

## 依赖管理说明

- **根目录**: 只包含项目管理脚本，不安装具体的业务依赖
- **子项目**: 各自管理自己的依赖，pnpm 会自动优化重复依赖
- **共享依赖**: pnpm 会自动提升公共依赖到根目录，无需手动配置

## 开发指南

1. 克隆项目后，运行 `pnpm install` 安装所有依赖
2. 使用 `pnpm run dev` 同时启动前后端服务
3. 前端访问地址: http://localhost:5173
4. 后端 API 地址: http://localhost:3000
