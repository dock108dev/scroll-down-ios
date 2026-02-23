"use client";

import { useState } from "react";
import type { PlayEntry, ServerTieredPlayGroup } from "@/lib/types";
import { TimelineRow } from "./TimelineRow";
import { CollapsedPlayGroup } from "./CollapsedPlayGroup";
import { cn } from "@/lib/utils";

// ─── Types ──────────────────────────────────────────────────

interface TimelineSectionProps {
  plays: PlayEntry[];
  homeTeamAbbr?: string;
  awayTeamAbbr?: string;
  homeColor?: string;
  awayColor?: string;
  groupedPlays?: ServerTieredPlayGroup[];
}

/** A renderable item inside a period: either a single play or a collapsed group. */
type PeriodItem =
  | { kind: "play"; play: PlayEntry; previousPlay?: PlayEntry }
  | { kind: "group"; plays: PlayEntry[]; summaryLabel?: string };

// ─── Helpers ────────────────────────────────────────────────

/**
 * Groups plays by periodLabel. Maintains insertion order.
 */
function groupByPeriod(plays: PlayEntry[]): Map<string, PlayEntry[]> {
  const map = new Map<string, PlayEntry[]>();
  for (const play of plays) {
    const key = play.periodLabel ?? `Period ${play.quarter ?? "?"}`;
    const arr = map.get(key);
    if (arr) {
      arr.push(play);
    } else {
      map.set(key, [play]);
    }
  }
  return map;
}

/**
 * Builds a lookup from playIndex to its server-provided group.
 */
function buildGroupLookup(
  groups: ServerTieredPlayGroup[] | undefined,
): Map<number, ServerTieredPlayGroup> {
  const lookup = new Map<number, ServerTieredPlayGroup>();
  if (!groups) return lookup;
  for (const g of groups) {
    for (const idx of g.playIndices) {
      lookup.set(idx, g);
    }
  }
  return lookup;
}

/**
 * Converts an array of plays within a period into renderable items,
 * collapsing consecutive tier-3 plays into groups.
 *
 * When server-provided groupedPlays are available, those groupings and
 * summary labels are used. Otherwise, client-side grouping collapses
 * consecutive tier-3 plays.
 */
function buildPeriodItems(
  periodPlays: PlayEntry[],
  allPlays: PlayEntry[],
  groupLookup: Map<number, ServerTieredPlayGroup>,
): PeriodItem[] {
  const items: PeriodItem[] = [];
  const usedServerGroups = new Set<ServerTieredPlayGroup>();

  let i = 0;
  while (i < periodPlays.length) {
    const play = periodPlays[i];
    const tier = play.tier ?? 3;

    // Check for server-provided group
    const serverGroup = groupLookup.get(play.playIndex);
    if (serverGroup && !usedServerGroups.has(serverGroup)) {
      usedServerGroups.add(serverGroup);

      // Gather all plays belonging to this server group that are in this period
      const groupPlays: PlayEntry[] = [];
      const groupIndices = new Set(serverGroup.playIndices);
      let j = i;
      while (j < periodPlays.length && groupIndices.has(periodPlays[j].playIndex)) {
        groupPlays.push(periodPlays[j]);
        j++;
      }

      if (groupPlays.length > 0) {
        items.push({
          kind: "group",
          plays: groupPlays,
          summaryLabel: serverGroup.summaryLabel,
        });
        i = j;
        continue;
      }
    }

    // Client-side grouping: collapse consecutive tier-3 plays
    if (tier === 3) {
      const tier3Plays: PlayEntry[] = [play];
      let j = i + 1;
      while (j < periodPlays.length && (periodPlays[j].tier ?? 3) === 3) {
        // Don't absorb plays that belong to a different server group
        const nextServerGroup = groupLookup.get(periodPlays[j].playIndex);
        if (nextServerGroup && !usedServerGroups.has(nextServerGroup)) break;
        tier3Plays.push(periodPlays[j]);
        j++;
      }

      if (tier3Plays.length >= 2) {
        items.push({ kind: "group", plays: tier3Plays });
      } else {
        // Single tier-3 play: render inline
        const prevIdx = play.playIndex - 1;
        const prevPlay = allPlays.find((p) => p.playIndex === prevIdx);
        items.push({ kind: "play", play, previousPlay: prevPlay });
      }
      i = j;
      continue;
    }

    // Tier 1 or 2: render as individual play
    const prevIdx = play.playIndex - 1;
    const prevPlay = allPlays.find((p) => p.playIndex === prevIdx);
    items.push({ kind: "play", play, previousPlay: prevPlay });
    i++;
  }

  return items;
}

