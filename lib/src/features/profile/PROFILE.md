# Profile feature

Manages the user's display identity within the app. There is no account in the traditional sense — just a display name and an optional real name stored in `user_profiles`.

## Files

```
data/
  user_profile_remote_repository.dart   # fetchProfile, createProfile, updateProfile
presentation/
  controllers/
    user_profile_notifier.dart          # UserProfileNotifier (keepAlive Riverpod)
    views/
      profile_screen.dart               # View/edit existing profile
      profile_setup_screen.dart         # First-time setup after sign-in
```

## Data model — user_profiles

| Column | Type | Notes |
|---|---|---|
| user_id | uuid PK | FK → auth.users |
| display_name | text | shown in group member lists |
| real_name | text? | only shown if show_real_name = true |
| show_real_name | bool | user-controlled toggle |
| fcm_token | text? | updated on app launch + token refresh |
| created_at | timestamp | |

## UserProfileNotifier

- `keepAlive: true` — profile is loaded once at startup and shared app-wide.
- On build: checks `SharedPreferences` cache first, then fetches from Supabase.
- `createProfile` / `updateProfile` both write to Supabase and update the local cache.
- `clearCache` is called before sign-out to avoid stale data on next session.

## Profile setup screen

Shown by the router when the user has a valid session but no `user_profiles` row, or when `display_name` is empty. The user sets:

- **Display name** (required, shown publicly in groups)
- **Real name** (optional)
- **Show real name** toggle

Pressing "Save & Continue" calls `createProfile`, then navigates to `/home`.

## FCM token

The `fcm_token` column is updated in two places:
1. App startup (`MainInitializationUtils._updateFcmTokenInDatabase`)
2. Token refresh listener (`_setupFcmTokenRefreshListener`)

This keeps the token current across reinstalls and token rotations.
