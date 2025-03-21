"use client";
import { useEffect, useState } from "react";

import useWebSocket from "@/hooks/UseWebSocket";
import UsernameDialog from "@/components/chat/UsernameDialog";
import ChatWindow from "@/components/chat/ChatWindow";
import ChatInput from "@/components/chat/ChatInput";
import { Message } from "@/types/Message";

export default function Home() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [username, setUsername] = useState<string | null>(null);

  const handleMessageAction = (message: MessageEvent) => {
    const data = JSON.parse(message.data);
    setMessages((prev) => [...prev, data]);
  };
  const { sendMessage, createConnection } = useWebSocket({
    url: "/api/ws/chat",
    handleMessageAction,
    isError: false,
  });
  useEffect(() => {
    createConnection();
  }, []);

  const onSendAction = (message: string) => {
    sendMessage({ username, message });
  };

  return (
    <main className="flex flex-col">
      <UsernameDialog
        open={!username}
        setUserNameAction={(username: string) => setUsername(username)}
      />
      <ChatWindow messages={messages} />
      <ChatInput onSendAction={onSendAction} />
    </main>
  );
}
