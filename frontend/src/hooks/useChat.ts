import { useState, useEffect, useRef, useCallback } from "react";
import { io, Socket } from "socket.io-client";
import { Message } from "../types";

type ConnectionStatus = "connecting" | "connected" | "disconnected" | "error";

interface UseChatOptions {
  chatId: string | null;
  token: string;
  userId: string;
  onMessage?: (message: Message) => void;
}

interface UseChatReturn {
  messages: Message[];
  sendMessage: (content: string) => void;
  connectionStatus: ConnectionStatus;
  isTyping: boolean;
}

const SERVER_URL = "http://localhost:3001";

export function useChat({ chatId, token, userId, onMessage }: UseChatOptions): UseChatReturn {
  const [messages, setMessages] = useState<Message[]>([]);
  const [connectionStatus, setConnectionStatus] = useState<ConnectionStatus>("disconnected");
  const [isTyping, setIsTyping] = useState(false);
  const socketRef = useRef<Socket | null>(null);
  const typingTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  //Load message history when chatId changes 
  useEffect(() => {
    if (!chatId || !token?.trim()) {
      setMessages([]);
      return;
    }

    fetch(`${SERVER_URL}/api/chats/${chatId}/messages`, {
      headers: { Authorization: `Bearer ${token}` },
    })
      .then((r) => r.json())
      .then((data) => {
        const loaded: Message[] = (data.messages ?? []).map((m: any) => ({
          id: m.id,
          senderId: m.senderId,
          content: m.text,
          timestamp: new Date(m.sentAt),
          isOwn: m.senderId === userId,
        }));
        setMessages(loaded);
      })
      .catch(() => {});
  }, [chatId]);   // only re-fetch when chat changes, not on every render

  // Socket.io connection
  useEffect(() => {
    if (!token || token.trim() === "") return;

    // If socket already exists and is connected, don't create a new one
    if (socketRef.current?.connected) return;

    setConnectionStatus("connecting");

    const socket = io(SERVER_URL, {
      auth: { token },
    });
    socketRef.current = socket;

    socket.on("connect", () => {
      setConnectionStatus("connected");
      if (chatId) socket.emit("join_chat", chatId);
    });

    socket.on("disconnect", () => setConnectionStatus("disconnected"));
    socket.on("connect_error", () => setConnectionStatus("error"));

    socket.on("receive_message", (m: any) => {
      setMessages((prev) => {
        // Ignore if we already have this message
        if (prev.some((msg) => msg.id === m.id)) return prev;
        return [...prev, {
          id: m.id,
          senderId: m.senderId,
          content: m.text,
          timestamp: new Date(m.sentAt),
          isOwn: false,
        }];
      });
      onMessage?.({ id: m.id, senderId: m.senderId, content: m.text, timestamp: new Date(m.sentAt), isOwn: false });
    });

    socket.on("message_sent", (m: any) => {
      setMessages((prev) => {
        // Already have the real message, do nothing
        if (prev.some((msg) => msg.id === m.id)) return prev;

        // Replace the optimistic message with the confirmed one
        const optimisticIndex = prev.findIndex(
          (msg) => msg.isOwn && msg.content === m.text && msg.id !== m.id
        );

        if (optimisticIndex !== -1) {
          const updated = [...prev];
          updated[optimisticIndex] = {
            id: m.id,
            senderId: m.senderId,
            content: m.text,
            timestamp: new Date(m.sentAt),
            isOwn: true,
          };
          return updated;
        }

        return [...prev, {
          id: m.id,
          senderId: m.senderId,
          content: m.text,
          timestamp: new Date(m.sentAt),
          isOwn: true,
        }];
      });
    });

    socket.on("typing", () => {
      setIsTyping(true);
      if (typingTimerRef.current) clearTimeout(typingTimerRef.current);
      typingTimerRef.current = setTimeout(() => setIsTyping(false), 2000);
    });

    return () => {
      socket.disconnect();
      socketRef.current = null;
      if (typingTimerRef.current) clearTimeout(typingTimerRef.current);
    };
  }, [token]);

  //Join new room when chatId changes
  useEffect(() => {
    if (chatId && socketRef.current?.connected) {
      socketRef.current.emit("join_chat", chatId);
    }
  }, [chatId]);

  // Sending a message
  const sendMessage = useCallback(
    (content: string) => {
      if (!content.trim() || !chatId || !socketRef.current) return;

      const optimistic: Message = {
        id: crypto.randomUUID(),
        senderId: userId,
        content: content.trim(),
        timestamp: new Date(),
        isOwn: true,
      };
      setMessages((prev) => [...prev, optimistic]);

      socketRef.current.emit("send_message", {
        chatId,
        text: content.trim(),
      });
    },
    [chatId, userId]
  );

  //Typing indicator
  const sendTyping = useCallback(() => {
    if (chatId && socketRef.current?.connected) {
      socketRef.current.emit("typing", chatId);
    }
  }, [chatId]);

  return { messages, sendMessage, connectionStatus, isTyping };
}