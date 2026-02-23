"use client";

import { cn } from "@/lib/utils";

interface SectionNavProps {
  sections: string[];
  active: string;
  onSelect: (section: string) => void;
}

export function SectionNav({ sections, active, onSelect }: SectionNavProps) {
  return (
    <div className="sticky top-14 z-30 border-b border-neutral-800 bg-neutral-950/95 backdrop-blur">
      <div className="flex overflow-x-auto scrollbar-none px-4 gap-1">
        {sections.map((section) => (
          <button
            key={section}
            onClick={() => onSelect(section)}
            className={cn(
              "shrink-0 px-3 py-2.5 text-xs font-medium border-b-2 transition",
              active === section
                ? "border-white text-white"
                : "border-transparent text-neutral-500 hover:text-neutral-300",
            )}
          >
            {section}
          </button>
        ))}
      </div>
    </div>
  );
}
