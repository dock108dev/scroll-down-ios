"use client";

import { useEffect, useState } from "react";
import { api } from "@/lib/api";
import type { TeamSummary } from "@/lib/types";

let cachedTeams: TeamSummary[] | null = null;

export function useTeamColors() {
  const [teams, setTeams] = useState<TeamSummary[]>(cachedTeams ?? []);
  const [loading, setLoading] = useState(!cachedTeams);

  useEffect(() => {
    if (cachedTeams) return;

    api
      .teams()
      .then((data) => {
        cachedTeams = data;
        setTeams(data);
      })
      .catch(() => {
        // Silently fail — team colors are cosmetic
      })
      .finally(() => setLoading(false));
  }, []);

  const getColor = (teamName: string, mode: "light" | "dark" = "dark") => {
    const team = teams.find(
      (t) => t.name.toLowerCase() === teamName.toLowerCase(),
    );
    return mode === "light" ? team?.colorLightHex : team?.colorDarkHex;
  };

  return { teams, loading, getColor };
}
