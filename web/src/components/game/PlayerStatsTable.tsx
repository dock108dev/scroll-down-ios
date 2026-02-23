import type { PlayerStat } from "@/lib/types";

interface PlayerStatsTableProps {
  title: string;
  players: PlayerStat[];
}

export function PlayerStatsTable({ title, players }: PlayerStatsTableProps) {
  if (players.length === 0) return null;

  return (
    <div className="rounded-lg border border-neutral-800 bg-neutral-900 overflow-hidden">
      <div className="px-3 py-2 text-xs font-semibold text-neutral-300 bg-neutral-800/50">
        {title}
      </div>
      <div className="overflow-x-auto">
        <table className="w-full text-xs">
          <thead>
            <tr className="border-b border-neutral-800 text-neutral-500">
              <th className="text-left px-3 py-2 font-medium">Player</th>
              <th className="text-right px-2 py-2 font-medium">MIN</th>
              <th className="text-right px-2 py-2 font-medium">PTS</th>
              <th className="text-right px-2 py-2 font-medium">REB</th>
              <th className="text-right px-2 py-2 font-medium">AST</th>
            </tr>
          </thead>
          <tbody>
            {players.map((p) => (
              <tr
                key={p.playerName}
                className="border-b border-neutral-800/50 text-neutral-300"
              >
                <td className="px-3 py-1.5 truncate max-w-[150px]">
                  {p.playerName}
                </td>
                <td className="text-right px-2 py-1.5 font-mono">
                  {p.minutes ?? "-"}
                </td>
                <td className="text-right px-2 py-1.5 font-mono">
                  {p.points ?? "-"}
                </td>
                <td className="text-right px-2 py-1.5 font-mono">
                  {p.rebounds ?? "-"}
                </td>
                <td className="text-right px-2 py-1.5 font-mono">
                  {p.assists ?? "-"}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
