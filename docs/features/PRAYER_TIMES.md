# Prayer times

Location-aware daily prayer schedule + optional per-prayer notification reminders.

## Source

Prayer times are computed from the user's `country` + `city` (see [LOCATION.md](LOCATION.md)) using a public prayer-times API (e.g. Aladhan) or an offline computation library. Cache per (city, date) to minimize network usage.

## UX

- Prayer widget on Home showing today's five prayers (Fajr, Dhuhr, Asr, Maghrib, Isha) + next-prayer countdown
- Tap widget → detailed screen with monthly view, calculation method selector, jurisprudence (Shafi'i / Hanafi) toggle for Asr
- Settings: enable/disable reminders per prayer, offset (e.g. 10 min before)

## Data

Client-only for the schedule. User preferences stored on `user_profiles`:

| Field | Notes |
|---|---|
| calc_method | enum — MWL / ISNA / Egypt / Makkah / Karachi / Tehran / Jafari |
| madhab | `shafii` / `hanafi` (affects Asr) |
| prayer_reminders | jsonb — `{fajr: true, dhuhr: false, ...}` |
| reminder_offset_min | int, default 0 |

## Reminders

Local scheduled notifications (not push) — no server dependency. Rescheduled daily and whenever location or preferences change. Type `prayer.reminder` — see [NOTIFICATIONS.md](NOTIFICATIONS.md).
