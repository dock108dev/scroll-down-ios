"use client";

import { useCallback, useEffect, useState } from "react";
import { api } from "@/lib/api";
import type { BetsResponse } from "@/lib/types";

interface UseFairBetOddsOptions {
  league?: string;
  book?: string;
  category?: string;
  game_id?: number;
}

export function useFairBetOdds(options: UseFairBetOddsOptions = {}) {
  const [data, setData] = useState<BetsResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchOdds = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const params = new URLSearchParams();
      if (options.league) params.set("league", options.league);
      if (options.book) params.set("book", options.book);
      if (options.category) params.set("category", options.category);
      if (options.game_id) params.set("game_id", String(options.game_id));
      const result = await api.fairbetOdds(params);
      setData(result);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to fetch odds");
    } finally {
      setLoading(false);
    }
  }, [options.league, options.book, options.category, options.game_id]);

  useEffect(() => {
    fetchOdds();
  }, [fetchOdds]);

  return { data, loading, error, refetch: fetchOdds };
}
