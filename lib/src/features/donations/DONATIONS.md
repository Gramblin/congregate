# Donations feature

Communities and initiatives can collect donations. Users can browse local and international initiatives to fund.

## Files (planned)

```
data/
  donations_remote_repository.dart   # list initiatives, donate, track
domain/
  donation_drive.dart    # DonationDrive freezed model
  donation.dart          # Donation record
presentation/
  controller/
    donations_controller.dart
  view/
    donations_screen.dart              # Browse all active drives (filterable by country)
    donation_drive_details_screen.dart # Drive detail + link + progress
    create_donation_drive_sheet.dart   # Community creates a drive
```

## Donation drive model

| Field | Notes |
|---|---|
| id | uuid PK |
| group_id | FK → groups (community that owns it), nullable for global initiatives |
| title | drive name |
| description | what the funds are for |
| external_link | GofundMe / LaunchGood / PayPal / bank transfer URL |
| goal_amount | optional target (display only) |
| current_amount | manually updated by community leaders |
| currency | ISO 4217 |
| country | optional — for filtering (local vs international) |
| is_global | bool — appears in international feed |
| seeking_sponsors | bool — businesses can apply to sponsor |
| created_by | FK → auth.users |
| is_active | bool |
| created_at | |

## Scopes

| Scope | Description |
|---|---|
| Community drive | Created by a community; visible to members + filterable in discovery |
| Local drive | `country` set; visible to users with matching location filter |
| International drive | `is_global = true`; visible to all users |

## User flow

1. User opens **Donations** tab (future bottom nav item) or browses from home
2. Sees drives filtered by their current location (local first, international below)
3. Taps a drive → sees title, description, progress bar (if goal set), "Donate" button
4. "Donate" opens the `external_link` in browser
5. Community leaders manually update `current_amount` to reflect progress

## Business sponsorship

When `seeking_sponsors = true`, the drive appears in the business sponsorship discovery section. See [BUSINESS.md](../business/BUSINESS.md#sponsorship--funding).

## Civic aspect

Congregate intends to surface a **Civic Initiatives** section where community and business drives are aggregated and can be presented to local governments or councils — a formatted report of Muslim community impact. This is a future editorial/export feature, not a user-facing flow in v1.

## Report abuse

Drives can be reported via the polymorphic `reports` table.
