# NestJS AI 流式聊天服务

在 AI 应用开发中，流式响应已经成为提升用户体验的关键特性。本文将带你从零开始，使用 NestJS 框架构建一个支持实时流式输出的 AI 聊天服务，集成阿里云百炼大模型，并实现完整的停止功能。

## 🚀 项目概述

这是一个基于 NestJS 构建的 AI 流式聊天服务，核心特性包括：

- ✅ **实时流式响应**: AI 回复逐字实时显示，避免用户长时间等待
- ✅ **停止功能**: 支持用户中断 AI 生成过程
- ✅ **SSE 支持**: 基于 Server-Sent Events 实现高效服务器推送
- ✅ **阿里云百炼**: 集成阿里云百炼大模型 API
- ✅ **TypeScript**: 完整的类型安全支持
- ✅ **可视化测试界面**: 内置前端页面方便调试

## 📁 项目结构

```
stream-serve/
├── src/
│   ├── ai/                    # AI 模块
│   │   ├── ai.controller.ts   # AI 控制器
│   │   ├── ai.service.ts      # AI 服务
│   │   └── ai.module.ts       # AI 模块定义
│   ├── app.controller.ts      # 应用控制器
│   ├── app.service.ts         # 应用服务
│   ├── app.module.ts          # 应用模块
│   └── main.ts               # 应用入口
├── public/
│   └── test-stream.html      # 测试页面
├── package.json              # 依赖配置
├── tsconfig.json            # TypeScript 配置
└── README.md                # 项目文档
```

## 🔍 核心实现详解

### 1. AI 服务层：实现流式调用逻辑

ai.service.ts 是与阿里云百炼大模型交互的核心，负责处理流式数据：

```typescript
import { Injectable } from '@nestjs/common';
import OpenAI from 'openai';

@Injectable()
export class AiService {
  private openai: OpenAI;

  constructor() {
    // 初始化阿里云百炼客户端
    this.openai = new OpenAI({
      apiKey: 'sk-your-api-key-here',
      baseURL: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
    });
  }

  // 流式聊天 - 使用异步生成器逐步返回数据
  async *streamChat(
    messages: OpenAI.Chat.Completions.ChatCompletionMessageParam[],
  ) {
    try {
      const stream = await this.openai.chat.completions.create({
        model: 'qwen-plus',
        messages,
        stream: true, // 开启流式响应
      });

      // 使用 for await 循环处理流式数据
      for await (const chunk of stream) {
        const content = chunk.choices[0]?.delta?.content;
        if (content) {
          yield content; // 逐个产出数据块
        }
      }
    } catch (error) {
      console.error('AI服务错误：', error);
      throw new Error('AI服务调用失败');
    }
  }
}
```

**技术亮点：：**

- `async *streamChat()`: 异步生成器函数，支持逐步产出数据
- `yield content`: 每次产出一个数据块，实现流式传输
- `for await`: 处理异步迭代器，等待每个数据块

### 2. 控制器层：处理 SSE 协议

ai.controller.ts 负责接收客户端请求，通过 SSE 协议推送实时数据：

```typescript
import { Controller, Post, Body, Res, HttpStatus } from '@nestjs/common';
import type { Response } from 'express';
import { AiService } from './ai.service';

interface ChatRequest {
  message: string;
  systemPrompt?: string;
}

@Controller('ai')
export class AiController {
  constructor(private readonly aiService: AiService) {}

  @Post('chat/stream-sse')
  async streamChatSSE(@Body() body: ChatRequest, @Res() res: Response) {
    const messages = [
      {
        role: 'system' as const,
        content: body.systemPrompt || '你是一个专业的编程助手',
      },
      { role: 'user' as const, content: body.message },
    ];

    try {
      // 设置 SSE 响应头
      res.setHeader('Content-Type', 'text/event-stream');
      res.setHeader('Cache-Control', 'no-cache');
      res.setHeader('Connection', 'keep-alive');
      res.setHeader('Access-Control-Allow-Origin', '*');

      res.status(HttpStatus.OK);

      // 发送开始信号
      res.write('data: {"type": "start"}\n\n');

      // 流式返回 AI 数据
      for await (const chunk of this.aiService.streamChat(messages)) {
        const data = JSON.stringify({ type: 'chunk', content: chunk });
        res.write(`data: ${data}\n\n`);
      }

      // 发送结束信号
      res.write('data: {"type": "end"}\n\n');
      res.end();
    } catch (error) {
      // 错误处理
      const errorData = JSON.stringify({
        type: 'error',
        error: '服务器内部错误',
        message: error.message,
      });
      res.write(`data: ${errorData}\n\n`);
      res.end();
    }
  }
}
```

**SSE 协议要点：**

