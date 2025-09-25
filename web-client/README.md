# Vue 3 AI 流式聊天客户端：现代化实时对话界面

基于 Vue 3 + TypeScript + Vite + Naive UI 构建的现代化 AI 聊天客户端，提供流畅的实时对话体验，支持 Markdown 渲染、代码高亮和流式停止功能。

## 🚀 项目概述

这是一个现代化的 AI 聊天前端应用，采用最新的前端技术栈，为用户提供流畅的实时对话体验。

### ✨ 核心特性

- 🎯 **Vue 3 Composition API**: 使用最新的 Vue 3 组合式 API，提供更好的逻辑复用和类型推导
- 🔧 **TypeScript 支持**: 完整的类型安全保障，提升开发体验和代码质量
- ⚡ **实时流式显示**: 基于 SSE 技术实现 AI 回复逐字实时显示，用户体验流畅
- 📝 **Markdown 渲染**: 集成 markdown-it 自动渲染 Markdown 格式内容
- 🌈 **代码高亮**: 使用 highlight.js 支持多语言代码语法高亮
- ⏹️ **流式停止功能**: 支持用户随时中断 AI 生成过程
- 📱 **响应式设计**: 适配桌面端和移动端各种屏幕尺寸
- 🧩 **组件化架构**: 模块化组件设计，易于维护和功能扩展
- 🎨 **现代化 UI**: 集成 Naive UI 组件库，提供美观的界面设计
- 🔄 **自动导入**: 使用 unplugin-auto-import 自动导入 Vue API，提升开发效率

## 📁 项目结构

```text
web-client/
├── src/
│   ├── components/           # 组件目录
│   │   ├── Head/            # 头部组件
│   │   │   └── index.vue    # 应用头部，包含标题和渐变背景
│   │   ├── Chat/            # 聊天组件
│   │   │   └── index.vue    # 聊天内容区域，支持消息渲染和欢迎页面
│   │   └── Input/           # 输入组件
│   │       └── index.vue    # 消息输入框，支持快捷键和流式控制
│   ├── hooks/               # 组合式函数
│   │   ├── useChat.js       # 聊天逻辑钩子，处理流式数据接收和状态管理
│   │   └── useMitt.js       # 事件总线钩子，用于组件间通信
│   ├── App.vue              # 根组件，定义整体布局和样式
│   ├── main.ts              # 应用入口，Vue 应用初始化
│   └── style.css            # 全局样式文件
├── public/                  # 公共资源目录
│   └── vite.svg             # Vite 默认图标
├── index.html               # HTML 模板文件
├── vite.config.ts           # Vite 构建配置
├── tsconfig.json            # TypeScript 配置
├── tsconfig.app.json        # 应用 TypeScript 配置
├── tsconfig.node.json       # Node.js TypeScript 配置
├── package.json             # 项目依赖和脚本配置
├── auto-imports.d.ts        # 自动导入类型声明文件
├── vite-env.d.ts           # Vite 环境类型声明
└── README.md                # 项目文档
```

## 🔍 核心实现详解

### 1. 聊天逻辑钩子：useChat.js

核心的聊天逻辑封装，处理流式数据接收和状态管理：

