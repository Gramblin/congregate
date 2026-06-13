# Congregate

A Flutter app for the global Muslim community — connecting people through prayer groups, community initiatives, halal businesses, and mentorship.

## Vision

Congregate serves three interconnected pillars:

1. **Community** — prayer groups coordinate salah, share events, collect volunteers, and run fundraising initiatives.
2. **Business** — Muslim-owned businesses advertise products/services, sponsor community events, and connect with other Muslim businesses globally.
3. **Mentorship** — Muslim professionals advertise expertise, post content, and connect with mentees or co-founders.

## Core flows

### Community
- Create or join a group (mosque, household, university circle, local community)
- Post prayer events with type, time, place; members get FCM push notifications
- Mark attendance; see who's going
- Admin → Leaders → Members role hierarchy; admins assign/remove leaders
- Share GofundMe or donation links with members
- Collect and manage volunteers; accept volunteer requests from businesses
- Communities can create events *inside* a business venue

### Business
- Register a business (name, description, category, country, city, contact info)
- Post business events: discounts, promotions, open days
- Sponsor / fund community initiatives (in-app application flow)
- Request community volunteers/helpers
- Set visibility: local-only or global
- Contact other businesses for B2B collaboration (contact details public or private)
- Businesses require admin approval before going live

### Mentorship
- Professionals create mentor profiles with LinkedIn tag, bio, expertise
- Post short content (max 200 words) to advertise knowledge/solutions
- Other users follow mentors
- Contact via in-app message or displayed contact details

### Discovery
- Filter communities, businesses, and events by country and city
- User sets their current location from the home screen (changeable anytime)
- Businesses can be local (city-level) or global

## Tech stack

| Layer | Choice |
|---|---|
| Framework | Flutter (iOS + Android) |
| Backend / DB | Supabase (Postgres + RLS) |
| Auth | Supabase anonymous auth + recovery key |
| Push notifications | Firebase Cloud Messaging (FCM) |
| State management | Riverpod (riverpod_annotation) |
| Navigation | go_router (typed routes) |
| Models | freezed + json_serializable |

## Features

| Feature | Doc |
|---|---|
| Auth | [LOGIN.md](lib/src/features/login/LOGIN.md) |
| Profile | [PROFILE.md](lib/src/features/profile/PROFILE.md) |
| Home + Discovery | [HOME.md](lib/src/features/home/HOME.md) |
| Communities | [GROUP.md](lib/src/features/group/GROUP.md) |
| Community Events | [GROUP_DETAILS.md](lib/src/features/group_details/GROUP_DETAILS.md) |
| Businesses | [BUSINESS.md](lib/src/features/business/BUSINESS.md) |
| Mentorship | [MENTORSHIP.md](lib/src/features/mentorship/MENTORSHIP.md) |
| Donations | [DONATIONS.md](lib/src/features/donations/DONATIONS.md) |

## Project structure

```
lib/src/
  features/
    login/          # auth, session, recovery
    profile/        # user profile, FCM token
    home/           # discovery screen, location picker
    group/          # community CRUD, membership, invites
    group_details/  # prayer events, attendance, admin controls
    business/       # business profiles, events, sponsorships
    mentorship/     # mentor profiles, posts, follow
    donations/      # donation drives, links, gofundme integration
  router/           # go_router config + typed routes
  utils/            # init, providers, extensions
  constants/        # sizes, colours
```

## Supabase project

URL: `https://vgciuxuxmzqmiuvvzmta.supabase.co`

### Current tables

| Table | Purpose |
|---|---|
| `user_profiles` | display_name, real_name, fcm_token, location (country/city) |
| `groups` | community groups with visibility, FCM topic, country/city |
| `group_members` | user↔group with role (admin / leader / member) |
| `group_events` | prayer events per group |
| `group_event_attendees` | attendance status per event |
| `group_invitations` | invite codes (expiry, max_uses) |
| `group_join_requests` | pending/approved/rejected for private groups |

### Planned tables

| Table | Purpose |
|---|---|
| `businesses` | profile, category, country, city, contact, visibility, approval_status |
| `business_events` | discounts / promos per business |
| `business_members` | user↔business (owner / staff) |
| `sponsorships` | business → community initiative funding applications |
| `volunteer_requests` | business requests community volunteers |
| `volunteer_pledges` | community members pledge for a request |
| `mentor_profiles` | professional profiles, linkedin, bio |
| `mentor_posts` | short posts (≤200 words) per mentor |
| `mentor_follows` | user↔mentor follow relationship |
| `donations` | donation drives per community; external links |
| `ratings` | polymorphic (entity_type + entity_id), score 1-5, comment |
| `reports` | abuse reports (entity_type + entity_id + reason) |

## Auth model

Anonymous Supabase sessions — no email, no OAuth. UUID-backed, persisted via secure storage. Recovery via a one-time 128-bit key shown at setup. See [LOGIN.md](lib/src/features/login/LOGIN.md).

## Running locally

```bash
flutter run --dart-define-from-file keys.json
```

`keys.json` (gitignored):

```json
{
  "PROJECT_ID": "<supabase project id>",
  "SUPABASE_URL": "https://<ref>.supabase.co",
  "SUPABASE_API_KEY": "<anon key>",
  "ANON_KEY": "<anon key>"
}
```
