# Group details feature

Shows everything inside a group: members, upcoming prayer events, and admin controls.

## Files

```
domain/
  group_event.dart      # GroupEvent freezed model
  group_member.dart     # GroupMember freezed model
presentation/
  controllers/
    group_members_provider.dart       # streams group_members for a given groupId
  views/
    group_details_screen.dart         # Main screen — events list + member count
    event_card.dart                   # Single event card with attendance controls
    create_event_sheet.dart           # Bottom sheet — post a new prayer event
    event_attendees_list_sheet.dart   # Bottom sheet — list of who is going
    edit_group_details_sheet.dart     # Bottom sheet — rename group, toggle visibility
    share_private_group_sheet.dart    # Bottom sheet — show/copy invite code for private groups
```

## GroupEvent model

| Field | Source column | Notes |
|---|---|---|
| id | id | |
| groupId | group_id | |
| createdBy | created_by | used to hide delete button for non-creators |
| prayerType | prayer_type | Fajr / Dhuhr / Asr / Maghrib / Isha / Nafl / Taraweeh / Tahajjud |
| prayerDateTime | prayer_datetime | UTC stored, displayed in local time |
| prayerPlace | prayer_place | free-text location |
| note | note | optional extra info |

## EventCard

Displays the event and lets members interact:

- **Going / Not going** buttons — call `markAttendance()` which upserts into `group_event_attendees`
- Attendance counts shown per status
- Tapping the count opens `EventAttendeesListSheet`
- Creator or group admin sees a **delete** icon
- If `status = going`, a local notification reminder is scheduled via `scheduleEventReminder()`

## Attendance flow

```
User taps "Going"
  → GroupEventsRepository.markAttendance(eventId, userId, 'going')
      → upsert group_event_attendees (onConflict: event_id,user_id)
      → scheduleEventReminder() — local notification before prayer time
User taps "Not going"
  → markAttendance(... 'not_going')
      → cancelEventReminder()
```

## Create event sheet

Admin or member posts a new event:
1. Select prayer type (segmented picker)
2. Pick date + time
3. Enter place
4. Optional note
5. Submit → `GroupEventController.createEvent()` → inserts into `group_events` → sends FCM notification to group topic

## Admin controls

Accessible from the `GroupDetailsScreen` action menu (admin only):
- **Edit group** — rename, change visibility
- **Share invite** — generates or shows existing invite code
- **Remove member** — calls `group_membership_remote_repository.removeMember()`
- **Delete group** — removes group and cascades members/events
