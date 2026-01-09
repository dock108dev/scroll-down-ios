# Beta Time Override — Quick Start

## TL;DR

Freeze app time to test historical data. Debug builds only.

---

## Enable (Choose One)

### Option 1: Environment Variable

```bash
export IOS_BETA_ASSUME_NOW=2024-02-15T04:00:00Z
```

Then launch app from Xcode.

### Option 2: Admin UI

1. Launch app (debug build)
2. **Long press** (2 sec) on "Updated X ago" text
3. Choose "Set Snapshot Date" or a preset

---

## Quick Presets

| Event | Date | Command |
|-------|------|---------|
| NBA Opening Night 2024 | Oct 23, 2024 | `export IOS_BETA_ASSUME_NOW=2024-10-23T04:00:00Z` |
| Super Bowl LVIII | Feb 12, 2024 | `export IOS_BETA_ASSUME_NOW=2024-02-12T04:00:00Z` |
| March Madness Final | Apr 9, 2024 | `export IOS_BETA_ASSUME_NOW=2024-04-09T04:00:00Z` |
| Yesterday at 4 AM | — | Use Admin UI preset |
| One Week Ago | — | Use Admin UI preset |

---

## Verify It's Working

✅ Orange badge appears: "🕐 Testing mode: Feb 15, 2024"  
✅ Console logs: `⏰ Time override enabled`  
✅ Only completed/scheduled games appear (no live games)

---

## Disable

### Option 1: Clear Environment Variable

```bash
unset IOS_BETA_ASSUME_NOW
```

Then relaunch app.

### Option 2: Admin UI

1. Open Admin Settings (long press)
2. Tap "Clear Override"

---

## What It Does

### In Snapshot Mode

- **Earlier section**: Games before snapshot date
- **Today section**: Games on snapshot date
- **Coming Up section**: Games after snapshot date
- **Live games**: Excluded (hidden)

### Normal Behavior

- Timelines work
- Recaps work
- Reveal controls work
- Social posts work

---

## Troubleshooting

### No orange badge?

- Check you're in a debug build
- Verify env var format: `YYYY-MM-DDTHH:MM:SSZ`
- Relaunch app after setting env var

### No games appearing?

- Backend may not have data for that date
- Try a different preset
- Check date is not too far in past/future

### Live games still showing?

- Verify orange badge is visible
- Check Console.app for "excluded X live games" log
- Try clearing and re-applying override

---

## Full Documentation

See `docs/BETA_TIME_OVERRIDE.md` for complete guide.

---

## Date Format

**Required**: ISO8601 with timezone

**Examples**:
- `2024-02-15T04:00:00Z` ✅
- `2024-02-15T04:00:00-05:00` ✅
- `2024-02-15 04:00:00` ❌ (no timezone)
- `02/15/2024` ❌ (wrong format)

---

## Safety

- ✅ Debug builds only
- ✅ Production builds ignore overrides
- ✅ No backend changes
- ✅ No API modifications
- ✅ Safe to use for testing

---

## Common Use Cases

### Test Yesterday's Games

```bash
export IOS_BETA_ASSUME_NOW=2025-01-08T04:00:00Z
```

### Replay a Specific Game Day

```bash
export IOS_BETA_ASSUME_NOW=2024-12-25T04:00:00Z  # Christmas Day games
```

### Validate Historical Season

```bash
export IOS_BETA_ASSUME_NOW=2024-06-01T04:00:00Z  # NBA Finals
```

---

## Tips

1. **Use 4:00 AM** as the time — games from previous day will be completed
2. **Check backend data** — ensure games exist for that date
3. **Clear override** when done — avoid confusion
4. **Use presets** — faster than typing dates
5. **Watch Console logs** — helpful for debugging

---

## Console Logs

Filter by: `com.scrolldown.app.time`

**On Enable**:
```
⏰ Time override enabled: 2024-02-15T04:00:00Z
⏰ Real device time: 2025-01-09T12:30:00Z
```

**On Filter**:
```
⏰ Snapshot mode: excluded 3 live/unknown games
```

**On Disable**:
```
⏰ Time override disabled, using real time
```

---

## Need Help?

1. Check Console.app logs
2. Verify date format
3. Try a preset instead
4. See full docs: `docs/BETA_TIME_OVERRIDE.md`
