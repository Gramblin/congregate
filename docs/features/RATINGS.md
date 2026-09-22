# Ratings

Polymorphic 1–5 star ratings with optional comment. One table serves communities, businesses, business events, mentors, mentor posts, and donation drives.

## Table

`ratings`

| Field | Notes |
|---|---|
| id | uuid PK |
| entity_type | `community` / `business` / `business_event` / `mentor` / `mentor_post` / `donation_drive` |
| entity_id | uuid of the rated entity |
| user_id | FK → auth.users |
| score | int 1–5 |
| comment | optional text |
| created_at | |

Unique constraint on (`entity_type`, `entity_id`, `user_id`) → one rating per user per entity; new submission upserts.

## Rules

- User cannot rate their own entity (own community if admin/leader, own business, own mentor profile, own post)
- Score required; comment optional
- Averages computed on read (or cached via view / trigger — TBD)

## UX

- Stars + review count shown on entity cards
- Tap → sheet with score selector + comment field
- Rating list shown on entity detail screen, newest first
