# Auth feature

Handles user identity, session lifecycle, account recovery, and routing guards.

## Design

No email, no OAuth. The app uses **Supabase anonymous auth**:

1. First launch → `supabase.auth.signInAnonymously()` — creates a UUID-backed user, persists the JWT in `supabase_flutter`'s secure local storage.
2. Every subsequent launch — session is restored automatically; no sign-in prompt.
3. After sign-in the user lands on **Profile Setup** if `user_profiles` row is missing or display name is empty.
4. After profile setup the user is taken to the **Recovery Token screen** where a one-time key is generated and must be saved.

## Files

```
data/
  login_remote_repository.dart   # signInAnonymously(), signOut(), fetchUserProfile()
  recovery_repository.dart       # generateAndSaveToken(), recoverAccount(token)
domain/
  user_profile.dart              # UserProfile freezed model
presentation/
  login_screen.dart              # Loading splash + "Recover existing account" link
  recovery_token_screen.dart     # Shown once after profile setup — displays the key
  account_recovery_screen.dart   # Token input form to restore a lost session
  controller/
    login_controller.dart        # LoginController (Riverpod), userStream, userId providers
```

## Flow

```
App launch
  └─ Supabase.initialize()
       └─ session exists?
            ├─ yes → restore session → check user_profiles → home or profile-setup
            └─ no  → LoginScreen shown
                       ├─ auto: signInAnonymously() → profile-setup → recovery-token → home
                       └─ tap "Recover": AccountRecoveryScreen → enter key → home
```

## Account recovery (key-based persistence)

Anonymous users have no email/password, so a **recovery key** is used to restore an account after reinstall or sign-out.

### Security model

| Piece | Detail |
|---|---|
| Token | 16 cryptographically random bytes (`Random.secure()`) → 32 uppercase hex chars |
| Format shown to user | `XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX` (128 bits of entropy) |
| What is stored in DB | SHA-256 hex digest only — via `save_recovery_token` security-definer RPC using `pgcrypto` |
| Plaintext token | Never stored anywhere — shown once, user must save it |
| Recovery flow | Plaintext token → Edge Function → SHA-256 hash → DB lookup → `auth.admin.createSession()` → fresh session returned → `setSession(refreshToken)` |
| DB leak impact | Hashes only; 2¹²⁸ search space makes brute force impossible |

### DB schema addition

`user_profiles.recovery_token_hash TEXT UNIQUE` — stores the SHA-256 hex digest.

### Supabase RPC — `save_recovery_token(p_token TEXT)`

Security-definer function. Normalises the token (strip dashes/spaces, uppercase), hashes with `pgcrypto`'s `digest()`, writes to the calling user's `user_profiles` row. Callable by `authenticated` role only.

### Edge Function — `recover-account`

- Path: `POST /functions/v1/recover-account`
- JWT verification: **off** (user has no session when recovering)
- Input: `{ "token": "XXXX-XXXX-..." }`
- Normalises token → SHA-256 hashes → queries `user_profiles` by hash → calls `supabase.auth.admin.createSession({ user_id })` → returns `{ access_token, refresh_token }`
- Returns the same `401 Invalid recovery token` for both wrong token and user-not-found (prevents enumeration)

### UX flow

1. Profile setup saves → navigates to `/login/profile-setup/recovery-token`
2. Recovery token screen generates + displays key, copy button, checkbox gate ("I've saved this")
3. "Continue to app" only enabled after checkbox is ticked → navigates to home
4. On login screen, "Recover existing account" link → `/login/recover`
5. Account recovery screen: paste/type key → calls `recoverAccount()` → session restored → home

## Routes

| Path | Screen |
|---|---|
| `/login` | `LoginScreen` — auto sign-in splash |
| `/login/profile-setup` | `ProfileSetupScreen` |
| `/login/profile-setup/recovery-token` | `RecoveryTokenScreen` — one-time key display |
| `/login/recover` | `AccountRecoveryScreen` — key input for recovery |

## Router guards (app_router.dart)

| Condition | Redirect |
|---|---|
| No Supabase session | `/login` |
| Session but no display name | `/login/profile-setup` |
| All good | `null` (stay) |
