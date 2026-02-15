/**
 * WebSocket client: connect to backend WS (auction, live, match).
 * Base URL from NEXT_PUBLIC_WS_BASE_URL or derived from API host.
 */

function getWsBaseUrl(): string {
  if (typeof window === "undefined") return "";
  const api = process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:8000/api/v1";
  const u = new URL(api);
  const protocol = u.protocol === "https:" ? "wss:" : "ws:";
  const port = u.port && u.port !== "80" && u.port !== "443" ? `:${u.port}` : "";
  return `${protocol}//${u.hostname}${port}`;
}

export function getAuctionWsUrl(leagueId: string): string {
  return `${getWsBaseUrl()}/ws/auction/${leagueId}`;
}

export function getLiveWsUrl(leagueId: string): string {
  return `${getWsBaseUrl()}/ws/live/${leagueId}`;
}

export function getMatchWsUrl(matchId: number): string {
  return `${getWsBaseUrl()}/ws/match/${matchId}`;
}

export function createWebSocket(
  url: string,
  onMessage: (data: unknown) => void,
  onClose?: () => void,
  onError?: (e: Event) => void
): WebSocket {
  const ws = new WebSocket(url);
  ws.onmessage = (event) => {
    try {
      const data = typeof event.data === "string" ? JSON.parse(event.data) : event.data;
      onMessage(data);
    } catch {
      onMessage(event.data);
    }
  };
  ws.onclose = () => onClose?.();
  ws.onerror = (e) => onError?.(e);
  return ws;
}
