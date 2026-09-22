# Reports (abuse)

Polymorphic report flow. Any user can flag any entity for moderator review.

## Table

`reports`

| Field | Notes |
|---|---|
| id | uuid PK |
| entity_type | `community` / `business` / `business_event` / `mentor` / `mentor_post` / `donation_drive` / `group_event` |
| entity_id | uuid of the reported entity |
| user_id | FK → auth.users (reporter) |
| reason | enum: `spam`, `hateful`, `misleading`, `illegal`, `other` |
| detail | optional free-text |
| status | `open` / `reviewed` / `dismissed` / `actioned` |
| created_at | |

## UX

- Overflow menu on entity cards/details → "Report"
- Sheet with reason radio + optional detail
- Toast confirmation; no visible impact until moderator acts
- Rate-limit: max N reports per user per day (server-side)

## Moderation

Reports are reviewed in the Congregate moderator dashboard (separate web project, Phase 6). Actioned reports may lead to entity removal, warning, or ban.
