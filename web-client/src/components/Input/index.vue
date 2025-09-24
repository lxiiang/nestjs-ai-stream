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
</style>
