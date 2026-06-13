# Mentorship feature

Muslim professionals advertise their expertise, post short content, and connect with mentees, collaborators, or co-founders.

## Files (planned)

```
data/
  mentor_remote_repository.dart    # CRUD for mentor profiles
  mentor_post_repository.dart      # Create/list/delete posts
  mentor_follow_repository.dart    # Follow / unfollow, follower counts
domain/
  mentor_profile.dart    # MentorProfile freezed model
  mentor_post.dart       # MentorPost freezed model
presentation/
  controller/
    mentor_controller.dart       # Profile notifier
    mentor_post_controller.dart  # Post notifier
  view/
    mentor_list_screen.dart       # Discovery list (filterable by expertise/country)
    mentor_profile_screen.dart    # Full mentor profile + posts + follow button
    create_mentor_profile_sheet.dart  # Register/edit mentor profile
    create_post_sheet.dart            # Write post (≤200 words)
```

## Mentor profile

| Field | Notes |
|---|---|
| id | uuid PK |
| user_id | FK → auth.users (1:1) |
| display_name | pulled from user_profiles |
| headline | one-line summary (e.g. "Fintech founder · 10 yrs in Islamic banking") |
| bio | longer description |
| expertise_tags | array (e.g. ["finance", "startup", "tech"]) |
| linkedin_url | full LinkedIn profile URL |
| contact_email | optional public contact |
| country | ISO country code |
| city | city name (optional) |
| is_open_to_mentoring | bool |
| is_open_to_cofounding | bool |
| follower_count | denormalised counter |
| created_at | |

## Posts

Short posts (≤200 words) to share knowledge, solutions, or opportunities.

| Field | Notes |
|---|---|
| id | uuid PK |
| mentor_id | FK → mentor_profiles |
| content | text, max 200 words enforced in app + DB check |
| created_at | |

Posts appear on the mentor's profile page, newest first. Followers see new posts in a future feed.

## Follow system

`mentor_follows` table: `follower_id` (user) + `mentor_id` — composite PK.

- Follow / unfollow button on mentor profile
- Follower count shown on profile
- Future: push notification to mentor when someone follows

## Contact

Three contact paths, surfaced on the mentor profile:
1. **LinkedIn** — external link opens in browser
2. **Email** — mailto link (only if `contact_email` is set)
3. **In-app message** — future feature (DM thread)

## Discovery

`mentor_list_screen.dart` shows mentors filterable by:
- Country
- Expertise tags
- Open to mentoring (toggle)
- Open to co-founding (toggle)

Default sort: follower count descending.

## Ratings / Report

Users can rate a mentor (1–5, via polymorphic `ratings`) and report abuse.
