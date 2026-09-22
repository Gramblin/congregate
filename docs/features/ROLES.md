# Community roles

Three-tier role model within a community.

## Roles

| Role | Permissions |
|---|---|
| `admin` | Everything: promote/demote members, edit community metadata, delete community, create invitations, all leader permissions |
| `leader` | Create events, create donation drives, publish volunteer requests, accept/decline sponsorships, moderate members (kick) |
| `member` | RSVP to events, pledge as volunteer, opt into volunteer pool, rate, report |

## Table

`group_members`

| Field | Notes |
|---|---|
| group_id | FK → groups |
| user_id | FK → auth.users |
| role | enum `admin` / `leader` / `member` |
| joined_at | |

PK (`group_id`, `user_id`).

## Transitions

- Community creator → `admin` on creation
- Member joins via invite → `member`
- Admin promotes member → `leader`
- Admin demotes leader → `member`
- Only admin can change roles
- At least one admin must remain (server enforces on demote/delete)

## Migration note

Historical `group_members.role` was `admin | member`. Migration adds `leader` value; existing rows untouched.
