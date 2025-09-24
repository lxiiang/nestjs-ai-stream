# Vue 3 AI 流式聊天客户端：现代化实时对话界面

基于 Vue 3 + TypeScript + Vite 构建的现代化 AI 聊天客户端，提供流畅的实时对话体验，支持 Markdown 渲染、代码高亮和流式停止功能。

## 🚀 项目概述

这是一个现代化的 AI 聊天前端应用，核心特性包括：

- ✅ **Vue 3 Composition API**: 使用最新的 Vue 3 组合式 API
- ✅ **TypeScript 支持**: 完整的类型安全保障
- ✅ **实时流式显示**: 支持 AI 回复逐字实时显示
- ✅ **Markdown 渲染**: 自动渲染 Markdown 格式内容
- ✅ **代码高亮**: 集成 highlight.js 支持多语言代码高亮
- ✅ **流式停止功能**: 支持用户中断 AI 生成过程
- ✅ **响应式设计**: 适配各种屏幕尺寸
- ✅ **组件化架构**: 模块化组件设计，易于维护扩展

## 📁 项目结构

```
web-client/
├── src/
│   ├── components/           # 组件目录
│   │   ├── Head/            # 头部组件
│   │   │   └── index.vue    # 应用头部
│   │   ├── Chat/            # 聊天组件
│   │   │   └── index.vue    # 聊天内容区域
│   │   └── Input/           # 输入组件
│   │       └── index.vue    # 消息输入框
│   ├── hooks/               # 组合式函数
│   │   ├── useChat.js       # 聊天逻辑钩子
│   │   └── useMitt.js       # 事件总线钩子
│   ├── assets/              # 静态资源
│   ├── App.vue              # 根组件
│   ├── main.ts              # 应用入口
│   └── style.css            # 全局样式
├── public/                  # 公共资源
├── index.html               # HTML 模板
├── vite.config.ts           # Vite 配置
├── package.json             # 依赖配置
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
  html: true,
  linkify: true,
  typographer: true,
  breaks: true,
  xhtmlOut: true,
  langPrefix: "language-",
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
      }
    }
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

- **组合式 API**: 使用 Vue 3 的 `ref` 和 `reactive` 管理状态
- **流式数据处理**: 通过 `fetchEventSource` 处理 SSE 数据流
- **Markdown 渲染**: 集成 `markdown-it` 实现富文本显示
- **代码高亮**: 使用 `highlight.js` 提供语法高亮
- **状态管理**: 响应式状态跟踪聊天状态和流式状态

### 2. 聊天内容组件：Chat/index.vue

负责展示聊天消息列表和处理消息渲染：

```vue
<template>
  <div class="chat-container" ref="chatContainer">
    <div class="messages-wrapper">
      <div
        v-for="message in messages"
        :key="message.mid"
        :class="['message', message.role]"
      >
        <div class="message-content">
          <!-- 用户消息 -->
          <div v-if="message.role === 'user'" class="text">
            {{ message.content }}
          </div>
          <!-- AI 消息 - 支持 Markdown 渲染 -->
          <div
            v-else-if="message.role === 'assistant'"
            class="text markdown-content"
            v-html="message.htmlStr || message.content"
          ></div>
        </div>
        <!-- 流式输入指示器 -->
        <div
          v-if="message.role === 'assistant' && isStreaming"
          class="typing-indicator"
        >
          <span class="cursor">|</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { useChat } from "@/hooks/useChat";
import { nextTick, watch } from "vue";

const { messages, isStreaming } = useChat();
const chatContainer = ref();

// 自动滚动到底部
const scrollToBottom = () => {
  nextTick(() => {
    if (chatContainer.value) {
      chatContainer.value.scrollTop = chatContainer.value.scrollHeight;
    }
  });
};

