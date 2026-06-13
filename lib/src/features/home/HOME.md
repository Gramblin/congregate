# Home / Discovery feature

The main screen. Shows the user's communities, discoverable content, and entry points to businesses and mentorship. Location-aware — user sets their country/city and all feeds filter accordingly.

## Files

```
data/
  home_remote_repository.dart         # fetchUserGroups(), fetchJoinableGroups(), fetchBusinesses(), fetchMentors()
  prayer_times_repository.dart        # GPS-based prayer times via Aladhan API (cached)
domain/
  group.dart                          # Group freezed model
  home_state.dart                     # HomeState
presentation/
  controller/
    home_controller.dart              # HomeController
  view/
    home_screen.dart                  # Main scaffold — tabs: Communities | Businesses | Mentorship
    group_tile.dart                   # Community row
    join_group_sheet.dart             # Join via invite code
    location_picker_sheet.dart        # [NEW] Country/city selector — persisted per user
    filter_bar.dart                   # [NEW] Country + city chips for filtering feed
```

## Location model

User has a **current location** (country + optional city) stored in `user_profiles.country` and `user_profiles.city`. This is:
- Set on the home screen via a tappable location chip in the AppBar or header
- Can be changed at any time (not tied to GPS)
- Used as the default filter for communities, businesses, and events

```
AppBar
  [📍 London, UK ▾]   ← tappable → LocationPickerSheet
```

`LocationPickerSheet` shows a searchable list of countries, then cities. Saves to Supabase + local prefs on confirm.

## Home screen layout

```
AppBar
  leading: profile icon → /profile
  center: location chip (country/city) → LocationPickerSheet
  actions: sign-out

TabBar
  Communities | Businesses | Mentorship

Tab: Communities
  FilterBar (country chip, city chip)
  "Your Communities" section
    GroupTile → GroupDetailsScreen
  "Nearby / Discoverable" section
    GroupTile (not joined) → GroupDetailsScreen
  FABs: [Join] [New Community]

Tab: Businesses
  FilterBar (country, city, category)
  BusinessTile list → BusinessDetailsScreen
  FAB: [Register Business]

Tab: Mentorship
  FilterBar (expertise, country)
  MentorTile list → MentorProfileScreen
```

## FilterBar

Stateful widget showing active filter chips. Chips:
- **Country** — set from current location by default, tappable to change
- **City** — optional, tappable to change
- **Category** (businesses tab only)
- **Expertise** (mentorship tab only)

Filters are passed as query params to repository methods.

## Prayer times

`todayPrayerTimesProvider` fetches from Aladhan API using device GPS. Cached in SharedPreferences per `lat/lon/date` key. Used in `CreateEventBottomSheet` to auto-select next prayer and pre-fill time.
