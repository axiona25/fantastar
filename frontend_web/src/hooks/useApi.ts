"use client";

import useSWR, { type SWRConfiguration, type KeyedMutator } from "swr";
import { apiFetch } from "@/services/apiClient";

/**
 * SWR-based data fetching with apiClient (auth + base URL).
 * key: path string or null to skip fetch.
 */
export function useApi<T>(path: string | null, config?: SWRConfiguration<T>) {
  const { data, error, mutate, isLoading, isValidating } = useSWR<T>(
    path,
    (url: string) => apiFetch<T>(url),
    config
  );
  return {
    data,
    error,
    mutate: mutate as KeyedMutator<T>,
    isLoading,
    isValidating,
    isError: !!error,
  };
}
