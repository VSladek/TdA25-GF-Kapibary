import { useState } from "react";
import { Input } from "../ui/input";
import { Button } from "../ui/button";

export default function ChatInput({
  onSendAction,
}: {
  onSendAction: (message: string) => void;
}) {
  const [message, setMessage] = useState("");
  const onSend = () => {
    onSendAction(message);
    setMessage("");
  };
  return (
    <div className="flex space-x-2 p-2">
      <Input
        value={message}
        onChange={(e) => setMessage(e.target.value)}
        placeholder="Type a message"
        height="h-32"
        onKeyDown={(e) => e.key === "Enter" && onSend()}
      />
      <Button onClick={onSend}>Send</Button>
    </div>
  );
}
