"use client";

import { useState } from "react";
import type { APIBet } from "@/lib/types";
import { cn, formatOdds } from "@/lib/utils";
import { useSettings } from "@/stores/settings";
import { FairBetTheme, bookAbbreviation } from "@/lib/theme";
import {
  formatEV,
  formatProbability,
  getMethodDisplayName,
  getMethodExplanation,
  getConfidenceLabel,
  getConfidenceColor,
  getEVColor,
  selectionDisplay,
  americanToImpliedProb,
  profitPerDollar,
  fairAmericanOdds,
  impliedProbToAmerican,
} from "@/lib/fairbet-utils";

interface FairExplainerSheetProps {
  open: boolean;
  onClose: () => void;
  bet: APIBet | null;
}

export function FairExplainerSheet({
  open,
  onClose,
  bet,
}: FairExplainerSheetProps) {
  const oddsFormat = useSettings((s) => s.oddsFormat);
  const [showImpliedProbs, setShowImpliedProbs] = useState(false);

  if (!open || !bet) return null;

  const method = bet.ev_method;
  const bestBook = bet.books.reduce(
    (best, b) => ((b.ev_percent ?? -999) > (best.ev_percent ?? -999) ? b : best),
    bet.books[0],
  );
  const fairProb = bet.true_prob ?? 0;
  // Fair price is computed from true_prob (the devigged probability), NOT reference_price
  // reference_price is the sharp book's raw line (before devig)
  const fairOdds = fairAmericanOdds(bet);
  const sharpRefPrice = bet.reference_price; // Sharp book's raw line
  const bestEV = bestBook?.ev_percent ?? 0;

  // Steps differ by method
  const steps = buildSteps(method, bet, bestBook, fairProb, fairOdds, sharpRefPrice, oddsFormat);

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center md:items-center">
      <div className="absolute inset-0 bg-black/60" onClick={onClose} />
      <div
        className="relative z-10 w-full max-w-lg max-h-[85vh] overflow-y-auto rounded-t-2xl md:rounded-2xl p-5 space-y-5"
        style={{
          backgroundColor: FairBetTheme.cardBackground,
          border: `1px solid ${FairBetTheme.borderSubtle}`,
        }}
      >
        {/* Header */}
        <div className="flex items-center justify-between">
          <h2 className="text-base font-semibold text-white">Fair Value Breakdown</h2>
          <button
            onClick={onClose}
            className="text-neutral-500 hover:text-white text-sm px-2 py-1"
          >
            Close
          </button>
        </div>

        {/* Summary card */}
        <div
          className="rounded-xl p-3.5 space-y-2"
          style={{
            backgroundColor: FairBetTheme.surfaceTint,
            border: `1px solid ${FairBetTheme.borderSubtle}`,
          }}
        >
          <div className="text-sm font-semibold text-white">{selectionDisplay(bet)}</div>
          <div className="text-xs" style={{ color: "rgba(255,255,255,0.5)" }}>
            {bet.away_team} @ {bet.home_team}
          </div>

          <div className="grid grid-cols-2 gap-3 pt-2">
            <StatBlock
              label="Estimated Fair Price"
              value={fairOdds != null ? formatOdds(fairOdds, oddsFormat) : "N/A"}
              large
            />
            {sharpRefPrice != null && (
              <StatBlock
                label="Sharp Reference"
                value={formatOdds(sharpRefPrice, oddsFormat)}
              />
            )}
          </div>
          <div className="text-center text-xs pt-1" style={{ color: "rgba(255,255,255,0.4)" }}>
            Implied probability: {fairProb > 0 ? formatProbability(fairProb) : "N/A"}
          </div>
        </div>

        {/* Method */}
        <div className="space-y-2">
          <h3 className="text-xs font-semibold uppercase tracking-wider" style={{ color: "rgba(255,255,255,0.4)" }}>
            How it was calculated
          </h3>
          <div
            className="rounded-lg px-3 py-2 text-xs font-medium"
            style={{
              backgroundColor: FairBetTheme.surfaceSecondary,
              color: FairBetTheme.info,
            }}
          >
            {getMethodDisplayName(method)}
          </div>
        </div>

        {/* Step by step math */}
        <div className="space-y-2">
          <h3 className="text-xs font-semibold uppercase tracking-wider" style={{ color: "rgba(255,255,255,0.4)" }}>
            Step-by-step
          </h3>
          <div className="space-y-2">
            {steps.map((step, i) => (
              <div
                key={i}
                className="rounded-lg px-3 py-2.5 space-y-1"
                style={{
                  backgroundColor: FairBetTheme.surfaceTint,
                  border: `1px solid ${FairBetTheme.cardBorder}`,
                }}
              >
                <div className="flex items-center gap-2">
                  <span
                    className="shrink-0 w-5 h-5 rounded-full text-[10px] font-bold flex items-center justify-center"
                    style={{ backgroundColor: FairBetTheme.surfaceSecondary, color: "rgba(255,255,255,0.6)" }}
                  >
                    {i + 1}
                  </span>
                  <span className="text-xs font-semibold text-white">{step.title}</span>
                </div>
                <div className="text-xs ml-7" style={{ color: "rgba(255,255,255,0.6)" }}>
                  {step.detail}
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Per-book implied probabilities */}
        <div className="space-y-2">
          <button
            onClick={() => setShowImpliedProbs((p) => !p)}
            className="flex items-center gap-1 text-xs font-semibold uppercase tracking-wider"
            style={{ color: "rgba(255,255,255,0.4)" }}
          >
            <svg
              className={cn("w-3 h-3 transition-transform", showImpliedProbs && "rotate-90")}
              fill="none"
              stroke="currentColor"
              strokeWidth={2}
              viewBox="0 0 24 24"
            >
              <path d="M9 5l7 7-7 7" />
            </svg>
            Per-book implied probabilities
          </button>
          {showImpliedProbs && (
            <div className="space-y-1">
              {bet.books.map((bp) => {
                const ip = bp.implied_prob ?? americanToImpliedProb(bp.price);
                return (
                  <div
                    key={bp.book}
                    className="flex items-center justify-between rounded px-3 py-1.5 text-xs"
                    style={{ backgroundColor: FairBetTheme.surfaceTint }}
                  >
                    <span className="flex items-center gap-2">
                      <span className="font-medium text-white">
                        {bookAbbreviation(bp.book)}
                      </span>
                      {bp.is_sharp && (
                        <span style={{ color: FairBetTheme.info }} className="text-[10px]">
                          ★
                        </span>
                      )}
                    </span>
                    <span className="flex items-center gap-3">
                      <span className="text-white font-mono">{formatOdds(bp.price, oddsFormat)}</span>
                      <span style={{ color: "rgba(255,255,255,0.5)" }}>
                        {formatProbability(ip)}
                      </span>
                    </span>
                  </div>
                );
              })}
            </div>
          )}
        </div>

        {/* What is this? */}
        <div className="space-y-2">
          <h3 className="text-xs font-semibold uppercase tracking-wider" style={{ color: "rgba(255,255,255,0.4)" }}>
            What is this?
          </h3>
          <p className="text-xs leading-relaxed" style={{ color: "rgba(255,255,255,0.6)" }}>
            {getMethodExplanation(method)}
          </p>
        </div>

        {/* Estimate quality */}
        <div className="space-y-2">
          <h3 className="text-xs font-semibold uppercase tracking-wider" style={{ color: "rgba(255,255,255,0.4)" }}>
            Estimate Quality
          </h3>
          <div
            className="flex items-center gap-2 rounded-lg px-3 py-2"
            style={{
              backgroundColor: FairBetTheme.surfaceTint,
              border: `1px solid ${FairBetTheme.cardBorder}`,
            }}
          >
            <span
              className="w-2 h-2 rounded-full shrink-0"
              style={{ backgroundColor: getConfidenceColor(bet.ev_confidence_tier) }}
            />
            <span className="text-xs font-semibold text-white">
              {getConfidenceLabel(bet.ev_confidence_tier)}
            </span>
            <span className="text-xs" style={{ color: "rgba(255,255,255,0.5)" }}>
              {bet.ev_confidence_tier === "sharp"
                ? "Based on sharp sportsbook lines - high reliability"
                : bet.ev_confidence_tier === "market"
                  ? "Based on market consensus - moderate reliability"
                  : "Limited data available - lower confidence"}
            </span>
          </div>
        </div>

        {/* Data sources */}
        <div className="space-y-1">
          <h3 className="text-xs font-semibold uppercase tracking-wider" style={{ color: "rgba(255,255,255,0.4)" }}>
            Data Sources
          </h3>
          <p className="text-xs" style={{ color: "rgba(255,255,255,0.5)" }}>
            {bet.books.length} sportsbooks compared
            {bet.books.some((b) => b.is_sharp) && (
              <span>
                {" "}
                &middot; Sharp books marked with{" "}
                <span style={{ color: FairBetTheme.info }}>★</span>
              </span>
            )}
          </p>
        </div>

        {/* Disclaimer */}
        <p
          className="text-[10px] leading-relaxed"
          style={{ color: "rgba(255,255,255,0.3)" }}
        >
          This analysis is for informational purposes only and does not constitute
          financial or gambling advice. Past performance does not guarantee future
          results. Always gamble responsibly.
        </p>
      </div>
    </div>
  );
}

// ── Sub-components ─────────────────────────────────────────────────

function StatBlock({
  label,
  value,
  color,
  large,
}: {
  label: string;
  value: string;
  color?: string;
  large?: boolean;
}) {
  return (
    <div className="text-center space-y-0.5">
      <div className="text-[10px]" style={{ color: "rgba(255,255,255,0.4)" }}>
        {label}
      </div>
      <div
        className={cn("font-bold", large ? "text-2xl" : "text-sm")}
        style={{ color: color ?? "white" }}
      >
        {value}
      </div>
    </div>
  );
}

// ── Step builder ───────────────────────────────────────────────────

interface Step {
  title: string;
  detail: string;
}

function buildSteps(
  method: string | undefined,
  bet: APIBet,
  bestBook: APIBet["books"][0] | undefined,
  fairProb: number,
  fairOdds: number | null,
  sharpRefPrice: number | undefined,
  oddsFormat: "american" | "decimal" | "fractional",
): Step[] {
  const bestPrice = bestBook?.price;
  const bestEV = bestBook?.ev_percent ?? 0;
  const profit = bestPrice != null ? profitPerDollar(bestPrice) : 0;

  // Build EV step (shared across methods) - uses ALL server-provided values
  const evStep: Step = {
    title: "Calculate EV at best price",
    detail: bestPrice != null
      ? [
          `Best price: ${formatOdds(bestPrice, oddsFormat)} (${bookAbbreviation(bestBook?.book ?? "")})`,
          `If this hits (${formatProbability(fairProb)} chance): win $${profit.toFixed(2)}`,
          `If this misses (${formatProbability(1 - fairProb)} chance): lose $1.00`,
          `EV = (${fairProb.toFixed(2)} × $${profit.toFixed(2)}) − (${(1 - fairProb).toFixed(2)} × $1.00)`,
          `   = $${(fairProb * profit).toFixed(2)} − $${((1 - fairProb) * 1).toFixed(2)}`,
          `   = +$${(fairProb * profit - (1 - fairProb)).toFixed(2)} per dollar (${formatEV(bestEV)})`,
        ].join("\n")
      : "Expected value based on fair probability vs. offered odds",
  };

  if (method === "pinnacle_shin" || method === "pinnacle_extrapolated" || method === "sharp_reference") {
    // Compute display values from server data
    const thisProb = sharpRefPrice != null ? americanToImpliedProb(sharpRefPrice) : 0;
    const otherProb = bet.opposite_reference_price != null ? americanToImpliedProb(bet.opposite_reference_price) : 0;
    const totalImplied = thisProb + otherProb;
    const vig = totalImplied - 1;

    const steps: Step[] = [
      {
        title: "Convert odds to implied probability",
        detail: sharpRefPrice != null && bet.opposite_reference_price != null
          ? [
              `This side:  ${formatOdds(sharpRefPrice, oddsFormat)}  →  ${formatProbability(thisProb)}`,
              `Other side: ${formatOdds(bet.opposite_reference_price, oddsFormat)}  →  ${formatProbability(otherProb)}`,
              `Total: ${formatProbability(totalImplied)}`,
            ].join("\n")
          : sharpRefPrice != null
            ? `Sharp reference price ${formatOdds(sharpRefPrice, oddsFormat)} implies ~${formatProbability(thisProb)} probability`
            : "Convert the sharp line to an implied probability",
      },
      {
        title: "Identify the vig",
        detail: [
          `Total implied: ${formatProbability(totalImplied)}`,
          `Should be: 100.0%`,
          `Vig (margin): ${formatProbability(vig)}`,
        ].join("\n"),
      },
      {
        title: method === "pinnacle_shin" || method === "pinnacle_extrapolated"
          ? "Remove the vig (Shin's method)"
          : "Remove vig from sharp line",
        detail: [
          ...(method === "pinnacle_shin" || method === "pinnacle_extrapolated"
            ? [
                `z = 1 − (1 / total): ${(1 - 1 / totalImplied).toFixed(2) + "%"}`,
                `q (this side): ${formatProbability(thisProb)}`,
                `p = (√(z² + 4(1−z)q²) − z) / (2(1−z))`,
              ]
            : []),
          `Fair probability: ${formatProbability(fairProb)}`,
          `Fair odds: ${fairOdds != null ? formatOdds(fairOdds, oddsFormat) : "N/A"}`,
          ...(method === "pinnacle_shin" || method === "pinnacle_extrapolated"
            ? ["Shin's method shifts more vig onto longshots." + (method === "pinnacle_extrapolated" ? "\nExtrapolated from nearby Pinnacle lines." : "")]
            : []),
        ].join("\n"),
      },
      evStep,
    ];
    return steps;
  }

  if (method === "median_consensus") {
    return [
      {
        title: "Calculate median probability",
        detail: `Median implied probability across ${bet.books.length} books = ${formatProbability(fairProb)}`,
      },
      evStep,
    ];
  }

  if (method === "paired_vig_removal") {
    const thisProb = sharpRefPrice != null ? americanToImpliedProb(sharpRefPrice) : 0;
    const otherProb = bet.opposite_reference_price != null ? americanToImpliedProb(bet.opposite_reference_price) : 0;
    const totalImplied = thisProb + otherProb;

    return [
      {
        title: "Convert to implied probabilities",
        detail: sharpRefPrice != null
          ? `Reference price ${formatOdds(sharpRefPrice, oddsFormat)} implies ~${formatProbability(thisProb)}`
          : "Convert both sides to implied probabilities",
      },
      {
        title: "Identify the vig",
        detail: `Sum of implied probabilities: ${formatProbability(totalImplied)} (over 100% = vig)`,
      },
      {
        title: "Remove vig (equal division)",
        detail: `Split the overround equally.\nFair probability = ${formatProbability(fairProb)}\nFair odds: ${fairOdds != null ? formatOdds(fairOdds, oddsFormat) : "N/A"}`,
      },
      evStep,
    ];
  }

  // Default / unknown
  return [
    {
      title: "Estimate fair probability",
      detail: `Fair probability estimated at ${formatProbability(fairProb)}`,
    },
    evStep,
  ];
}
