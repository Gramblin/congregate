# Location filtering

Every discovery surface (communities, businesses, mentors, events, donation drives) is filtered by the user's chosen **country + city**. Location is a first-class piece of context, not a search parameter.

## Data

- `user_profiles.country` — ISO country code
- `user_profiles.city` — free-form city name
- `groups.country`, `groups.city`
- `businesses.country`, `businesses.city`
- `business_events.country`, `business_events.city` — inherited from business, overridable
- `visibility` (business/mentor) — `local` (only shown in same country/city) or `global`

## UX

- On first launch, user is prompted to pick country → city via a searchable sheet
- Selection persists to `user_profiles` and to local storage
- `LocationChip` in the AppBar shows current location and is tappable to change
- `FilterBar` widget (country + city chips) reused across Communities, Businesses, Mentorship tabs

## Queries

All list fetches pass the current `country`/`city` filter down to Supabase. `global` entities bypass the city filter but still respect country when set.

## Edge cases

- User travels: change city from AppBar, discovery updates immediately
- No city selected → show country-wide results
- No country selected → show global results only
