"use client";

import { useCallback, useEffect, useState } from "react";
import { api } from "@/lib/api";
import type { GameDetailResponse } from "@/lib/types";

export function useGame(id: number) {
  const [data, setData] = useState<GameDetailResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchGame = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const result = await api.game(id);
      setData(result);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to fetch game");
    } finally {
      setLoading(false);
    }
  }, [id]);

  useEffect(() => {
    fetchGame();
  }, [fetchGame]);

  return { data, loading, error, refetch: fetchGame };
}