- **SSE 响应头**: 设置正确的 Content-Type 和缓存策略
- **消息格式**: 使用 `data: {...}\n\n` 格式符合 SSE 标准
- **流式处理**: `for await` 循环实时处理 AI 响应
- **缓存处理**: 使用 keep-alive 保持长连接

### 3. 前端实现：接收流式数据并支持停止

test-stream.html 实现了完整的客户端逻辑：

```javascript
// 全局变量
let currentController = null; // 用于控制停止

// 使用原生fetch实现SSE，支持停止功能
async function testEventSourceSSE() {
  setLoading(true);
  responseDiv.className = 'response';
  responseDiv.textContent = '';

  // 创建 AbortController 用于停止
  currentController = new AbortController();

  try {
    const response = await fetch('/ai/chat/stream-sse', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(getRequestBody()),
      signal: currentController.signal, // 支持停止
    });

    if (!response.ok) {
      throw new Error(`HTTP错误: ${response.status}`);
    }

    const reader = response.body.getReader();
    const decoder = new TextDecoder();

    // 流式读取响应数据
    while (true) {
      const { done, value } = await reader.read();

      if (done) break;

      const chunk = decoder.decode(value, { stream: true });
      const lines = chunk.split('\n');

      // 解析 SSE 消息
      for (const line of lines) {
        if (line.startsWith('data: ') && line.length > 6) {
          try {
            const data = JSON.parse(line.slice(6));

            if (data.type === 'chunk') {
              responseDiv.textContent += data.content; // 实时显示
            } else if (data.type === 'end') {
              break; // 结束
            } else if (data.type === 'error') {
              responseDiv.className = 'response error';
              responseDiv.textContent = `错误: ${data.message}`;
              return;
            }
          } catch (parseError) {
            console.warn('解析SSE数据失败:', line);
          }
        }
      }
    }
  } catch (error) {
    if (error.name === 'AbortError') {
      responseDiv.textContent += '\n\n[用户停止生成]';
    } else {
      responseDiv.className = 'response error';
      responseDiv.textContent = `连接错误: ${error.message}`;
    }
  } finally {
    setLoading(false);
    currentController = null;
  }
}

// 停止流式生成
function stopStream() {
  if (currentController) {
    currentController.abort(); // 中断请求
    currentController = null;
  }
}
```

**客户端关键技术：**

- **AbortController**: 实现请求的中断控制
- **流式读取**: 使用 `getReader()` 逐块读取响应
- **SSE 解析**: 正确解析 `data: ` 格式的消息
- **实时显示**: 每收到数据块立即更新界面

## 🔧 环境配置

### 环境变量

创建 `.env` 文件：

```bash
# 阿里云百炼 API 密钥
DASHSCOPE_API_KEY=sk-your-api-key-here

# 服务端口（可选）
PORT=3000
```

### 依赖安装

```bash
# 安装依赖
pnpm install

# 启动开发服务器
pnpm run start:dev

# 构建生产版本
pnpm run build

# 启动生产服务器
pnpm run start:prod
```

## 🌐 API 接口

### POST /ai/chat/stream-sse

流式聊天接口，返回 SSE 格式的实时数据。

**请求参数：**

```json
{
  "message": "你好，请介绍一下自己",
  "systemPrompt": "你是一个专业的编程助手"
}
```

**响应格式：**

```
data: {"type": "start"}

data: {"type": "chunk", "content": "你"}

data: {"type": "chunk", "content": "好"}

data: {"type": "end"}
```

## 🧪 测试

访问测试页面：`http://localhost:3000/test-stream.html`

- 输入问题并点击"开始聊天"
- 观察 AI 回复的实时显示效果
- 可随时点击"停止生成"中断对话

## 🔍 技术要点

### 1. 异步生成器 (Async Generator)

```typescript
async *streamChat(messages) {
  // 异步生成器函数
  for await (const chunk of stream) {
    yield chunk; // 逐个产出数据
  }
}
```

### 2. Server-Sent Events (SSE)

```typescript
// 设置 SSE 响应头
res.setHeader('Content-Type', 'text/event-stream');
res.setHeader('Cache-Control', 'no-cache');

// 发送 SSE 消息
res.write('data: {"type": "chunk", "content": "hello"}\n\n');
```

### 3. AbortController 停止机制

```javascript
// 创建控制器
const controller = new AbortController();

// 传递 signal
fetch(url, { signal: controller.signal });

// 中断请求
controller.abort();
```

## 🎯 总结

本文详细介绍了如何使用 NestJS 构建 AI 流式聊天服务，核心是通过异步生成器处理 AI 接口的流式响应，结合 SSE 协议实现服务器到客户端的实时推送，并利用 AbortController 实现请求中断功能。

这种架构不仅可以应用于 AI 聊天场景，还可以扩展到任何需要实时数据推送的业务中，如实时日志、进度展示等。
