"use client";

import { ErrorToast } from "@/components/ErrorToast";
import { useCallback, useRef, useState, useEffect } from "react";

export default function useWebSocket({
  url,
  handleMessageAction,
  isError,
}: {
  url: string;
  handleMessageAction: (message: MessageEvent) => void;
  isError: boolean;
}) {
  const hardStop = useRef(false);

  useEffect(() => {
    if (isError) hardStop.current = true;
  }, [isError]);

  const websocketRef = useRef<WebSocket | null>(null);
  const attemptReconnectRef = useRef<() => void>(() => {});
  const reconnectTimeoutRef = useRef<number | null>(null);
  const realAttemptCount = useRef(0);
  const [reconnectAttempts, setReconnectAttempts] = useState(0);
  const [isConnected, setIsConnected] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  const cleanupWebSocket = useCallback(() => {
    if (websocketRef.current) {
      websocketRef.current.onopen = null;
      websocketRef.current.onclose = null;
      websocketRef.current.onerror = null;
      websocketRef.current.onmessage = null;
      websocketRef.current.close();
      websocketRef.current = null;
    }
  }, []);

  // Handle change of handleMessage function
  useEffect(() => {
    if (websocketRef.current)
      websocketRef.current.onmessage = handleMessageAction;
  }, [handleMessageAction]);

  const createConnection = useCallback(() => {
    if (hardStop.current) return;
    if (websocketRef.current && websocketRef.current?.readyState === 1) {
      setIsConnected(true);
      return;
    }
    if (websocketRef.current) {
      console.log("Cleaning up previous WebSocket instance.");
      cleanupWebSocket();
    }

    const protocol = window.location.protocol === "https:" ? "wss" : "ws";
    const host = window.location.host;
    const websocket = new WebSocket(`${protocol}://${host}${url}`);

    websocketRef.current = websocket;

    websocket.onopen = () => {
      console.log("Connected to game server");
      setIsLoading(false);
      setIsConnected(true);
      setReconnectAttempts(0);

      if (reconnectTimeoutRef.current) {
        clearTimeout(reconnectTimeoutRef.current);
        reconnectTimeoutRef.current = null;
      }
    };

    websocket.onclose = () => {
      console.log("Disconnected from game server");
      setIsLoading(false);
      setIsConnected(false);
      attemptReconnectRef.current();
    };

    websocket.onerror = (error) => {
      console.error("WebSocket error:", error);
      websocket.close();
      setIsConnected(false);
      setIsLoading(false);
    };

    websocket.onmessage = handleMessageAction;
  }, [url, handleMessageAction, cleanupWebSocket]);

  const attemptReconnect = useCallback(() => {
    if (hardStop.current) return;
    if (realAttemptCount.current >= 5) {
      console.log("Max reconnection attempts reached. Stopping.");
      ErrorToast({ message: "Failed to reconnect to server." });
      hardStop.current = true;
      return;
    }

    const timeout = Math.min(1000 * 2 ** realAttemptCount.current, 30000);
    realAttemptCount.current += 1;
    setReconnectAttempts((prev) => prev + 1);

    console.log(`Reconnecting in ${timeout / 1000} seconds...`);
    reconnectTimeoutRef.current = window.setTimeout(() => {
      createConnection();
    }, timeout);
  }, [createConnection, realAttemptCount]);

  useEffect(() => {
    attemptReconnectRef.current = attemptReconnect;
  }, [attemptReconnect]);

  useEffect(() => {
    if (hardStop.current) return;
    const handleOnline = () => {
      console.log("Network restored. Attempting to reconnect...");
      createConnection();
    };

    const handleOffline = () => {
      console.log("Network lost. Waiting for reconnection...");
      setIsConnected(false);
    };

    window.addEventListener("online", handleOnline);
    window.addEventListener("offline", handleOffline);

    return () => {
      if (reconnectTimeoutRef.current) {
        clearTimeout(reconnectTimeoutRef.current);
      }
      window.removeEventListener("online", handleOnline);
      window.removeEventListener("offline", handleOffline);
    };
  }, [createConnection]);

  const sendMessage = useCallback((message: object) => {
    if (websocketRef.current?.readyState === WebSocket.OPEN)
      websocketRef.current.send(JSON.stringify(message));
    else ErrorToast({ message: "Failed to send message." });
  }, []);

  return {
    createConnection,
    sendMessage,
    isConnected,
    isLoading,
    reconnectAttempts,
  };
}
