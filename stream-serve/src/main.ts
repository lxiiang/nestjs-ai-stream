import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { NestExpressApplication } from '@nestjs/platform-express';
import { join } from 'path';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  // 启用CORS
  app.enableCors();

  // 配置静态文件服务
  app.useStaticAssets(join(__dirname, '..', 'public'));

  await app.listen(process.env.PORT ?? 3000);
  console.log(`🚀 应用已启动: http://localhost:${process.env.PORT ?? 3000}`);
  console.log(
    `📝 测试页面: http://localhost:${process.env.PORT ?? 3000}/test-stream.html`,
  );
}
bootstrap();
