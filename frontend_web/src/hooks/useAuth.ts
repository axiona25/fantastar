"use client";

import { useAuthStore } from "@/store/authStore";
import { useEffect } from "react";

/**
 * Auth state and actions; optionally sync user from API on mount when tokens exist.
 */
export function useAuth(syncOnMount = false) {
  const store = useAuthStore();

  useEffect(() => {
    if (!syncOnMount || typeof window === "undefined") return;
    const token = localStorage.getItem("access_token");
    if (token && !store.user) store.fetchMe();
  }, [syncOnMount, store.user, store.fetchMe]);

  return store;
}
