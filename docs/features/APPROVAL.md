# Approval / moderation

New communities and businesses go through a moderation queue before being visible in discovery. Prevents spam, impersonation, and low-quality listings.

## Data

`groups.approval_status` and `businesses.approval_status` — enum `pending` / `approved` / `rejected`.

Optional companion columns per entity:
- `approved_by` — moderator user id
- `approved_at`
- `rejection_reason` — text (shown to owner)

## Flow

1. User submits community/business → row created with `approval_status = pending`
2. Entity is visible only to the creator (with "Pending approval" banner)
3. Congregate moderator reviews in web dashboard (separate project, Phase 6)
4. Approved → entity enters discovery; creator notified via `approval.decided` (see [NOTIFICATIONS.md](NOTIFICATIONS.md))
5. Rejected → creator sees rejection reason; can edit and resubmit → back to `pending`

## Rules (RLS)

- Discovery queries filter `approval_status = 'approved'`
- Owner can always read their own pending entity
- Only moderators can update `approval_status` (server-side role check)

## Reports interaction

An approved entity accumulating reports may be re-flagged for review; moderator can revoke to `rejected`. See [REPORTS.md](REPORTS.md).
