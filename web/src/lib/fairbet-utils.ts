/**
 * FairBet utility functions — client-side only.
 *
 * Functions that map to API-provided display fields have been removed.
 * Remaining: formatting, EV colour mapping, confidence checks, bet identity,
 * and market category mapping.
 */

import { FairBetTheme } from "./theme";
import type { APIBet } from "./types";

// ── Formatting ─────────────────────────────────────────────────────

/** Format EV percent with sign: "+5.2%" or "-2.1%" */
export function formatEV(percent: number): string {
  const sign = percent > 0 ? "+" : "";
  return `${sign}${percent.toFixed(1)}%`;
}

/** Format probability as percentage: "52.3%" */
export function formatProbability(prob: number): string {
  return `${(prob * 100).toFixed(1)}%`;
}

// ── Confidence ─────────────────────────────────────────────────────

export function getConfidenceColor(tier?: string): string {
  switch (tier) {
    case "full":
    case "sharp":
    case "high":
      return FairBetTheme.positive;
    case "decent":
    case "market":
    case "medium":
      return FairBetTheme.positiveMuted;
    case "thin":
    case "low":
      return FairBetTheme.neutral;
    default:
      return FairBetTheme.neutral;
  }
}

/** Check if a confidence tier qualifies as reliable (not thin/none). */
export function isConfidenceReliable(tier?: string): boolean {
  return tier === "full" || tier === "sharp" || tier === "high" ||
    tier === "decent" || tier === "market" || tier === "medium";
}

// ── EV colour tiers ────────────────────────────────────────────────

/** Get EV display colour by tier threshold. */
export function getEVColor(ev: number): string {
  if (ev >= 5) return FairBetTheme.positive;
  if (ev > 0) return FairBetTheme.positiveMuted;
  if (ev < 0) return FairBetTheme.negative;
  return FairBetTheme.neutral;
}

// ── Reliability ────────────────────────────────────────────────────

/** A bet is reliably positive EV when EV > 0 and confidence is not thin/none. */
export function isReliablyPositive(ev: number, confidence?: string): boolean {
  if (ev <= 0) return false;
  return isConfidenceReliable(confidence);
}

// ── Bet identity ───────────────────────────────────────────────────

/** Produce a unique ID string for a bet row. */
export function betId(bet: APIBet): string {
  return `${bet.game_id}::${bet.market_key}::${bet.selection_key}::${bet.line_value ?? ""}`;
}

// ── Market category mapping ────────────────────────────────────────

/** Map a market_key to a high-level market category for filtering. */
export function marketKeyToCategory(key: string): string {
  const lower = key.toLowerCase();
  if (lower === "h2h" || lower === "moneyline") return "moneyline";
  if (lower === "spreads" || lower === "spread" || lower === "alternate_spread") return "spread";
  if (lower === "totals" || lower === "total" || lower === "alternate_total") return "total";
  if (lower.startsWith("player_")) return "player_props";
  if (lower === "team_total") return "team_props";
  return "other";
}
