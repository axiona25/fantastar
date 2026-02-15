/**
 * API client: base URL, Bearer token, 401 refresh and redirect.
 * Uses NEXT_PUBLIC_API_BASE_URL or defaults to http://localhost:8000/api/v1
 */

import type { Token } from "@/types";

const BASE_URL =
  typeof window !== "undefined"
    ? (process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:8000/api/v1")
    : process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:8000/api/v1";

let onUnauthorized: (() => void) | null = null;

export function setOnUnauthorized(fn: (() => void) | null) {
  onUnauthorized = fn;
}

async function getStoredToken(): Promise<string | null> {
  if (typeof window === "undefined") return null;
  return localStorage.getItem("access_token");
}

async function getStoredRefreshToken(): Promise<string | null> {
  if (typeof window === "undefined") return null;
  return localStorage.getItem("refresh_token");
}

export async function setStoredTokens(access: string, refresh: string) {
  if (typeof window === "undefined") return;
  localStorage.setItem("access_token", access);
  localStorage.setItem("refresh_token", refresh);
}

export async function clearStoredTokens() {
  if (typeof window === "undefined") return;
  localStorage.removeItem("access_token");
  localStorage.removeItem("refresh_token");
}

export async function refreshToken(): Promise<boolean> {
  const refresh = await getStoredRefreshToken();
  if (!refresh) return false;
  try {
    const res = await fetch(`${BASE_URL}/auth/refresh`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ refresh_token: refresh }),
    });
    if (!res.ok) return false;
    const data = (await res.json()) as Token;
    await setStoredTokens(data.access_token, data.refresh_token);
    return true;
  } catch {
    return false;
  }
}

export async function apiFetch<T>(
  path: string,
  options: RequestInit = {}
): Promise<T> {
  const url = path.startsWith("http") ? path : `${BASE_URL}${path}`;
  const token = await getStoredToken();
  const headers: HeadersInit = {
    "Content-Type": "application/json",
    Accept: "application/json",
    ...(options.headers as Record<string, string>),
  };
  if (token) (headers as Record<string, string>)["Authorization"] = `Bearer ${token}`;

  let res = await fetch(url, { ...options, headers });

  if (res.status === 401 && onUnauthorized) {
    const ok = await refreshToken();
    if (ok) {
      const newToken = await getStoredToken();
      if (newToken) (headers as Record<string, string>)["Authorization"] = `Bearer ${newToken}`;
      res = await fetch(url, { ...options, headers });
    }
    if (res.status === 401) {
      clearStoredTokens();
      onUnauthorized();
      throw new Error("Unauthorized");
    }
  }

  if (!res.ok) {
    const text = await res.text();
    throw new Error(text || `HTTP ${res.status}`);
  }

  const contentType = res.headers.get("content-type");
  if (contentType?.includes("application/json")) return res.json() as Promise<T>;
  return res.text() as Promise<T>;
}

export { BASE_URL };
