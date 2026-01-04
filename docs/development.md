# Development

## Mock Mode

The app runs in **mock mode** by default—no backend required. Toggle via `AppConfig.dataMode`.

## Compact Timeline

Tap a compact timeline moment to open its expanded view with a play-by-play slice.
Timeline scores surface via separators (live, halftime, period end) instead of inside play rows.

## Running Tests

```bash
xcodebuild test -scheme ScrollDown -destination 'platform=iOS Simulator,name=iPhone 16'
```

## QA Checklist

- Dark/light mode
- Long team names
- Games without ratings
- Mid-major conferences
- Offline mode fallback
