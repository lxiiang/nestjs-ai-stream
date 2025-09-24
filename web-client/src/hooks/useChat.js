import { ref } from "vue";
import { v4 as uuidv4 } from "uuid";
import { fetchEventSource } from "@microsoft/fetch-event-source";
import MarkdownIt from "markdown-it";
import hljs from "highlight.js";

const messages = ref([]);
const curMessage = ref({});
const controller = ref(null);
const isStreaming = ref(false);

const markdown = MarkdownIt({
  html: true, // 允许在 Markdown 中使用原始 HTML 标签
  linkify: true, // 自动将 URL 转换为链接
  typographer: true, // 启用智能引号和连字符
  breaks: true, // 启用自动换行
  xhtmlOut: true, // 使用 XHTML 模式
  langPrefix: "language-", // 添加语言前缀
});

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
  const handleStreamMessage = (ev) => {
    if (ev.data) {
      const data = JSON.parse(ev.data);
      if (data.type === "start") {
        curMessage.value = {
          mid: uuidv4(),
          role: "assistant",
          content: "",
        };
        messages.value.push(curMessage.value);
      }
      if (data.type === "chunk") {
        curMessage.value.content += data.content;
        curMessage.value.htmlStr = markdown.render(curMessage.value.content);
      }
      if (data.type === "end") {
        curMessage.value = {};
        isStreaming.value = false;
      } else if (data.type === "error") {
        isStreaming.value = false;
        messages.value.push({
          role: "assistant",
          content: data.message,
        });
      }
    }
  };

  const handleStreamError = (ev) => {
    isStreaming.value = false;
    messages.value.push({
      role: "assistant",
      content: "服务异常",
    });
  };
  // 接口调用
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
      // 处理错误
      onerror: (ev) => handleStreamError(ev),
    });
  };

  const sendMessage = (userMsg) => {
    if (!userMsg.trim()) return;
    const userMessage = {
      mid: uuidv4(),
      role: "user",
      content: userMsg,
    };
    messages.value.push(userMessage);
    isStreaming.value = true;
    // 只发送消息内容，不发送完整的消息对象
    queryAnswer({ message: userMsg });
  };

  const stopConversation = () => {
    if (controller) {
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
