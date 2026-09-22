# Notifications

FCM push + in-app inbox. Every high-signal event across community, business, mentorship pillars fans out to relevant users.

## Transport

- Firebase Cloud Messaging for push
- `notifications` table for in-app inbox (persistent, read/unread state)

## Table

`notifications`

| Field | Notes |
|---|---|
| id | uuid PK |
| user_id | FK → auth.users (recipient) |
| type | enum — see list below |
| entity_type | polymorphic ref type |
| entity_id | polymorphic ref id |
| title | rendered title |
| body | rendered body |
| data | jsonb — deep-link payload |
| read_at | nullable |
| created_at | |

## Event → recipient matrix

| Event | Recipients | Type |
|---|---|---|
| New event in a joined community | All members | `event.created` |
| Event updated | All RSVPs | `event.updated` |
| Community invite accepted | Inviter + admins | `invite.redeemed` |
| Donation drive posted | All community members | `donation.created` |
| Volunteer request broadcast | Volunteer pool members | `volunteer.requested` |
| Volunteer pledge confirmed | Pledging member | `volunteer.confirmed` |
| Sponsorship application received | Community admin/leader | `sponsorship.applied` |
| Sponsorship accepted/declined | Business owner | `sponsorship.decided` |
| New mentor follower | Mentor | `mentor.followed` |
| New mentor post | Followers | `mentor.posted` |
| Report actioned against your entity | Entity owner | `report.actioned` |
| Business approved/rejected | Business owner | `approval.decided` |
| Community approved/rejected | Community creator | `approval.decided` |
| Prayer time reminder | Opted-in users | `prayer.reminder` |

## User preferences

Per-type mute toggles in profile settings. Push channel + in-app inbox toggleable independently. Prayer reminders opt-in per prayer (Fajr, Dhuhr, Asr, Maghrib, Isha).

## Deep-linking

`data.route` on each notification drives router navigation on tap. Falls back to notifications inbox if route is unresolved.