// ─── Period Card ────────────────────────────────────────────

interface PeriodCardProps {
  period: string;
  items: PeriodItem[];
  defaultOpen: boolean;
  homeTeamAbbr?: string;
  awayTeamAbbr?: string;
  homeColor?: string;
  awayColor?: string;
}

function PeriodCard({
  period,
  items,
  defaultOpen,
  homeTeamAbbr,
  awayTeamAbbr,
  homeColor,
  awayColor,
}: PeriodCardProps) {
  const [open, setOpen] = useState(defaultOpen);

  return (
    <div className="rounded-lg border border-neutral-800 bg-neutral-900 overflow-hidden">
      {/* Sticky period header */}
      <button
        onClick={() => setOpen(!open)}
        className={cn(
          "flex w-full items-center justify-between px-4 py-3",
          "text-sm font-semibold text-neutral-200",
          "hover:bg-neutral-800/50 transition",
          "sticky top-0 z-10 bg-neutral-900 border-b border-neutral-800/50",
        )}
      >
        <span>{period}</span>
        <span
          className={cn(
            "text-xs text-neutral-500 transition-transform duration-200",
            open && "rotate-180",
          )}
        >
          {"\u25BC"}
        </span>
      </button>

      {/* Collapsible content */}
      <div
        className={cn(
          "grid transition-[grid-template-rows] duration-200",
          open ? "grid-rows-[1fr]" : "grid-rows-[0fr]",
        )}
      >
        <div className="overflow-hidden">
          <div className="px-2 py-2 space-y-0.5">
            {items.map((item, idx) => {
              if (item.kind === "group") {
                return (
                  <CollapsedPlayGroup
                    key={`group-${item.plays[0].playIndex}`}
                    plays={item.plays}
                    summaryLabel={item.summaryLabel}
                    homeTeamAbbr={homeTeamAbbr}
                    awayTeamAbbr={awayTeamAbbr}
                    homeColor={homeColor}
                    awayColor={awayColor}
                  />
                );
              }
              return (
                <TimelineRow
                  key={item.play.playIndex}
                  play={item.play}
                  previousPlay={item.previousPlay}
                  homeTeamAbbr={homeTeamAbbr}
                  awayTeamAbbr={awayTeamAbbr}
                  homeColor={homeColor}
                  awayColor={awayColor}
                />
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
}

// ─── Main Component ─────────────────────────────────────────

export function TimelineSection({
  plays,
  homeTeamAbbr,
  awayTeamAbbr,
  homeColor,
  awayColor,
  groupedPlays,
}: TimelineSectionProps) {
  if (plays.length === 0) {
    return (
      <div className="px-4 py-4 text-sm text-neutral-500">
        No play-by-play data available
      </div>
    );
  }

  const periodMap = groupByPeriod(plays);
  const groupLookup = buildGroupLookup(groupedPlays);

  // Build renderable items for each period
  const periods = Array.from(periodMap.entries()).map(
    ([period, periodPlays]) => ({
      period,
      items: buildPeriodItems(periodPlays, plays, groupLookup),
    }),
  );

  return (
    <div className="px-4 space-y-2">
      {periods.map(({ period, items }) => (
        <PeriodCard
          key={period}
          period={period}
          items={items}
          defaultOpen={false}
          homeTeamAbbr={homeTeamAbbr}
          awayTeamAbbr={awayTeamAbbr}
          homeColor={homeColor}
          awayColor={awayColor}
        />
      ))}
    </div>
  );
}
