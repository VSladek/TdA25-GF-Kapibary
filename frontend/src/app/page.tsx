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
    url: "/ws/chat",
    handleMessageAction,
    isError: false,
  });
  useEffect(() => {
    createConnection();
  }, []);

  const onSendAction = (message: string) => {
    sendMessage({
      timestamp: new Date().toUTCString(),
      username,
      message,
    } as Message);
  };

  return (
    <main className="flex flex-col [--chatSize:55px]">
      <UsernameDialog
        open={!username}
        setUserNameAction={(username: string) => setUsername(username)}
      />
      <ChatWindow
        messages={messages}
        className="h-[calc(100dvh-var(--chatSize))] p-2"
      />
      <ChatInput
        onSendAction={onSendAction}
        className="flex space-x-2 p-3 h-[var(--chatSize)]"
      />
    </main>
  );
}
