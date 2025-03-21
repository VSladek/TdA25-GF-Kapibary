import { Message } from "@/types/Message";
import { ScrollArea } from "@/components/ui/scroll-area";

export default function ChatWindow({ messages }: { messages: Message[] }) {
  return (
    <ScrollArea className="h-[93dvh]">
      {messages.map((message, index) => (
        <div key={index}>
          <span>{message.username}</span>:<span>{message.message}</span>
        </div>
      ))}
    </ScrollArea>
  );
}
