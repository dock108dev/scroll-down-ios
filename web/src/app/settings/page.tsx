"use client";

import { useSettings } from "@/stores/settings";

export default function SettingsPage() {
  const {
    theme,
    setTheme,
    scoreRevealMode,
    setScoreRevealMode,
    oddsFormat,
    setOddsFormat,
    autoResumePosition,
    setAutoResumePosition,
    hideLimitedData,
    setHideLimitedData,
  } = useSettings();

  return (
    <div className="mx-auto max-w-2xl px-4 py-6 space-y-6">
      <h1 className="text-xl font-bold">Settings</h1>

      {/* Appearance */}
      <SettingsSection title="Appearance">
        <SettingsRow label="Theme">
          <select
            value={theme}
            onChange={(e) =>
              setTheme(e.target.value as "system" | "light" | "dark")
            }
            className="bg-neutral-800 border border-neutral-700 rounded px-3 py-1.5 text-sm text-white"
          >
            <option value="system">System</option>
            <option value="light">Light</option>
            <option value="dark">Dark</option>
          </select>
        </SettingsRow>
      </SettingsSection>

      {/* Score Display */}
      <SettingsSection title="Score Display">
        <SettingsRow label="Score reveal">
          <select
            value={scoreRevealMode}
            onChange={(e) =>
              setScoreRevealMode(e.target.value as "always" | "onMarkRead")
            }
            className="bg-neutral-800 border border-neutral-700 rounded px-3 py-1.5 text-sm text-white"
          >
            <option value="onMarkRead">Reveal on Mark Read</option>
            <option value="always">Always Visible</option>
          </select>
        </SettingsRow>
      </SettingsSection>

      {/* Odds */}
      <SettingsSection title="Odds">
        <SettingsRow label="Format">
          <select
            value={oddsFormat}
            onChange={(e) =>
              setOddsFormat(
                e.target.value as "american" | "decimal" | "fractional",
              )
            }
            className="bg-neutral-800 border border-neutral-700 rounded px-3 py-1.5 text-sm text-white"
          >
            <option value="american">American (-110)</option>
            <option value="decimal">Decimal (1.91)</option>
            <option value="fractional">Fractional (10/11)</option>
          </select>
        </SettingsRow>
      </SettingsSection>

      {/* Game */}
      <SettingsSection title="Game">
        <SettingsToggle
          label="Auto-resume reading position"
          checked={autoResumePosition}
          onChange={setAutoResumePosition}
        />
        <SettingsToggle
          label="Hide games with limited data"
          checked={hideLimitedData}
          onChange={setHideLimitedData}
        />
      </SettingsSection>
    </div>
  );
}

function SettingsSection({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <div className="space-y-1">
      <h2 className="text-xs font-semibold text-neutral-500 uppercase tracking-wide px-1 mb-2">
        {title}
      </h2>
      <div className="rounded-lg border border-neutral-800 bg-neutral-900 divide-y divide-neutral-800">
        {children}
      </div>
    </div>
  );
}

function SettingsRow({
  label,
  children,
}: {
  label: string;
  children: React.ReactNode;
}) {
  return (
    <div className="flex items-center justify-between px-4 py-3">
      <span className="text-sm text-neutral-200">{label}</span>
      {children}
    </div>
  );
}

function SettingsToggle({
  label,
  checked,
  onChange,
}: {
  label: string;
  checked: boolean;
  onChange: (v: boolean) => void;
}) {
  return (
    <div className="flex items-center justify-between px-4 py-3">
      <span className="text-sm text-neutral-200">{label}</span>
      <button
        onClick={() => onChange(!checked)}
        className={`relative inline-flex h-6 w-11 items-center rounded-full transition ${
          checked ? "bg-green-500" : "bg-neutral-700"
        }`}
      >
        <span
          className={`inline-block h-4 w-4 transform rounded-full bg-white transition ${
            checked ? "translate-x-6" : "translate-x-1"
          }`}
        />
      </button>
    </div>
  );
}
