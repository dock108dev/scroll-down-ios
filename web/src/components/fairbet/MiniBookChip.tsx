import { cn } from "@/lib/utils";
import { BOOK_ABBREVIATIONS } from "@/lib/constants";

interface MiniBookChipProps {
  book: string;
  price: string;
  ev?: number;
  isSharp?: boolean;
}

export function MiniBookChip({ book, price, ev, isSharp }: MiniBookChipProps) {
  const hasPositiveEV = ev != null && ev > 0;
  const abbr = BOOK_ABBREVIATIONS[book] ?? book;

  return (
    <span
      className={cn(
        "inline-flex items-center gap-1 rounded px-2 py-1 text-xs font-mono",
        hasPositiveEV
          ? "bg-green-500/10 text-green-400 border border-green-500/20"
          : "bg-neutral-800 text-neutral-400 border border-neutral-700",
        isSharp && "ring-1 ring-blue-500/30",
      )}
    >
      <span className="text-[10px] text-neutral-500">{abbr}</span>
      {price}
    </span>
  );
}