// 监听消息变化，自动滚动
watch(messages, scrollToBottom, { deep: true });
watch(isStreaming, scrollToBottom);
</script>
```

**组件特性：**

- **消息渲染**: 区分用户和 AI 消息的不同样式
- **Markdown 支持**: AI 消息支持 HTML 渲染显示 Markdown
- **自动滚动**: 新消息到达时自动滚动到底部
- **打字指示器**: 流式输入时显示光标动画

### 3. 输入组件：Input/index.vue

处理用户输入和发送逻辑：

```vue
<template>
  <div class="input-area">
    <div class="input-container">
      <textarea
        v-model="inputMessage"
        @keypress="handleKeyPress"
        placeholder="输入你的消息... (Enter发送，Shift+Enter换行)"
        class="message-input"
        rows="1"
      ></textarea>
      <button
        @click="handleSend"
        :disabled="!inputMessage.trim()"
        class="send-btn"
      >
        {{ isStreaming ? "⏹️ 停止" : "发送" }}
      </button>
    </div>
  </div>
</template>

<script setup>
import { useChat } from "@/hooks/useChat";

const { sendMessage, isStreaming, stopConversation } = useChat();
const inputMessage = ref("");

// 处理键盘事件
const handleKeyPress = (event) => {
  if (event.key === "Enter" && !event.shiftKey) {
    event.preventDefault();
    handleSend();
  }
};

// 处理发送
const handleSend = () => {
  if (!inputMessage.value.trim()) return;

  if (isStreaming.value) {
    stopConversation();
    return;
  }

  sendMessage(inputMessage.value);
  inputMessage.value = "";
};
</script>
```

**输入特性：**

- **快捷键支持**: Enter 发送，Shift+Enter 换行
- **状态响应**: 根据流式状态切换发送/停止按钮
- **输入验证**: 防止发送空消息

## 🔧 开发配置

### 环境要求

- Node.js >= 16.0.0
- pnpm >= 7.0.0

### 本地开发

```bash
# 安装依赖
pnpm install

# 启动开发服务器
pnpm run dev

# 构建生产版本
pnpm run build

# 预览生产构建
pnpm run preview
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

- **vue**: Vue 3 框架核心
- **@microsoft/fetch-event-source**: SSE 客户端库
- **markdown-it**: Markdown 解析和渲染
- **highlight.js**: 代码语法高亮
- **uuid**: 生成唯一标识符
- **mitt**: 轻量级事件总线

### 开发依赖

- **vite**: 现代化构建工具
- **@vitejs/plugin-vue**: Vue SFC 支持
- **vue-tsc**: Vue TypeScript 编译器
- **unplugin-auto-import**: 自动导入 Vue API

## 🎨 样式设计

### 设计理念

- **现代化**: 采用卡片式设计和柔和阴影
- **响应式**: 适配桌面和移动端
- **可读性**: 优化字体和间距提升阅读体验
- **交互反馈**: 丰富的动画和状态反馈

### 主要样式特性

```css
/* 聊天容器 */
.chat-app {
  display: flex;
  flex-direction: column;
  height: 100vh;
  max-width: 800px;
  margin: 0 auto;
  background: #f5f5f5;
  border-radius: 12px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
}

/* 消息气泡 */
.message {
  animation: fadeIn 0.3s ease-out;
  margin-bottom: 16px;
}

/* 打字动画 */
.cursor {
  animation: blink 1s infinite;
}

/* 代码块样式 */
.markdown-content pre {
  background: #f8f9fa;
  border-radius: 8px;
  padding: 16px;
  overflow-x: auto;
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

```bash
# 构建项目
pnpm run build

# 构建产物在 dist 目录
ls dist/
````

### 静态部署

构建后的 `dist` 目录可以部署到任何静态文件服务器：

- **Nginx**: 配置反向代理到后端 API
- **Apache**: 设置 `.htaccess` 支持 SPA 路由
- **CDN**: 上传到 OSS/COS 等对象存储

### Docker 部署

```dockerfile
FROM nginx:alpine

# 复制构建产物
COPY dist/ /usr/share/nginx/html/

# 复制 Nginx 配置
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

## 🎯 总结

本项目展示了如何使用现代化的前端技术栈构建一个功能完整的 AI 聊天客户端。通过 Vue 3 的组合式 API 实现了清晰的逻辑组织，集成 Markdown 渲染和代码高亮提升了用户体验，支持流式显示和停止功能满足了实时交互需求。

该架构不仅适用于 AI 聊天场景，还可以扩展到客服系统、在线协作工具等需要实时通信的应用中。通过模块化的组件设计，可以轻松定制界面样式和扩展功能特性。
