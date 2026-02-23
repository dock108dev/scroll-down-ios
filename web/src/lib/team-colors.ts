/**
 * Team colour cache system.
 *
 * Fetches from /api/teams on first access, stores in a module-level cache,
 * and exposes helpers for single-team and matchup colour lookups.
 *
 * This is the **non-React** counterpart of `useTeamColors`.
 * Use it in server components, utility functions, or anywhere hooks are unavailable.
 */

import type { TeamSummary } from "./types";
import { colorDistance, matchupColor as resolveMatchup } from "./theme";

// ── Module-level cache ──────────────────────────────────────────────

let cachedTeams: TeamSummary[] | null = null;
let fetchPromise: Promise<TeamSummary[]> | null = null;

/**
 * Fetch and cache the full team list.
 * Subsequent calls return the same promise / cached array.
 */
async function ensureTeams(): Promise<TeamSummary[]> {
  if (cachedTeams) return cachedTeams;

  if (!fetchPromise) {
    fetchPromise = fetch("/api/teams")
      .then((res) => {
        if (!res.ok) throw new Error(`Team fetch failed: ${res.status}`);
        return res.json() as Promise<TeamSummary[]>;
      })
      .then((teams) => {
        cachedTeams = teams;
        return teams;
      })
      .catch(() => {
        // Team colours are cosmetic — fail silently
        fetchPromise = null; // allow retry next call
        return [] as TeamSummary[];
      });
  }

  return fetchPromise;
}

// ── Prefix matching ─────────────────────────────────────────────────

/**
 * Find a team by name using case-insensitive prefix matching.
 * Exact match is preferred; if none, the first prefix match wins.
 */
function findTeam(
  teams: TeamSummary[],
  name: string,
): TeamSummary | undefined {
  const lower = name.toLowerCase();

  // 1. Exact match
  const exact = teams.find((t) => t.name.toLowerCase() === lower);
  if (exact) return exact;

  // 2. Prefix match (e.g. "Los Angeles" matches "Los Angeles Lakers")
  return teams.find((t) => t.name.toLowerCase().startsWith(lower));
}

// ── Public API ──────────────────────────────────────────────────────

export type ColorMode = "light" | "dark";

/**
 * Get a single team's hex colour string.
 * Returns `undefined` when the team is not found or the colour is not set.
 */
export async function getTeamColor(
  teamName: string,
  mode: ColorMode = "dark",
): Promise<string | undefined> {
  const teams = await ensureTeams();
  const team = findTeam(teams, teamName);
  if (!team) return undefined;
  return mode === "light" ? team.colorLightHex : team.colorDarkHex;
}

/**
 * Synchronous version — only returns a result if the cache is already populated.
 * Useful inside React render paths where you cannot await.
 */
export function getTeamColorSync(
  teamName: string,
  mode: ColorMode = "dark",
): string | undefined {
  if (!cachedTeams) return undefined;
  const team = findTeam(cachedTeams, teamName);
  if (!team) return undefined;
  return mode === "light" ? team.colorLightHex : team.colorDarkHex;
}

/** Default fallback colour (system indigo equivalent) */
const DEFAULT_COLOR = "#5856d6";

export interface MatchupColors {
  home: string;
  away: string;
}

/**
 * Get matchup-safe colours for a home/away pair.
 *
 * Applies clash detection (Euclidean distance in RGB, threshold 0.12).
 * When the two team colours are too similar the **home** team yields to
 * a neutral fallback (white).
 */
export async function getMatchupColors(
  homeTeam: string,
  awayTeam: string,
  mode: ColorMode = "dark",
): Promise<MatchupColors> {
  const teams = await ensureTeams();
  const homeEntry = findTeam(teams, homeTeam);
  const awayEntry = findTeam(teams, awayTeam);

  const homeHex =
    (mode === "light" ? homeEntry?.colorLightHex : homeEntry?.colorDarkHex) ??
    DEFAULT_COLOR;
  const awayHex =
    (mode === "light" ? awayEntry?.colorLightHex : awayEntry?.colorDarkHex) ??
    DEFAULT_COLOR;

  return {
    home: resolveMatchup(homeHex, awayHex, true),
    away: resolveMatchup(awayHex, homeHex, false),
  };
}

/**
 * Synchronous matchup colours — requires cache to be warm.
 */
export function getMatchupColorsSync(
  homeTeam: string,
  awayTeam: string,
  mode: ColorMode = "dark",
): MatchupColors {
  const homeHex = getTeamColorSync(homeTeam, mode) ?? DEFAULT_COLOR;
  const awayHex = getTeamColorSync(awayTeam, mode) ?? DEFAULT_COLOR;

  return {
    home: resolveMatchup(homeHex, awayHex, true),
    away: resolveMatchup(awayHex, homeHex, false),
  };
}

/**
 * Pre-warm the cache. Call from a top-level layout effect so colours are
 * available synchronously for the rest of the session.
 */
export function prefetchTeamColors(): void {
  ensureTeams();
}

/**
 * Re-export the distance function for ad-hoc use.
 */
export { colorDistance };
