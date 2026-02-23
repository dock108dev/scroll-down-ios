import type { BlockMiniBox } from "@/lib/types";

interface MiniBoxScoreProps {
  miniBox: BlockMiniBox;
  homeTeam?: string;
  awayTeam?: string;
  homeColor?: string;
  awayColor?: string;
}

export function MiniBoxScore({
  miniBox,
  homeTeam,
  awayTeam,
  homeColor,
  awayColor,
}: MiniBoxScoreProps) {
  return (
    <div className="mt-3 pt-3 border-t border-neutral-800">
      {miniBox.block_stars.length > 0 && (
        <div className="text-[10px] text-yellow-500 font-medium mb-2">
          Block Stars: {miniBox.block_stars.join(", ")}
        </div>
      )}

      <div className="grid grid-cols-2 gap-3 text-xs">
        {/* Away */}
        <div>
          <div
            className="font-medium mb-1"
            style={{ color: awayColor ?? "#a3a3a3" }}
          >
            {miniBox.away.team || awayTeam}
          </div>
          {miniBox.away.players.map((p) => (
            <div key={p.name} className="flex justify-between text-neutral-400">
              <span className="truncate">{p.name}</span>
              <span className="font-mono">
                {p.pts != null ? `${p.pts}p` : ""}
                {p.reb != null ? ` ${p.reb}r` : ""}
                {p.ast != null ? ` ${p.ast}a` : ""}
                {p.goals != null ? ` ${p.goals}g` : ""}
              </span>
            </div>
          ))}
        </div>

        {/* Home */}
        <div>
          <div
            className="font-medium mb-1"
            style={{ color: homeColor ?? "#a3a3a3" }}
          >
            {miniBox.home.team || homeTeam}
          </div>
          {miniBox.home.players.map((p) => (
            <div key={p.name} className="flex justify-between text-neutral-400">
              <span className="truncate">{p.name}</span>
              <span className="font-mono">
                {p.pts != null ? `${p.pts}p` : ""}
                {p.reb != null ? ` ${p.reb}r` : ""}
                {p.ast != null ? ` ${p.ast}a` : ""}
                {p.goals != null ? ` ${p.goals}g` : ""}
              </span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
