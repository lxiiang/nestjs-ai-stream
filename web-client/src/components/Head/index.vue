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
  h1 {
    margin: 0;
    font-size: 24px;
    font-weight: 600;
  }
  .header-actions {
    display: flex;
    gap: 10px;
  }
  .header-actions {
    display: flex;
    gap: 10px;
  }
  .stop-btn,
  .clear-btn {
    padding: 8px 16px;
    border: none;
    border-radius: 6px;
    cursor: pointer;
    font-size: 14px;
    transition: all 0.2s;
  }

  .stop-btn {
    background: #ff4757;
    color: white;
  }
}
</style>