```javascript
import { ref } from "vue";
import { v4 as uuidv4 } from "uuid";
import { fetchEventSource } from "@microsoft/fetch-event-source";
import MarkdownIt from "markdown-it";
import hljs from "highlight.js";

// 响应式状态管理
const messages = ref([]);
const curMessage = ref({});
const controller = ref(null);
const isStreaming = ref(false);

// Markdown 渲染器配置
const markdown = MarkdownIt({
  html: true, // 允许在 Markdown 中使用原始 HTML 标签
  linkify: true, // 自动将 URL 转换为链接
  typographer: true, // 启用智能引号和连字符
  breaks: true, // 启用自动换行
  xhtmlOut: true, // 使用 XHTML 模式
  langPrefix: "language-", // 添加语言前缀
});

// 代码高亮配置
markdown.set({
  highlight: function (str, lang) {
    if (lang && hljs.getLanguage(lang)) {
      try {
        return (
          '<pre class="hljs"><code>' +
          hljs.highlight(str, { language: lang, ignoreIllegals: true }).value +
          "</code></pre>"
        );
      } catch (__) {}
    }
    return (
      '<pre class="hljs"><code>' +
      markdown.utils.escapeHtml(str) +
      "</code></pre>"
    );
  },
});

export function useChat() {
  // 处理流式消息
  const handleStreamMessage = (ev) => {
    if (ev.data) {
      const data = JSON.parse(ev.data);

      if (data.type === "start") {
        // 开始流式响应
        curMessage.value = {
          mid: uuidv4(),
          role: "assistant",
          content: "",
        };
        messages.value.push(curMessage.value);
      }

      if (data.type === "chunk") {
        // 追加内容并渲染 Markdown
        curMessage.value.content += data.content;
        curMessage.value.htmlStr = markdown.render(curMessage.value.content);
      }

      if (data.type === "end") {
        curMessage.value = {};
        isStreaming.value = false;
      } else if (data.type === "error") {
        // 处理错误情况
        isStreaming.value = false;
        messages.value.push({
          role: "assistant",
          content: data.message,
        });
      }
    }
  };

  // 处理流式错误
  const handleStreamError = (ev) => {
    isStreaming.value = false;
    messages.value.push({
      role: "assistant",
      content: "服务异常",
    });
  };

  // API 调用
  const queryAnswer = async (message) => {
    controller.value = new AbortController();
    const signal = controller.value.signal;

    fetchEventSource("/api/ai/chat/stream-sse", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(message),
      signal, // 中断信号
      openWhenHidden: true, // 页面隐藏时仍保持连接
      onmessage: (ev) => handleStreamMessage(ev),
      onerror: (ev) => handleStreamError(ev),
    });
  };

  // 发送消息
  const sendMessage = (userMsg) => {
    if (!userMsg.trim()) return;

    const userMessage = {
      mid: uuidv4(),
      role: "user",
      content: userMsg,
    };

    messages.value.push(userMessage);
    isStreaming.value = true;
    queryAnswer({ message: userMsg });
  };

  // 停止对话
  const stopConversation = () => {
    if (controller.value) {
      controller.value.abort();
      isStreaming.value = false;
    }
  };

  return {
    messages,
    isStreaming,
    sendMessage,
    stopConversation,
  };
}
```

**技术亮点：**

- **组合式 API**: 使用 Vue 3 的 `ref` 管理响应式状态
- **流式数据处理**: 通过 `fetchEventSource` 处理 Server-Sent Events 数据流
- **Markdown 渲染**: 集成 `markdown-it` 实现富文本显示，支持 HTML 标签
- **代码高亮**: 使用 `highlight.js` 提供多语言语法高亮
- **错误处理**: 完善的错误处理机制，包括网络异常和服务异常
- **连接管理**: 支持页面隐藏时保持连接，提供更好的用户体验
- **中断控制**: 使用 `AbortController` 实现流式响应的中断功能

### 2. 聊天内容组件：Chat/index.vue

负责展示聊天消息列表和处理消息渲染，包含欢迎页面和消息展示：

```vue
<script setup>
import { useChat } from "@/hooks/useChat";

const { messages } = useChat();
</script>

<template>
  <div id="chat-container" class="chat-container">
    <!-- 欢迎页面 -->
    <div v-if="messages.length === 0" class="welcome-message">
      <div class="welcome-content">
        <h2>👋 你好！我是你的数字人助手</h2>
        <p>有什么可以帮助你的吗？</p>
      </div>
    </div>

    <!-- 消息列表 -->
    <div
      v-for="message in messages"
      :key="message.id"
      :class="['message', message.role]"
    >
      <!-- 用户头像 -->
      <div class="message-avatar">
        <span v-if="message.role === 'user'">👤</span>
        <span v-else>🤖</span>
      </div>

      <!-- 消息内容 -->
      <div class="message-content">
        <div
          class="message-text"
          v-if="message.htmlStr"
          v-html="message.htmlStr"
        ></div>
        <div class="message-text" v-else>
          {{ message.content }}
          <span v-if="message.isStreaming" class="typing-indicator">▋</span>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.chat-container {
  flex: 1;
  overflow-y: auto;
  padding: 20px;
  background: white;
}

.welcome-message {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 100%;
  text-align: center;
}

.message {
  display: flex;
  margin-bottom: 20px;
  animation: fadeIn 0.3s ease-in;
}

.message.user {
  flex-direction: row-reverse;
}

.message-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
  margin: 0 10px;
  background: #f0f0f0;
}

.message.user .message-avatar {
  background: #667eea;
  color: white;
}

.message-content {
  max-width: 70%;
  background: #f8f9fa;
  padding: 12px 16px;
  border-radius: 18px;
  position: relative;
}

.message.user .message-content {
  background: #667eea;
  color: white;
}

.typing-indicator {
  animation: blink 1s infinite;
  color: #667eea;
}
</style>
```

**组件特性：**

