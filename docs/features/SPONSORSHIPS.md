# Sponsorships

Businesses fund community initiatives (events, donation drives, projects). Two-sided flow: community marks initiative as seeking sponsors, business applies, community accepts.

## Table

`sponsorships`

| Field | Notes |
|---|---|
| id | uuid PK |
| community_id | FK → groups |
| initiative_type | `group_event` / `donation_drive` / `project` |
| initiative_id | uuid — polymorphic ref |
| business_id | FK → businesses |
| amount | numeric — proposed sponsorship amount |
| currency | ISO 4217 |
| message | text — pitch from business |
| status | `pending` / `accepted` / `declined` / `withdrawn` |
| responded_by | FK → auth.users (community admin/leader) |
| responded_at | |
| created_at | |

## Flow

1. Community leader/admin toggles initiative `seeking_sponsors = true`
2. Business browses the sponsorship discovery screen (filter by country/city/category)
3. Business submits sponsorship application (amount, message)
4. Community leader/admin sees application in inbox → accepts or declines
5. Accepted sponsor rendered on the initiative page (logo + business name → tap opens business profile)
6. Notifications sent on each transition (see [NOTIFICATIONS.md](NOTIFICATIONS.md))

## Rules

- Only community admin/leader can accept/decline
- Business owner can withdraw while `pending`
- Multiple sponsors per initiative allowed
- Declined applications keep audit trail; not shown publicly

## Payments

Out of scope for Phase 3. Sponsorships are trust-based commitments; payment happens off-platform. In-app payment processing gated behind a Phase 6 decision (see PLAN.md open questions).
