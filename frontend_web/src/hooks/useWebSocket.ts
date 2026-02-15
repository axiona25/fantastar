"use client";

import { useEffect, useRef, useCallback, useState } from "react";
import { createWebSocket } from "@/services/wsClient";

/**
 * Hook to connect to a WebSocket URL and receive messages.
 * Returns last message and connection status; reconnects on close (optional).
 */
export function useWebSocket(
  url: string | null,
  options?: {
    onMessage?: (data: unknown) => void;
    reconnect?: boolean;
    reconnectIntervalMs?: number;
  }
) {
  const [lastMessage, setLastMessage] = useState<unknown>(null);
  const [connected, setConnected] = useState(false);
  const wsRef = useRef<WebSocket | null>(null);
  const reconnectTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const handleMessage = useCallback(
    (data: unknown) => {
      setLastMessage(data);
      options?.onMessage?.(data);
    },
    [options?.onMessage]
  );

  useEffect(() => {
    if (!url) return;

    const connect = () => {
      if (wsRef.current?.readyState === WebSocket.OPEN) return;
      const ws = createWebSocket(
        url,
        handleMessage,
        () => {
          setConnected(false);
          wsRef.current = null;
          if (options?.reconnect) {
            reconnectTimeoutRef.current = setTimeout(
              connect,
              options.reconnectIntervalMs ?? 3000
            );
          }
        },
        () => setConnected(false)
      );
      ws.onopen = () => setConnected(true);
      wsRef.current = ws;
    };

    connect();
    return () => {
      if (reconnectTimeoutRef.current) clearTimeout(reconnectTimeoutRef.current);
      wsRef.current?.close();
      wsRef.current = null;
      setConnected(false);
    };
  }, [url, handleMessage, options?.reconnect, options?.reconnectIntervalMs]);

  return { lastMessage, connected };
}
