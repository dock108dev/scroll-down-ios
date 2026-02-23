import type { OddsEntry } from "@/lib/types";
import { useSettings } from "@/stores/settings";
import { formatOdds } from "@/lib/utils";
import { BOOK_ABBREVIATIONS } from "@/lib/constants";

interface OddsTableProps {
  odds: OddsEntry[];
}

export function OddsTable({ odds }: OddsTableProps) {
  const oddsFormat = useSettings((s) => s.oddsFormat);
  const books = Array.from(new Set(odds.map((o) => o.book)));

  // Group odds by marketType + side + line
  const rows: Record<string, OddsEntry[]> = {};
  for (const o of odds) {
    const key = `${o.marketType}|${o.side ?? ""}|${o.line ?? ""}|${o.playerName ?? ""}`;
    if (!rows[key]) rows[key] = [];
    rows[key].push(o);
  }

  return (
    <div className="overflow-x-auto rounded-lg border border-neutral-800">
      <table className="w-full text-xs">
        <thead>
          <tr className="bg-neutral-800/50 text-neutral-500">
            <th className="text-left px-3 py-2 font-medium sticky left-0 bg-neutral-800/50">
              Market
            </th>
            {books.map((book) => (
              <th key={book} className="text-center px-2 py-2 font-medium">
                {BOOK_ABBREVIATIONS[book] ?? book}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {Object.entries(rows).map(([key, entries]) => {
            const first = entries[0];
            const label = first.playerName
              ? `${first.playerName} ${first.description ?? first.marketType}`
              : `${first.side ?? ""} ${first.marketType} ${first.line != null ? first.line : ""}`.trim();

            return (
              <tr
                key={key}
                className="border-t border-neutral-800/50 text-neutral-300"
              >
                <td className="px-3 py-1.5 truncate max-w-[200px] sticky left-0 bg-neutral-900">
                  {label}
                </td>
                {books.map((book) => {
                  const entry = entries.find((e) => e.book === book);
                  return (
                    <td
                      key={book}
                      className="text-center px-2 py-1.5 font-mono"
                    >
                      {entry?.price != null
                        ? formatOdds(entry.price, oddsFormat)
                        : "-"}
                    </td>
                  );
                })}
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}
