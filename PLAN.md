# Congregate — Expansion Plan

## Overview

Congregate evolves from a prayer-group coordination app into a full Muslim community platform with three pillars: **Community**, **Business**, and **Mentorship**. Execution is split into phases; earlier phases unblock later ones.

---

## Phase 1 — Foundation: Location + Roles + Ratings (2–3 weeks)

Everything downstream depends on location data and the new role model. Do this first.

### 1.1 Location infrastructure
- Add `country` + `city` columns to `user_profiles`, `groups`
- Location picker sheet on home screen (searchable country → city, persisted)
- Location chip in AppBar — tappable to change anytime
- Pass `country`/`city` filters to existing group fetch queries

### 1.2 Community roles upgrade
- Migrate `group_members.role` from `admin | member` → `admin | leader | member`
- UI: admin can promote member → leader, demote leader → member
- Leaders get event creation + donation + volunteer permissions (currently admin-only)

### 1.3 Polymorphic ratings + reports
- Create `ratings` table: `entity_type`, `entity_id`, `user_id`, `score`, `comment`, `created_at`
- Create `reports` table: `entity_type`, `entity_id`, `user_id`, `reason`, `created_at`
- Wire ratings UI to community cards (stars + review count)
- Wire report abuse to a hidden menu on communities/events

### 1.4 Home screen tabs
- Add TabBar: Communities | Businesses | Mentorship
- FilterBar widget (country + city chips, reusable across tabs)

**Deliverable:** location-aware home, leader role, ratings, report abuse.

---

## Phase 2 — Community enhancements (2 weeks)

Builds on Phase 1 roles + location.

### 2.1 Donation drives
- `donation_drives` table (see DONATIONS.md)
- Community leaders create drives with external link (GofundMe/LaunchGood/etc.)
- Drives appear inside the community as a pinned banner
- Global donations discovery screen (filter by country / international)

### 2.2 Volunteers
- `volunteer_pool` — members opt in, store skill tags
- `volunteer_requests` — placeholder for Phase 4 (business requests)
- UI: "Join volunteer list" button in community screen

### 2.3 Community approval system
- Add `groups.approval_status` column (`pending` | `approved` | `rejected`)
- New communities start as `pending` (visible only to creator until approved)
- Congregate admin dashboard (web, separate project, not in app) to approve
- App: show "pending approval" state to creator

### 2.4 Group events in businesses (link only)
- Add optional `business_id` FK to `group_events`
- UI: when creating an event, optionally tag a business location
- Business page shows "Community events here" section

**Deliverable:** donation drives live, volunteer pool seeded, approval flow.

---

## Phase 3 — Business feature (3–4 weeks)

### 3.1 Business profiles
- `businesses` table (see BUSINESS.md)
- Register business form (name, description, category, country, city, visibility, contact)
- Business details screen (profile, events, contact, ratings)
- Businesses tab in home discovery with FilterBar
- Approval flow same as communities

### 3.2 Business events
- `business_events` table
- Post discount / promo / open day events
- Business events appear in discovery and on the business profile

### 3.3 B2B directory
- Business filter screen: filter by country, city, category, visibility
- Contact details shown/hidden based on `contact_public`
- "Request contact" flow for private businesses (sends notification to owner)

### 3.4 Business sponsorship
- `sponsorships` table
- Community marks initiative as `seeking_sponsors`
- Business applies to sponsor → community admin accepts/declines
- Sponsor shown on initiative/donation drive page

### 3.5 Business volunteer requests
- Business submits `volunteer_request` to a specific community
- Community leaders broadcast to volunteer pool
- Members pledge; leader confirms and sends list to business

**Deliverable:** full business pillar live.

---

## Phase 4 — Mentorship feature (2 weeks)

### 4.1 Mentor profiles
- `mentor_profiles` table
- Create/edit profile (headline, bio, expertise tags, LinkedIn, contact email)
- Mentorship tab in home discovery

### 4.2 Posts
- `mentor_posts` table, ≤200 words enforced
- Post creation sheet
- Posts listed on mentor profile, newest first

### 4.3 Follow system
- `mentor_follows` table
- Follow/unfollow button on profile
- Follower count displayed

**Deliverable:** mentorship pillar live.

---

## Phase 5 — Polish + Safety (1–2 weeks)

### 5.1 Ratings everywhere
- Wire ratings to businesses and mentors (built in Phase 1, just needs UI on new entities)
- Average rating shown on all cards

### 5.2 Report abuse everywhere
- Wire report flow to business profiles, business events, mentor profiles, mentor posts, donation drives

### 5.3 Invitation system hardening
- QR code display for community invites
- Invite link analytics (uses remaining shown to admin)

### 5.4 Notifications
- Donation drive posted → notify community members
- New volunteer request → notify community leaders
- Sponsorship accepted/declined → notify business
- New follower → notify mentor

---

## Phase 6 — Future / Stretch

| Feature | Notes |
|---|---|
| In-app DM | Message between users, businesses, mentors |
| Civic initiatives export | Formatted report of Muslim community impact for local government presentation |
| Business membership tiers | Monthly/annual fee for premium business features |
| International donations feed | Curated global Muslim causes |
| Congregate moderator dashboard | Web-only; approve communities/businesses |
| Push for mentor new posts | Followers notified of new mentor posts |
| Co-founder matching | Structured matchmaking between mentor profiles |

---

## DB migrations order

1. `user_profiles`: add `country`, `city`
2. `groups`: add `country`, `city`, `approval_status`, `description`
3. `group_members.role`: migrate enum to include `leader`
4. Create `ratings` (polymorphic)
5. Create `reports` (polymorphic)
6. Create `donation_drives`
7. Create `volunteer_pool`, `volunteer_requests`, `volunteer_pledges`
8. Create `businesses`, `business_members`, `business_events`
9. Create `sponsorships`
10. Create `mentor_profiles`, `mentor_posts`, `mentor_follows`
11. Add `business_id` FK to `group_events`

---

## Questions to decide before Phase 3

1. **Payments** — are donations purely external links (GofundMe etc.) or do we want in-app payment processing? In-app requires Stripe/payment provider integration and significantly more compliance work.
2. **Moderation dashboard** — who are the Congregate admins? Is it just you, or a team? Do we build the dashboard now or gate it behind Phase 6?
3. **Business membership fees** — is this a revenue model? Flat fee, freemium, or fully free for now?
4. **Auth** — does the anonymous session model hold for business owners? A business owner losing their device = losing the business profile unless they saved their recovery key. Consider adding email auth as an optional link for business/mentor accounts.
