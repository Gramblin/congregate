# Invitations

Communities are join-by-invite. Admins/leaders generate invitation codes; users redeem via link or QR.

## Table

`invitations`

| Field | Notes |
|---|---|
| id | uuid PK |
| group_id | FK → groups |
| code | short URL-safe token |
| created_by | FK → auth.users |
| max_uses | int (nullable → unlimited) |
| uses_remaining | int (nullable if unlimited) |
| expires_at | timestamptz (nullable) |
| created_at | |

## UX

- Admin/leader taps "Invite" in community → sheet: max uses selector + expiry
- Generated invite shown as link + QR code
- Redemption: opening link (deep link) or scanning QR opens app → confirm sheet → joins community
- Admin dashboard shows active invites with uses remaining and expiry countdown

## Rules

- Redeeming decrements `uses_remaining`; hits 0 → invite invalidated
- Expired invites rejected with clear error
- Only community admin/leader can create invites
- One membership per user per community (redemption is idempotent)

## Deep links

Format: `https://congregate.app/invite/<code>` — resolves via router to the join-confirmation screen. Fallback web page for uninstalled users.
