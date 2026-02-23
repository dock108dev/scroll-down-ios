"use client";

import type { GameDetailResponse, OddsEntry } from "@/lib/types";
import { useSettings } from "@/stores/settings";
import { formatOdds, cn } from "@/lib/utils";

interface WrapUpSectionProps {
  data: GameDetailResponse;
}

/** Known metric keys with special rendering */
const OUTCOME_KEYS = [
  "winner",
  "finalScore",
  "margin",
  "spreadResult",
  "totalResult",
  "moneylineResult",
] as const;

const OUTCOME_LABELS: Record<string, string> = {
  winner: "Winner",
  finalScore: "Final Score",
  margin: "Margin",
  spreadResult: "Spread Result",
  totalResult: "Total Result",
  moneylineResult: "Moneyline Result",
};

/** Group remaining metrics into logical sections */
function groupMetrics(
  metrics: Record<string, unknown>,
): { outcomes: [string, unknown][]; other: [string, unknown][] } {
  const outcomeSet = new Set<string>(OUTCOME_KEYS);
  const outcomes: [string, unknown][] = [];
  const other: [string, unknown][] = [];

  // Add outcome keys in preferred order
  for (const key of OUTCOME_KEYS) {
    if (key in metrics) {
      outcomes.push([key, metrics[key]]);
    }
  }

  // Add remaining keys
  for (const [key, value] of Object.entries(metrics)) {
    if (!outcomeSet.has(key)) {
      other.push([key, value]);
    }
  }

  return { outcomes, other };
}

/** Find opening and closing lines for comparison */
function getLineComparison(odds: OddsEntry[]): {
  opening: OddsEntry[];
  closing: OddsEntry[];
} {
  const closing = odds.filter((o) => o.isClosingLine);
  const opening = odds.filter((o) => !o.isClosingLine);
  return { opening, closing };
}

/** Get the best price from a set of odds entries for a given market */
function getBestForMarket(
  entries: OddsEntry[],
  marketType: string,
  side?: string,
): OddsEntry | undefined {
  return entries
    .filter(
      (e) =>
        e.marketType === marketType &&
        (side === undefined || e.side === side),
    )
    .sort((a, b) => (b.price ?? -Infinity) - (a.price ?? -Infinity))[0];
}

