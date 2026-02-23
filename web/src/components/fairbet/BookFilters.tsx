"use client";

import { cn } from "@/lib/utils";
import { BOOK_ABBREVIATIONS, LEAGUE_OPTIONS } from "@/lib/constants";

interface BookFiltersProps {
  books: string[];
  selectedBook: string;
  onBookChange: (book: string) => void;
  selectedLeague: string;
  onLeagueChange: (league: string) => void;
  categories: string[];
  selectedCategory: string;
  onCategoryChange: (category: string) => void;
}

export function BookFilters({
  books,
  selectedBook,
  onBookChange,
  selectedLeague,
  onLeagueChange,
  categories,
  selectedCategory,
  onCategoryChange,
}: BookFiltersProps) {
  return (
    <div className="space-y-3">
      {/* League filter */}
      <div className="flex gap-2 overflow-x-auto scrollbar-none">
        <FilterChip
          label="All"
          active={selectedLeague === ""}
          onClick={() => onLeagueChange("")}
        />
        {LEAGUE_OPTIONS.map((l) => (
          <FilterChip
            key={l.code}
            label={l.label}
            active={selectedLeague === l.code}
            onClick={() => onLeagueChange(l.code)}
          />
        ))}
      </div>

      {/* Book filter */}
      <div className="flex gap-2 overflow-x-auto scrollbar-none">
        <FilterChip
          label="All Books"
          active={selectedBook === ""}
          onClick={() => onBookChange("")}
        />
        {books.map((b) => (
          <FilterChip
            key={b}
            label={BOOK_ABBREVIATIONS[b] ?? b}
            active={selectedBook === b}
            onClick={() => onBookChange(b)}
          />
        ))}
      </div>

      {/* Category filter */}
      {categories.length > 1 && (
        <div className="flex gap-2 overflow-x-auto scrollbar-none">
          <FilterChip
            label="All Markets"
            active={selectedCategory === ""}
            onClick={() => onCategoryChange("")}
          />
          {categories.map((c) => (
            <FilterChip
              key={c}
              label={c.replace(/_/g, " ")}
              active={selectedCategory === c}
              onClick={() => onCategoryChange(c)}
            />
          ))}
        </div>
      )}
    </div>
  );
}

function FilterChip({
  label,
  active,
  onClick,
}: {
  label: string;
  active: boolean;
  onClick: () => void;
}) {
  return (
    <button
      onClick={onClick}
      className={cn(
        "shrink-0 rounded-full px-3 py-1 text-xs font-medium transition capitalize",
        active
          ? "bg-white text-black"
          : "bg-neutral-800 text-neutral-400 hover:text-white",
      )}
    >
      {label}
    </button>
  );
}
