# Business feature

Muslim-owned businesses can register, advertise products/services, post events, sponsor community initiatives, request volunteers, and connect with other businesses.

## Files (planned)

```
data/
  business_remote_repository.dart         # CRUD for business profiles
  business_events_repository.dart         # Business events (discounts, promos, open days)
  business_sponsorship_repository.dart    # Apply to sponsor / fund community initiatives
  business_volunteer_repository.dart      # Request volunteers from communities
  business_directory_repository.dart      # B2B discovery — filter by country/city/category
domain/
  business.dart              # Business freezed model
  business_event.dart        # BusinessEvent freezed model
  sponsorship_application.dart  # Sponsorship request model
  volunteer_request.dart     # Business → community volunteer request
presentation/
  controller/
    business_controller.dart         # Business CRUD notifier
    business_event_controller.dart   # Events notifier
  view/
    business_list_screen.dart        # Discovery list (filterable)
    business_details_screen.dart     # Full profile + events + contact
    create_business_sheet.dart       # Register/edit a business
    business_events_screen.dart      # Business's posted events
    create_business_event_sheet.dart # Post discount / promo event
    sponsor_initiative_sheet.dart    # Apply to fund a community initiative
    b2b_directory_screen.dart        # Business-to-business discovery
    volunteer_request_sheet.dart     # Request volunteers from a community
```

## Business profile

| Field | Notes |
|---|---|
| id | uuid PK |
| name | business name |
| description | about the business |
| category | e.g. Food, Finance, Education, Legal, Tech, Health, Retail, Other |
| country | ISO country code |
| city | city name |
| visibility | `local` (city/country only) or `global` |
| contact_public | bool — whether contact info is visible to all users |
| email | contact email (shown if contact_public or business-to-business request accepted) |
| phone | contact phone |
| website | URL |
| owner_id | FK → auth.users |
| approval_status | `pending` / `approved` / `rejected` — reviewed by Congregate moderators |
| created_at | |

## Approval system

New business registrations go through a **moderation queue**:
1. Owner submits business → `approval_status = pending`
2. Congregate admin reviews in a moderation dashboard (future)
3. Approved → visible in discovery; rejected → owner notified with reason

Businesses are not shown in discovery until approved.

## Business events

Short-lived posts: discounts, promotions, open days, product launches.

| Field | Notes |
|---|---|
| id | uuid PK |
| business_id | FK → businesses |
| title | e.g. "20% off all halal meats this Friday" |
| description | details |
| start_at | event start datetime |
| end_at | optional end |
| country / city | inherits from business, overridable |
| created_by | FK → auth.users |

Business events appear in the **Businesses** tab and in **community event feeds** if the community created an event inside that business.

## Sponsorship / funding

Businesses can fund community initiatives (campaigns, events, projects):

1. Business browses community initiatives marked as `seeking_sponsors = true`
2. Business submits a `sponsorship_application` (amount offered, message)
3. Community admin/leader reviews and accepts or declines
4. Accepted sponsor shown on initiative page with optional business logo

`sponsorships` table: `community_id`, `initiative_id`, `business_id`, `amount`, `message`, `status` (`pending`/`accepted`/`declined`), `created_at`.

## Volunteers (business requesting from community)

1. Business submits a `volunteer_request` to a specific community (role needed, date, hours, description)
2. Community leaders review and broadcast to volunteer pool
3. Members pledge; leader confirms final list and sends back to business
4. Business can view confirmed volunteer names and contact them

## B2B directory

Businesses can set `contact_public = false` for privacy (contact details hidden from regular users), but other **verified businesses** can request contact.

Filter options:
- Country
- City
- Category
- Visibility (local / global)

A UK business looking for a German partner → filters `country = DE`, sees businesses with contact_public = true or sends a contact request for private ones.

## Ratings

Users can rate a business (1–5 stars + optional comment) after interacting with it. Stored in the polymorphic `ratings` table (`entity_type = 'business'`). Average rating shown on business profile.

## Report abuse

Any user can report a business profile or business event via the polymorphic `reports` table.