- **欢迎页面**: 首次访问时显示友好的欢迎界面
- **消息渲染**: 区分用户和 AI 消息的不同样式和布局
- **头像系统**: 使用 emoji 图标区分用户和 AI 身份
- **Markdown 支持**: AI 消息支持 HTML 渲染显示 Markdown 内容
- **打字指示器**: 流式输入时显示闪烁的光标动画
- **响应式布局**: 用户消息右对齐，AI 消息左对齐
- **动画效果**: 消息出现时的淡入动画效果

### 3. 输入组件：Input/index.vue

处理用户输入和发送逻辑，支持快捷键和流式控制：

```vue
<script setup>
import { useChat } from "@/hooks/useChat";

const { sendMessage, isStreaming, stopConversation } = useChat();

const inputMessage = ref("");

// 处理键盘事件
const handleKeyPress = (event) => {
  if (isStreaming.value) {
    stopConversation();
    return;
  }
  if (!inputMessage.value.trim()) return;
  if (event.key === "Enter" && !event.shiftKey) {
    event.preventDefault();
  }
  sendMessage(inputMessage.value);
  inputMessage.value = "";
};
</script>

<template>
  <!-- 输入区域 -->
  <div class="input-area">
    <div class="input-container">
      <textarea
        v-model="inputMessage"
        @keypress="handleKeyPress"
        placeholder="输入你的消息... (Enter发送，Shift+Enter换行)"
        class="message-input"
        rows="1"
      ></textarea>
      <button @click="handleKeyPress(inputMessage)" class="send-btn">
        {{ isStreaming ? "   ⏹️ 停止" : "发送" }}
      </button>
    </div>
  </div>
</template>

<style scoped>
.input-area {
  padding: 20px;
  background: white;
  border-top: 1px solid #eee;
}

.input-container {
  display: flex;
  gap: 10px;
  align-items: flex-end;
}

.message-input {
  flex: 1;
  border: 2px solid #e0e0e0;
  border-radius: 20px;
  padding: 12px 16px;
  font-size: 14px;
  resize: none;
  outline: none;
  transition: border-color 0.2s;
  min-height: 20px;
  max-height: 120px;
}

.message-input:focus {
  border-color: #667eea;
}

.send-btn {
  padding: 12px 24px;
  background: #667eea;
  color: white;
  border: none;
  border-radius: 20px;
  cursor: pointer;
  font-size: 14px;
  font-weight: 500;
  transition: all 0.2s;
  white-space: nowrap;
}

.send-btn:hover {
  background: #5a6fd8;
}
</style>
```

**输入特性：**

- **智能键盘处理**: Enter 键根据流式状态执行发送或停止操作
- **快捷键支持**: Shift+Enter 换行，Enter 发送消息
- **动态按钮状态**: 根据流式状态切换"发送"和"停止"按钮
- **自适应输入框**: 支持多行输入，最大高度限制
- **输入验证**: 防止发送空消息
- **视觉反馈**: 输入框聚焦时边框颜色变化
- **响应式设计**: 适配不同屏幕尺寸的布局

### 4. 头部组件：Head/index.vue

简洁的应用头部组件，提供品牌展示：

```vue
<script setup></script>

<template>
  <div class="chat-header">
    <h1>🤖 数字人助手</h1>
  </div>
</template>

<style scoped>
.chat-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.chat-header h1 {
  margin: 0;
  font-size: 24px;
  font-weight: 600;
}
</style>
```

**头部特性：**

- **渐变背景**: 使用 CSS 渐变创建美观的视觉效果
- **品牌展示**: 清晰的标题和图标展示
- **预留扩展**: 预留了操作按钮的位置，便于后续功能扩展

## 🎨 UI 组件库支持

### Naive UI 集成

