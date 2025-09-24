<script setup>
import { useChat } from "@/hooks/useChat";

const { messages } = useChat();
</script>

<template>
  <div id="chat-container" class="chat-container">
    <div v-if="messages.length === 0" class="welcome-message">
      <div class="welcome-content">
        <h2>👋 你好！我是你的数字人助手</h2>
        <p>有什么可以帮助你的吗？</p>
      </div>
    </div>

    <div
      v-for="message in messages"
      :key="message.id"
      :class="['message', message.role]"
    >
      <div class="message-avatar">
        <span v-if="message.role === 'user'">👤</span>
        <span v-else>🤖</span>
      </div>
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

.welcome-content h2 {
  color: #333;
  margin-bottom: 10px;
}

.welcome-content p {
  color: #666;
  font-size: 16px;
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

.message-text {
  line-height: 1.5;
  word-wrap: break-word;
}

.typing-indicator {
  animation: blink 1s infinite;
  color: #667eea;
}
</style>
