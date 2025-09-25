import { Injectable } from '@nestjs/common';
import OpenAI from 'openai';

@Injectable()
export class AiService {
  private openai: OpenAI;

  constructor() {
    this.openai = new OpenAI({
      apiKey: 'APIKEY', //作者用的是阿里云的百炼大模型有免费额度
      baseURL: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
    });
  }

  async *streamChat(
    messages: OpenAI.Chat.Completions.ChatCompletionMessageParam[],
  ) {
    try {
      const stream = await this.openai.chat.completions.create({
        model: 'qwen-plus',
        messages,
        stream: true,
      });

      for await (const chunk of stream) {
        const content = chunk.choices[0]?.delta?.content;
        if (content) {
          yield content;
        }
      }
    } catch (error) {
      console.error('AI服务错误：', error);
      throw new Error('AI服务调用失败');
    }
  }
}