项目已集成 [Naive UI](https://www.naiveui.com/) 组件库，这是一个基于 Vue 3 的现代化 UI 组件库：

**特性优势：**

- 🎯 **TypeScript 友好**: 完整的 TypeScript 支持
- 🎨 **主题定制**: 强大的主题系统，支持暗黑模式
- 📱 **响应式设计**: 适配各种屏幕尺寸
- ⚡ **性能优化**: 按需加载，减少打包体积
- 🔧 **易于使用**: 简洁的 API 设计

**使用示例：**

```vue
<script setup>
import { NButton, NMessage } from "naive-ui";

// 显示消息提示
const showMessage = () => {
  window.$message.success("操作成功！");
};
</script>

<template>
  <div>
    <n-button type="primary" @click="showMessage"> 点击我 </n-button>
  </div>
</template>
```

**按需导入配置：**

```typescript
// vite.config.ts
import { defineConfig } from "vite";
import vue from "@vitejs/plugin-vue";
import AutoImport from "unplugin-auto-import/vite";

export default defineConfig({
  plugins: [
    vue(),
    AutoImport({
      imports: [
        "vue",
        {
          "naive-ui": [
            "useMessage",
            "useDialog",
            "useNotification",
            "useLoadingBar",
          ],
        },
      ],
      dts: true,
    }),
  ],
});
```

## 🔧 开发配置

### 环境要求

- Node.js >= 16.0.0
- pnpm >= 7.0.0

### 本地开发

#### 快速开始

```bash
# 1. 克隆项目
git clone <repository-url>
cd web-client

# 2. 安装依赖
pnpm install

# 3. 启动开发服务器
pnpm run dev

# 4. 打开浏览器访问
# http://localhost:5173
```

#### 开发命令

```bash
# 启动开发服务器（热重载）
pnpm run dev

# 构建生产版本
pnpm run build

# 预览生产构建
pnpm run preview

# 类型检查
pnpm run type-check

# 代码格式化
pnpm run format

# 代码检查
pnpm run lint
```

#### 开发环境配置

##### 环境变量配置

创建 `.env.local` 文件：

```bash
# API 基础地址
VITE_API_BASE_URL=http://localhost:3000

# 应用标题
VITE_APP_TITLE=数字人助手

# 是否启用调试模式
VITE_DEBUG=true
```

##### Vite 配置优化

```typescript
// vite.config.ts
import { defineConfig } from "vite";
import vue from "@vitejs/plugin-vue";
import AutoImport from "unplugin-auto-import/vite";

export default defineConfig({
  plugins: [
    vue(),
    AutoImport({
      imports: ["vue"],
      dts: true,
    }),
  ],
  resolve: {
    alias: {
      "@": resolve(__dirname, "src"),
    },
  },
  server: {
    port: 5173,
    host: true, // 允许外部访问
    proxy: {
      "/api": {
        target: process.env.VITE_API_BASE_URL || "http://localhost:3000",
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, ""),
      },
    },
  },
  build: {
    // 构建优化
    rollupOptions: {
      output: {
        manualChunks: {
          "vue-vendor": ["vue"],
          "ui-vendor": ["naive-ui"],
          "utils-vendor": ["markdown-it", "highlight.js"],
        },
      },
    },
    // 压缩配置
    minify: "terser",
    terserOptions: {
      compress: {
        drop_console: true,
        drop_debugger: true,
      },
    },
  },
});
```

#### 开发工具推荐

##### VS Code 扩展

```json
{
  "recommendations": [
    "Vue.volar",
    "Vue.vscode-typescript-vue-plugin",
    "bradlc.vscode-tailwindcss",
    "esbenp.prettier-vscode",
    "dbaeumer.vscode-eslint"
  ]
}
```

##### VS Code 设置

```json
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "typescript.preferences.importModuleSpecifier": "relative"
}
```

### Vite 配置

```typescript
import { defineConfig } from "vite";
import vue from "@vitejs/plugin-vue";
import AutoImport from "unplugin-auto-import/vite";

export default defineConfig({
  plugins: [
    vue(),
    AutoImport({
      imports: ["vue"],
      dts: true, // 自动生成类型声明
    }),
  ],
  resolve: {
    alias: {
      "@": resolve(__dirname, "src"),
    },
  },
  server: {
    port: 5173,
    proxy: {
      "/api": {
        target: "http://localhost:3000", // 后端服务地址
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, ""),
      },
    },
  },
});
```

## 📦 核心依赖

### 生产依赖

| 包名                              | 版本       | 用途                                       |
| --------------------------------- | ---------- | ------------------------------------------ |
| **vue**                           | `^3.5.18`  | Vue 3 框架核心，提供响应式系统和组件化开发 |
| **@microsoft/fetch-event-source** | `^2.0.1`   | SSE 客户端库，处理流式数据接收             |
| **markdown-it**                   | `^14.1.0`  | Markdown 解析和渲染，支持扩展插件          |
| **highlight.js**                  | `^11.11.1` | 代码语法高亮库，支持多种编程语言           |
| **uuid**                          | `^13.0.0`  | 生成唯一标识符，用于消息 ID                |
| **mitt**                          | `^3.0.1`   | 轻量级事件总线，用于组件间通信             |
| **naive-ui**                      | `^2.42.0`  | Vue 3 UI 组件库，提供现代化界面组件        |
| **qs**                            | `^6.14.0`  | URL 查询字符串解析和序列化库               |

### 开发依赖

| 包名                     | 版本      | 用途                                |
| ------------------------ | --------- | ----------------------------------- |
| **vite**                 | `^5.4.10` | 现代化构建工具，提供快速的开发体验  |
| **@vitejs/plugin-vue**   | `^5.2.1`  | Vite 的 Vue 单文件组件支持插件      |
| **@vue/tsconfig**        | `^0.7.0`  | Vue 官方 TypeScript 配置            |
| **vue-tsc**              | `^2.1.10` | Vue TypeScript 编译器，用于类型检查 |
| **unplugin-auto-import** | `^20.1.0` | 自动导入 Vue API 的 Vite 插件       |

### 依赖说明

#### 核心功能依赖

1. **Vue 3 生态**

   - `vue`: 核心框架，提供 Composition API 和响应式系统
   - `@vitejs/plugin-vue`: 支持 `.vue` 单文件组件

2. **流式通信**

   - `@microsoft/fetch-event-source`: 处理 Server-Sent Events，实现实时数据流
   - 支持连接中断、错误重试等高级功能

3. **内容渲染**

   - `markdown-it`: 将 Markdown 文本转换为 HTML
   - `highlight.js`: 为代码块提供语法高亮

4. **工具库**
   - `uuid`: 生成全局唯一标识符
   - `mitt`: 轻量级事件发布订阅系统
   - `qs`: URL 参数处理

#### UI 组件库

- **Naive UI**: 现代化的 Vue 3 UI 组件库
  - 完整的 TypeScript 支持
  - 丰富的组件生态
  - 主题定制能力
  - 按需加载支持

#### 开发工具

- **Vite**: 下一代前端构建工具

  - 极快的冷启动速度
  - 热模块替换 (HMR)
  - 开箱即用的 TypeScript 支持

- **Auto Import**: 自动导入 Vue API
  - 减少重复的 import 语句
  - 自动生成类型声明文件
  - 提升开发效率

### 版本兼容性

- **Node.js**: >= 16.0.0
- **pnpm**: >= 7.0.0
- **Vue**: 3.5.x (支持 Composition API)
- **TypeScript**: 5.x

### 包管理器

项目使用 `pnpm` 作为包管理器，相比 npm 和 yarn 具有以下优势：

- 🚀 **更快的安装速度**: 通过硬链接和符号链接优化
- 💾 **节省磁盘空间**: 共享依赖包，避免重复存储
- 🔒 **严格的依赖管理**: 避免幽灵依赖问题
- 📦 **更好的 monorepo 支持**: 适合多包项目管理

## 🎨 样式设计

### 设计理念

- **现代化**: 采用卡片式设计和柔和阴影，营造现代感
- **响应式**: 适配桌面和移动端，提供一致的用户体验
- **可读性**: 优化字体和间距，提升阅读体验
- **交互反馈**: 丰富的动画和状态反馈，增强用户交互体验
- **一致性**: 统一的色彩方案和设计语言

### 核心样式实现

#### 1. 主应用容器 (App.vue)

```css
.chat-app {
  display: flex;
  flex-direction: column;
  height: 100vh;
  max-width: 800px;
  margin: 0 auto;
  background: #f5f5f5;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
}

/* 动画效果 */
@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes blink {
  0%,
  50% {
    opacity: 1;
  }
  51%,
  100% {
    opacity: 0;
  }
}

/* 自定义滚动条 */
.chat-container::-webkit-scrollbar {
  width: 6px;
}

.chat-container::-webkit-scrollbar-track {
  background: #f1f1f1;
}

.chat-container::-webkit-scrollbar-thumb {
  background: #c1c1c1;
  border-radius: 3px;
}

.chat-container::-webkit-scrollbar-thumb:hover {
  background: #a8a8a8;
}
```

#### 2. 头部样式 (Head/index.vue)

```css
.chat-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.chat-header h1 {
  margin: 0;
  font-size: 24px;
  font-weight: 600;
}
```

#### 3. 消息样式 (Chat/index.vue)

```css
.chat-container {
  flex: 1;
  overflow-y: auto;
  padding: 20px;
  background: white;
}

.welcome-message {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 100%;
  text-align: center;
}

.message {
  display: flex;
  margin-bottom: 20px;
  animation: fadeIn 0.3s ease-in;
}

.message.user {
  flex-direction: row-reverse;
}

.message-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
  margin: 0 10px;
  background: #f0f0f0;
}

.message.user .message-avatar {
  background: #667eea;
  color: white;
}

.message-content {
  max-width: 70%;
  background: #f8f9fa;
  padding: 12px 16px;
  border-radius: 18px;
  position: relative;
}

.message.user .message-content {
  background: #667eea;
  color: white;
}

.typing-indicator {
  animation: blink 1s infinite;
  color: #667eea;
}
```

#### 4. 输入框样式 (Input/index.vue)

```css
.input-area {
  padding: 20px;
  background: white;
  border-top: 1px solid #eee;
}

.input-container {
  display: flex;
  gap: 10px;
  align-items: flex-end;
}

.message-input {
  flex: 1;
  border: 2px solid #e0e0e0;
  border-radius: 20px;
  padding: 12px 16px;
  font-size: 14px;
  resize: none;
  outline: none;
  transition: border-color 0.2s;
  min-height: 20px;
  max-height: 120px;
}

.message-input:focus {
  border-color: #667eea;
}

.send-btn {
  padding: 12px 24px;
  background: #667eea;
  color: white;
  border: none;
  border-radius: 20px;
  cursor: pointer;
  font-size: 14px;
  font-weight: 500;
  transition: all 0.2s;
  white-space: nowrap;
}

.send-btn:hover {
  background: #5a6fd8;
}
```

### 设计系统

#### 色彩方案

- **主色调**: `#667eea` (蓝紫色)
- **渐变背景**: `linear-gradient(135deg, #667eea 0%, #764ba2 100%)`
- **背景色**: `#f5f5f5` (浅灰)
- **消息背景**: `#f8f9fa` (更浅的灰)
- **边框色**: `#e0e0e0` (淡灰)
- **文字色**: `#333` (深灰)

#### 间距系统

- **小间距**: `8px`, `10px`
- **中间距**: `12px`, `16px`, `20px`
- **大间距**: `24px`

#### 圆角系统

- **小圆角**: `6px`, `8px`
- **中圆角**: `12px`, `18px`, `20px`
- **大圆角**: `50%` (圆形头像)

### 响应式设计

```css
/* 移动端适配 */
@media (max-width: 768px) {
  .chat-app {
    max-width: 100%;
    border-radius: 0;
    height: 100vh;
  }

  .message-content {
    max-width: 85%;
  }

  .input-area {
    padding: 15px;
  }
}
```

## 🔗 与后端集成

### API 代理配置

通过 Vite 代理配置，前端请求 `/api/*` 会自动转发到后端服务：

```typescript
proxy: {
  "/api": {
    target: "http://localhost:3000",
    changeOrigin: true,
    rewrite: (path) => path.replace(/^\/api/, ""),
  },
}
```

### SSE 连接处理

使用 `@microsoft/fetch-event-source` 库处理 Server-Sent Events：

```javascript
fetchEventSource("/api/ai/chat/stream-sse", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
  },
  body: JSON.stringify({ message: userMsg }),
  signal: controller.signal,
  onmessage: handleStreamMessage,
  onerror: handleStreamError,
});
```

## 🧪 功能测试

### 基本功能测试

1. **消息发送**: 输入消息并发送
2. **流式显示**: 观察 AI 回复的逐字显示
3. **Markdown 渲染**: 发送包含 Markdown 格式的消息
4. **代码高亮**: 发送代码块测试语法高亮
5. **停止功能**: 在 AI 回复过程中点击停止按钮

### 测试用例

````markdown
# 测试 Markdown 渲染

请回复一段包含以下格式的内容：

- **粗体文本**
- _斜体文本_
- `行内代码`
- [链接](https://example.com)

## 代码块测试

```javascript
function hello() {
  console.log("Hello World!");
}
```
````

## 数学公式测试

行内公式：$E = mc^2$
块级公式：$$\sum_{i=1}^{n} x_i$$

````

## 🚀 部署指南

### 生产构建

#### 基础构建

```bash
# 1. 安装依赖
pnpm install

# 2. 构建生产版本
pnpm run build

# 3. 构建产物在 dist 目录
ls -la dist/
```

#### 构建优化

```bash
# 分析构建产物
pnpm run build --analyze

# 检查构建产物大小
npx vite-bundle-analyzer dist/
```

### 静态部署

#### Nginx 部署

**1. 复制构建产物**

```bash
# 复制到 Nginx 目录
sudo cp -r dist/* /var/www/html/

# 设置权限
sudo chown -R www-data:www-data /var/www/html/
```

**2. Nginx 配置**

```nginx
server {
    listen 80;
    server_name your-domain.com;
    root /var/www/html;
    index index.html;

    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # API 代理
    location /api/ {
        proxy_pass http://localhost:3000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # SPA 路由支持
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

#### Apache 部署

**1. 复制构建产物**

```bash
# 复制到 Apache 目录
sudo cp -r dist/* /var/www/html/
```

**2. .htaccess 配置**

```apache
RewriteEngine On

# SPA 路由支持
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.html [L]

# 静态资源缓存
<IfModule mod_expires.c>
    ExpiresActive on
    ExpiresByType text/css "access plus 1 year"
    ExpiresByType application/javascript "access plus 1 year"
    ExpiresByType image/png "access plus 1 year"
    ExpiresByType image/jpg "access plus 1 year"
    ExpiresByType image/jpeg "access plus 1 year"
    ExpiresByType image/gif "access plus 1 year"
    ExpiresByType image/svg+xml "access plus 1 year"
</IfModule>
```

### Docker 部署

#### 1. 创建 Dockerfile

```dockerfile
# 构建阶段
FROM node:18-alpine as builder

WORKDIR /app

# 复制依赖文件
COPY package.json pnpm-lock.yaml ./

# 安装 pnpm
RUN npm install -g pnpm

# 安装依赖
RUN pnpm install --frozen-lockfile

# 复制源代码
COPY . .

# 构建应用
RUN pnpm run build

# 生产阶段
FROM nginx:alpine

# 复制构建产物
COPY --from=builder /app/dist /usr/share/nginx/html

# 复制 Nginx 配置
COPY nginx.conf /etc/nginx/conf.d/default.conf

# 暴露端口
EXPOSE 80

# 启动 Nginx
CMD ["nginx", "-g", "daemon off;"]
```

#### 2. Nginx 配置文件

```nginx
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # API 代理（如果有后端服务）
    location /api/ {
        proxy_pass http://backend:3000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # SPA 路由支持
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

#### 3. Docker Compose 部署

```yaml
version: '3.8'

services:
  web-client:
    build: .
    ports:
      - "80:80"
    environment:
      - NODE_ENV=production
    depends_on:
      - backend
    networks:
      - app-network

  backend:
    image: your-backend-image:latest
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    networks:
      - app-network

networks:
  app-network:
    driver: bridge
```

#### 4. 构建和运行

```bash
# 构建 Docker 镜像
docker build -t web-client:latest .

# 运行容器
docker run -d -p 80:80 --name web-client web-client:latest

# 使用 Docker Compose
docker-compose up -d
```

### 云平台部署

#### Vercel 部署

创建 `vercel.json` 文件：

```json
{
  "version": 2,
  "builds": [
    {
      "src": "package.json",
      "use": "@vercel/static-build",
      "config": {
        "distDir": "dist"
      }
    }
  ],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "/index.html"
    }
  ]
}
```

#### Netlify 部署

创建 `netlify.toml` 文件：

```toml
[build]
  publish = "dist"
  command = "pnpm run build"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200

[build.environment]
  NODE_VERSION = "18"
```

## 🔧 故障排除和常见问题

### 常见问题

#### 1. 开发环境问题

**Q: 启动开发服务器时出现端口占用错误**

```bash
Error: listen EADDRINUSE: address already in use :::5173
```

**解决方案：**

```bash
# 方法1: 更换端口
pnpm run dev --port 3000

# 方法2: 杀死占用端口的进程
# Windows
netstat -ano | findstr :5173
taskkill /PID <进程ID> /F

# macOS/Linux
lsof -ti:5173 | xargs kill -9
```

**Q: 依赖安装失败**

```bash
# 清除缓存重新安装
pnpm store prune
rm -rf node_modules pnpm-lock.yaml
pnpm install
```

#### 2. 构建问题

**Q: 构建时出现内存不足错误**

```bash
# 增加 Node.js 内存限制
NODE_OPTIONS="--max-old-space-size=4096" pnpm run build
```

**Q: 构建产物过大**

```bash
# 分析构建产物
npx vite-bundle-analyzer dist/

# 优化方案：
# 1. 启用代码分割
# 2. 使用 CDN 加载大型库
# 3. 移除未使用的依赖
```

#### 3. 运行时问题

**Q: SSE 连接失败**

```javascript
// 检查网络连接和后端服务
console.log('检查后端服务是否启动:', process.env.VITE_API_BASE_URL)

// 检查 CORS 配置
// 后端需要允许前端域名访问
```

**Q: Markdown 渲染异常**

```javascript
// 检查 markdown-it 配置
const markdown = MarkdownIt({
  html: true,
  linkify: true,
  typographer: true,
  breaks: true,
})

// 确保 highlight.js 正确导入
import hljs from 'highlight.js'
```

#### 4. 部署问题

**Q: Nginx 部署后页面空白**

```nginx
# 检查 Nginx 配置
server {
    listen 80;
    root /usr/share/nginx/html;
    index index.html;

    # 重要：支持 SPA 路由
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

**Q: Docker 构建失败**

```dockerfile
# 检查 Dockerfile 语法
# 确保 COPY 路径正确
COPY dist/ /usr/share/nginx/html

# 检查文件权限
RUN chown -R nginx:nginx /usr/share/nginx/html
```

### 调试技巧

#### 1. 开发调试

**启用 Vue DevTools**

```javascript
// main.ts
if (process.env.NODE_ENV === 'development') {
  app.config.performance = true
}
```

**网络请求调试**

```javascript
// useChat.js 中添加调试日志
const queryAnswer = async (message) => {
  console.log('发送请求:', message)

  fetchEventSource("/api/ai/chat/stream-sse", {
    // ... 配置
    onmessage: (ev) => {
      console.log('收到消息:', ev.data)
      handleStreamMessage(ev)
    },
    onerror: (err) => {
      console.error('连接错误:', err)
      handleStreamError(err)
    }
  })
}
```

#### 2. 性能优化

**代码分割**

```typescript
// 路由懒加载
const Chat = () => import('./components/Chat/index.vue')

// 组件懒加载
const HeavyComponent = defineAsyncComponent(() =>
  import('./components/HeavyComponent.vue')
)
```

**缓存策略**

```typescript
// vite.config.ts
export default defineConfig({
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          'vue-vendor': ['vue'],
          'ui-vendor': ['naive-ui'],
          'utils-vendor': ['markdown-it', 'highlight.js'],
        },
      },
    },
  },
})
```

### 错误监控

#### 1. 前端错误监控

```javascript
// 全局错误处理
window.addEventListener('error', (event) => {
  console.error('全局错误:', event.error)
  // 发送到错误监控服务
})

window.addEventListener('unhandledrejection', (event) => {
  console.error('未处理的 Promise 拒绝:', event.reason)
  // 发送到错误监控服务
})
```

#### 2. 网络监控

```javascript
// 监控 SSE 连接状态
const monitorConnection = () => {
  const connection = new EventSource('/api/ai/chat/stream-sse')

  connection.onopen = () => {
    console.log('SSE 连接已建立')
  }

  connection.onerror = (error) => {
    console.error('SSE 连接错误:', error)
    // 实现重连逻辑
  }
}
```

### 最佳实践

#### 1. 代码规范

```javascript
// 使用 ESLint 和 Prettier
// .eslintrc.js
module.exports = {
  extends: [
    '@vue/typescript/recommended',
    'plugin:vue/vue3-recommended'
  ],
  rules: {
    'vue/multi-word-component-names': 'off',
    '@typescript-eslint/no-explicit-any': 'warn'
  }
}
```

#### 2. 类型安全

```typescript
// 定义接口类型
interface Message {
  id: string
  role: 'user' | 'assistant'
  content: string
  htmlStr?: string
  timestamp?: number
}

// 使用类型断言
const messages = ref<Message[]>([])
```

#### 3. 测试策略

```javascript
// 单元测试示例
import { describe, it, expect } from 'vitest'
import { useChat } from '@/hooks/useChat'

describe('useChat', () => {
  it('应该能够发送消息', () => {
    const { sendMessage, messages } = useChat()
    sendMessage('Hello')
    expect(messages.value).toHaveLength(1)
  })
})
```

## 🎯 总结

本项目展示了如何使用现代化的前端技术栈构建一个功能完整的 AI 聊天客户端。通过 Vue 3 的组合式 API 实现了清晰的逻辑组织，集成 Markdown 渲染和代码高亮提升了用户体验，支持流式显示和停止功能满足了实时交互需求。

### 技术亮点

- 🚀 **现代化技术栈**: Vue 3 + TypeScript + Vite + Naive UI
- ⚡ **实时流式通信**: 基于 SSE 的流畅用户体验
- 🎨 **美观的界面设计**: 响应式布局和现代化 UI
- 🔧 **完善的开发工具**: 自动导入、类型检查、热重载
- 📦 **灵活的部署方案**: 支持多种部署方式
- 🛠️ **易于扩展**: 模块化架构，便于功能扩展

### 适用场景

该架构不仅适用于 AI 聊天场景，还可以扩展到：

- 💬 **客服系统**: 在线客服和用户支持
- 🤝 **协作工具**: 团队沟通和项目管理
- 📚 **教育平台**: 在线学习和智能答疑
- 🏥 **医疗咨询**: 智能问诊和健康咨询
- 🛒 **电商助手**: 购物咨询和产品推荐

通过模块化的组件设计和清晰的代码结构，可以轻松定制界面样式和扩展功能特性，满足不同业务场景的需求。
````
