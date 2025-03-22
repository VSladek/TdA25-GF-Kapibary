import { useState } from "react";
import { Input } from "../ui/input";
import { Button } from "../ui/button";

export default function ChatInput({
  onSendAction,
  className,
}: {
  onSendAction: (message: string) => void;
  className?: string;
}) {
  const [message, setMessage] = useState("");
  const onSend = () => {
    if (!message) return;
    onSendAction(message);
    setMessage("");
    window.document.getElementById("chat")?.scrollTo({
      top: window.document.getElementById("chat")?.scrollHeight,
      behavior: "smooth",
    });
  };
  return (
    <div className={className}>
      <Input
        value={message}
        onChange={(e) => setMessage(e.target.value)}
        placeholder="Type a message"
        onKeyDown={(e) => e.key === "Enter" && onSend()}
        className="h-[38px]"
      />
      <Button
        onClick={onSend}
        className="h-[38px] text-white bg-blue-500 hover:bg-blue-700"
      >
        Send
      </Button>
    </div>
  );
}
