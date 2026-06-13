# Community (Group) feature

Covers community creation, membership roles, invite/approval flows, FCM notifications, donations, and volunteer management.

## Files

```
data/
  group_remote_repository.dart              # createGroup, fetchGroup, deleteGroup, approveGroup
  group_membership_remote_repository.dart   # joinGroup, leaveGroup, getMembers, updateRole, assignLeader
  group_invitations_remote_repository.dart  # createInvite, redeemInvite, listInvites, deactivateInvite
  group_events_repository.dart              # createEvent, getGroupEvents, deleteEvent, markAttendance, getAttendees
  group_donations_repository.dart           # [NEW] createDonationDrive, listDrives, shareDrive
  group_volunteers_repository.dart          # [NEW] createVolunteerRequest, listVolunteers, pledgeVolunteer
  fcm_notifications_remote_repository.dart  # sendPrayerEventNotification, sendGeneralNotification
domain/
  create_group.dart        # CreateGroup request model
  event_attendee.dart      # EventAttendee freezed model
  group_invitation.dart    # GroupInvitation freezed model
  donation_drive.dart      # [NEW] DonationDrive freezed model
  volunteer_request.dart   # [NEW] VolunteerRequest freezed model
presentation/
  controller/
    group_controller.dart        # GroupController — create, manage members, roles
    group_event_controller.dart  # GroupEventController — create/delete events, notifications
  view/
    create_group_sheet.dart          # New community form
    group_invite_screen.dart         # Manage invite links
    donation_drives_screen.dart      # [NEW] List and manage donation drives
    create_donation_drive_sheet.dart # [NEW] Add GofundMe link or internal drive
    volunteer_board_screen.dart      # [NEW] List volunteer requests; pledge
```

## Role hierarchy

```
Admin
  └─ Leader(s)    ← assigned by admin
       └─ Member(s)
```

| Role | Permissions |
|---|---|
| `admin` | All — delete group, edit, manage members, assign/remove leaders, approve join requests |
| `leader` | Create events, manage volunteers, post donation drives, send announcements |
| `member` | Join events, pledge volunteering, view donation drives |

`group_members.role` values: `admin`, `leader`, `member`.

Admin can promote a member to leader or demote a leader to member via the members screen. There is always at least one admin.

## Approval system

Communities can be **open** (anyone joins) or require **approval** (admin/leader approves join requests).

Additionally, a future global moderation layer will require new communities to be approved by a Congregate moderator before appearing in public discovery — stored in `groups.approval_status` (`pending` | `approved` | `rejected`).

## Invitation system

```
Admin/Leader generates invite code
  → stored in group_invitations (expiry, max_uses, single-use flag)
  → deep link: congregate://invite/<code>
  → share via native share sheet

Recipient opens link
  → router → /invite/<code>
  → shows group info + "Join" button
  → redeemInvite() → group_members row created
```

Additional invite controls:
- QR code display for in-person sharing
- Invite link expiry and per-link use cap
- Admin can deactivate any link at any time

## Donation drives

Leaders and admins can create **donation drives**:
- External link (GofundMe, LaunchGood, PayPal, bank transfer info)
- Or internal goal with manual progress updates
- Drives are shown to all group members with a banner in the community feed
- Members can tap to open the external link
- Report abuse on a drive

`donation_drives` table: `group_id`, `title`, `description`, `external_link`, `goal_amount`, `current_amount`, `created_by`, `is_active`.

## Volunteers

Communities maintain a **volunteer pool**:
- Members opt in as volunteers (skill tags, availability)
- Businesses can send a `volunteer_request` to a community
- Leaders/admins approve or decline the request, then announce to volunteer members
- Volunteers pledge; final list sent back to requesting business

## Data models

### groups

| Column | Notes |
|---|---|
| id | uuid PK |
| name | display name |
| description | text |
| visibility | `public` or `private` |
| topic_id | FCM topic |
| created_by | FK → auth.users |
| country | ISO country code |
| city | city name |
| approval_status | `pending` / `approved` / `rejected` |

### group_members

| Column | Notes |
|---|---|
| group_id + user_id | composite PK |
| role | `admin` / `leader` / `member` |
| show_real_name | privacy per group |

## FCM notifications

`sendPrayerEventNotification()` fans out via FCM topic. Planned additions:
- Donation drive posted → notify members
- Volunteer request received → notify leaders
- Member approved → notify requester