export function WrapUpSection({ data }: WrapUpSectionProps) {
  const metrics = data.derivedMetrics;
  const odds = data.odds;
  const oddsFormat = useSettings((s) => s.oddsFormat);

  if (
    (!metrics || Object.keys(metrics).length === 0) &&
    odds.length === 0
  ) {
    return (
      <div className="px-4 py-4 text-sm text-neutral-500">
        No wrap-up data available
      </div>
    );
  }

  const { outcomes, other } = metrics
    ? groupMetrics(metrics)
    : { outcomes: [], other: [] };

  const { opening, closing } = getLineComparison(odds);

  // Build line comparison data for mainline markets
  const lineComparisons: {
    label: string;
    openPrice: number | undefined;
    closePrice: number | undefined;
  }[] = [];

  for (const mt of ["spread", "moneyline", "total"] as const) {
    for (const side of ["home", "away", "over", "under"]) {
      const openEntry = getBestForMarket(opening, mt, side);
      const closeEntry = getBestForMarket(closing, mt, side);
      if (openEntry?.price != null || closeEntry?.price != null) {
        const sideLabel = side.charAt(0).toUpperCase() + side.slice(1);
        const mtLabel = mt.charAt(0).toUpperCase() + mt.slice(1);
        const lineStr =
          (closeEntry ?? openEntry)?.line != null
            ? ` ${(closeEntry ?? openEntry)!.line! > 0 ? "+" : ""}${(closeEntry ?? openEntry)!.line}`
            : "";
        lineComparisons.push({
          label: `${sideLabel} ${mtLabel}${lineStr}`,
          openPrice: openEntry?.price ?? undefined,
          closePrice: closeEntry?.price ?? undefined,
        });
      }
    }
  }

  return (
    <div className="px-4 space-y-4">
      {/* Outcomes */}
      {outcomes.length > 0 && (
        <div className="rounded-lg border border-neutral-800 bg-neutral-900 p-4">
          <h3 className="text-xs font-semibold text-neutral-500 uppercase tracking-wide mb-3">
            Outcomes
          </h3>
          <div className="space-y-3">
            {outcomes.map(([key, value]) => (
              <OutcomeRow
                key={key}
                label={OUTCOME_LABELS[key] ?? key.replace(/_/g, " ")}
                value={value}
                metricKey={key}
              />
            ))}
          </div>
        </div>
      )}

      {/* Opening vs Closing Lines */}
      {lineComparisons.length > 0 && (
        <div className="rounded-lg border border-neutral-800 bg-neutral-900 p-4">
          <h3 className="text-xs font-semibold text-neutral-500 uppercase tracking-wide mb-3">
            Opening vs Closing Lines
          </h3>
          <div className="space-y-1">
            <div className="flex items-center text-[10px] text-neutral-500 font-medium mb-2">
              <span className="flex-1">Market</span>
              <span className="w-20 text-center">Open</span>
              <span className="w-20 text-center">Close</span>
              <span className="w-16 text-center">Move</span>
            </div>
            {lineComparisons.map((comp, i) => {
              const diff =
                comp.openPrice != null && comp.closePrice != null
                  ? comp.closePrice - comp.openPrice
                  : null;
              return (
                <div
                  key={i}
                  className="flex items-center py-1.5 text-sm border-t border-neutral-800/30"
                >
                  <span className="flex-1 text-neutral-300 text-xs truncate pr-2">
                    {comp.label}
                  </span>
                  <span className="w-20 text-center font-mono text-xs text-neutral-400">
                    {comp.openPrice != null
                      ? formatOdds(comp.openPrice, oddsFormat)
                      : "\u2014"}
                  </span>
                  <span className="w-20 text-center font-mono text-xs text-neutral-200">
                    {comp.closePrice != null
                      ? formatOdds(comp.closePrice, oddsFormat)
                      : "\u2014"}
                  </span>
                  <span
                    className={cn(
                      "w-16 text-center font-mono text-xs",
                      diff != null && diff > 0
                        ? "text-green-400"
                        : diff != null && diff < 0
                          ? "text-red-400"
                          : "text-neutral-500",
                    )}
                  >
                    {diff != null
                      ? `${diff > 0 ? "+" : ""}${diff}`
                      : "\u2014"}
                  </span>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Other Metrics */}
      {other.length > 0 && (
        <div className="rounded-lg border border-neutral-800 bg-neutral-900 p-4">
          <h3 className="text-xs font-semibold text-neutral-500 uppercase tracking-wide mb-3">
            Key Metrics
          </h3>
          <div className="grid grid-cols-2 gap-3">
            {other.map(([key, value]) => (
              <div key={key}>
                <div className="text-xs text-neutral-500 capitalize mb-0.5">
                  {key.replace(/_/g, " ")}
                </div>
                <div className="text-sm text-neutral-200">
                  {typeof value === "string"
                    ? value
                    : typeof value === "number"
                      ? String(value)
                      : JSON.stringify(value)}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

function OutcomeRow({
  label,
  value,
  metricKey,
}: {
  label: string;
  value: unknown;
  metricKey: string;
}) {
  const displayValue =
    typeof value === "string"
      ? value
      : typeof value === "number"
        ? String(value)
        : JSON.stringify(value);

  // Special styling for known keys
  const isResult =
    metricKey === "spreadResult" ||
    metricKey === "totalResult" ||
    metricKey === "moneylineResult";

  const resultColor =
    isResult && typeof value === "string"
      ? value.toLowerCase().includes("cover") ||
        value.toLowerCase().includes("hit") ||
        value.toLowerCase().includes("win") ||
        value.toLowerCase().includes("over")
        ? "text-green-400"
        : value.toLowerCase().includes("push")
          ? "text-amber-400"
          : "text-red-400"
      : "text-neutral-200";

  return (
    <div className="flex items-center justify-between">
      <span className="text-xs text-neutral-500 capitalize">{label}</span>
      <span
        className={cn(
          "text-sm font-medium",
          metricKey === "winner"
            ? "text-neutral-100"
            : metricKey === "finalScore"
              ? "text-neutral-100 font-mono"
              : isResult
                ? resultColor
                : "text-neutral-200",
        )}
      >
        {displayValue}
      </span>
    </div>
  );
}
