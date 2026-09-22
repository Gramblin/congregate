# Volunteers

Members opt into a community's volunteer pool. Community leaders can broadcast volunteer requests (from businesses or from the community itself). Members pledge; leaders confirm.

## Tables

### `volunteer_pool`
Per-community opt-in list.

| Field | Notes |
|---|---|
| id | uuid PK |
| community_id | FK → groups |
| user_id | FK → auth.users |
| skills | text[] — free-form tags (e.g. `driver`, `translator-arabic`, `medical`) |
| joined_at | |

Unique (`community_id`, `user_id`).

### `volunteer_requests`
Ask sent to a community.

| Field | Notes |
|---|---|
| id | uuid PK |
| community_id | FK → groups |
| requester_type | `business` / `community` |
| requester_id | uuid — business_id or group_id |
| title | e.g. "Ramadan iftar servers, 30 people" |
| description | |
| role | short label |
| skills_needed | text[] |
| date | when volunteers are needed |
| hours | estimated |
| slots | int — how many volunteers wanted |
| status | `open` / `filled` / `closed` |
| created_at | |

### `volunteer_pledges`
Member commitments against a request.

| Field | Notes |
|---|---|
| id | uuid PK |
| request_id | FK → volunteer_requests |
| user_id | FK → auth.users |
| status | `pledged` / `confirmed` / `declined` / `withdrew` |
| pledged_at | |

## Flow

1. Members open community → "Join volunteer list" → optionally add skills
2. Request comes in (from business via [SPONSORSHIPS.md](SPONSORSHIPS.md)-adjacent flow, or created by community leader directly)
3. Community leader reviews and publishes → broadcast to pool (push + in-app)
4. Members pledge
5. Leader confirms final list → status `filled`
6. If business-initiated: confirmed list (names + contact) sent to business

## Rules

- Only pool members receive broadcasts
- Pledging is soft commitment until leader confirms
- Members can withdraw before confirmation
