/**
 * Auth state (Zustand): user, tokens, login, logout, hydrate from storage.
 */

import { create } from "zustand";
import { persist } from "zustand/middleware";
import type { User, Token } from "@/types";
import { apiFetch, setStoredTokens, clearStoredTokens } from "@/services/apiClient";

interface AuthState {
  user: User | null;
  isLoading: boolean;
  error: string | null;
  login: (email: string, password: string) => Promise<void>;
  register: (email: string, username: string, password: string) => Promise<void>;
  logout: () => void;
  fetchMe: () => Promise<void>;
  clearError: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      user: null,
      isLoading: false,
      error: null,

      login: async (email: string, password: string) => {
        set({ isLoading: true, error: null });
        try {
          const data = await apiFetch<Token>("/auth/login", {
            method: "POST",
            body: JSON.stringify({ email, password }),
          });
          await setStoredTokens(data.access_token, data.refresh_token);
          await get().fetchMe();
          set({ error: null });
        } catch (e) {
          set({ error: e instanceof Error ? e.message : "Login failed", user: null });
          throw e;
        } finally {
          set({ isLoading: false });
        }
      },

      register: async (email: string, username: string, password: string) => {
        set({ isLoading: true, error: null });
        try {
          await apiFetch("/auth/register", {
            method: "POST",
            body: JSON.stringify({ email, username, password }),
          });
          await get().login(email, password);
        } catch (e) {
          set({ error: e instanceof Error ? e.message : "Registration failed" });
          throw e;
        } finally {
          set({ isLoading: false });
        }
      },

      logout: () => {
        clearStoredTokens();
        set({ user: null, error: null });
      },

      fetchMe: async () => {
        try {
          const user = await apiFetch<User>("/auth/me");
          set({ user });
        } catch {
          set({ user: null });
        }
      },

      clearError: () => set({ error: null }),
    }),
    { name: "fantastar-auth", partialize: (s) => ({ user: s.user }) }
  )
);
