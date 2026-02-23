"use client";

import { cn } from "@/lib/utils";

interface ParlaySheetProps {
  open: boolean;
  onClose: () => void;
}

export function ParlaySheet({ open, onClose }: ParlaySheetProps) {
  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center md:items-center">
      <div className="absolute inset-0 bg-black/60" onClick={onClose} />
      <div
        className={cn(
          "relative z-10 w-full max-w-lg rounded-t-2xl md:rounded-2xl bg-neutral-900 border border-neutral-800 p-6",
        )}
      >
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold">Parlay Builder</h2>
          <button
            onClick={onClose}
            className="text-neutral-500 hover:text-white text-sm"
          >
            Close
          </button>
        </div>

        <div className="text-sm text-neutral-400 text-center py-8">
          Parlay builder coming soon. Select +EV bets from the list to combine
          them.
        </div>
      </div>
    </div>
  );
}
