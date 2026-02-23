import { create } from "zustand";
import { persist } from "zustand/middleware";

interface SettingsState {
  theme: "system" | "light" | "dark";
  scoreRevealMode: "always" | "onMarkRead";
  preferredSportsbook: string;
  oddsFormat: "american" | "decimal" | "fractional";
  autoResumePosition: boolean;
  homeExpandedSections: string[];
  gameExpandedSections: string[];
  hideLimitedData: boolean;

  setTheme: (t: "system" | "light" | "dark") => void;
  setScoreRevealMode: (m: "always" | "onMarkRead") => void;
  setPreferredSportsbook: (b: string) => void;
  setOddsFormat: (f: "american" | "decimal" | "fractional") => void;
  setAutoResumePosition: (v: boolean) => void;
  setHomeExpandedSections: (s: string[]) => void;
  setGameExpandedSections: (s: string[]) => void;
  setHideLimitedData: (v: boolean) => void;
}

export const useSettings = create<SettingsState>()(
  persist(
    (set) => ({
      theme: "system",
      scoreRevealMode: "onMarkRead",
      preferredSportsbook: "",
      oddsFormat: "american",
      autoResumePosition: true,
      homeExpandedSections: [],
      gameExpandedSections: [],
      hideLimitedData: true,

      setTheme: (theme) => set({ theme }),
      setScoreRevealMode: (scoreRevealMode) => set({ scoreRevealMode }),
      setPreferredSportsbook: (preferredSportsbook) =>
        set({ preferredSportsbook }),
      setOddsFormat: (oddsFormat) => set({ oddsFormat }),
      setAutoResumePosition: (autoResumePosition) =>
        set({ autoResumePosition }),
      setHomeExpandedSections: (homeExpandedSections) =>
        set({ homeExpandedSections }),
      setGameExpandedSections: (gameExpandedSections) =>
        set({ gameExpandedSections }),
      setHideLimitedData: (hideLimitedData) => set({ hideLimitedData }),
    }),
    { name: "sd-settings" },
  ),
);
