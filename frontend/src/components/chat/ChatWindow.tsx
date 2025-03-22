"use client";
import { Message } from "@/types/Message";
import { ScrollArea } from "@/components/ui/scroll-area";

export default function ChatWindow({
  messages,
  className,
}: {
  messages: Message[];
  className?: string;
}) {
  return (
    <ScrollArea className={className} id="chat">
      {messages.map((message, index) => (
        <div key={index} className="*:mr-2">
          <span className="text-gray-500 text-sm">
            {new Date(message.timestamp).toLocaleTimeString(["cs-CZ"])}
          </span>
          <span className="font-bold">{message.username}</span>
          <span>{message.message}</span>
        </div>
      ))}
      <div ref={(el) => el?.scrollIntoView()} />
    </ScrollArea>
  );
}
