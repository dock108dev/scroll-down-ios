"use client";

import { useCallback, useEffect, useState } from "react";
import { api } from "@/lib/api";
import type { GameSummary } from "@/lib/types";

interface UseGamesOptions {
  league?: string;
  range?: string;
  search?: string;
}

export function useGames(options: UseGamesOptions = {}) {
  const [games, setGames] = useState<GameSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchGames = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const params = new URLSearchParams();
      if (options.league) params.set("league", options.league);
      if (options.range) params.set("range", options.range);
      if (options.search) params.set("search", options.search);
      const data = await api.games(params);
      setGames(data.games);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to fetch games");
    } finally {
      setLoading(false);
    }
  }, [options.league, options.range, options.search]);

  useEffect(() => {
    fetchGames();
  }, [fetchGames]);

  return { games, loading, error, refetch: fetchGames };
}
