"use client";

import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useState } from "react";

export default function UsernameDialog({
  open,
  setUserNameAction,
}: {
  open: boolean;
  setUserNameAction: (username: string) => void;
}) {
  const [username, setUsername] = useState("");

  return (
    <Dialog open={open}>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Set your username</DialogTitle>
          <DialogDescription>
            This will be the name displayed to other users.
          </DialogDescription>
        </DialogHeader>
        <div className="grid gap-4 py-4">
          <div className="grid grid-cols-4 items-center gap-4">
            <Label htmlFor="username" className="text-right">
              Username
            </Label>
            <Input
              id="username"
              className="col-span-3"
              onChange={(e) => setUsername(e.target.value)}
              onKeyDown={(e) =>
                e.key === "Enter" && setUserNameAction(username)
              }
            />
          </div>
        </div>
        <DialogFooter>
          <Button type="submit" onClick={() => setUserNameAction(username)}>
            Set username
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
