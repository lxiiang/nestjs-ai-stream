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
      // 设置SSE响应头
      res.setHeader('Content-Type', 'text/event-stream');
      res.setHeader('Cache-Control', 'no-cache');
      res.setHeader('Connection', 'keep-alive');
      res.setHeader('Access-Control-Allow-Origin', '*');
      res.setHeader('Access-Control-Allow-Headers', 'Cache-Control');

      res.status(HttpStatus.OK);

      // 发送初始连接确认
      res.write('data: {"type": "start"}\n\n');

      // 流式返回数据
      for await (const chunk of this.aiService.streamChat(messages)) {
        const data = JSON.stringify({ type: 'chunk', content: chunk });
        res.write(`data: ${data}\n\n`);
      }

      // 发送结束信号
      res.write('data: {"type": "end"}\n\n');
      res.end();
    } catch (error) {
      console.error('SSE流式聊天错误：', error);
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
