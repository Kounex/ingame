---
spec: real-time-coordination-models
version: "1.5"
status: complete
last_updated: "2026-06-06"
sub_project: 2
---

# InGame -- Real-Time Coordination Models Spec

> Part of the [InGame Product Roadmap](roadmap.md) and the [Real-Time Coordination overview](2026-05-30-real-time-coordination-design.md)

## Scope

This spec covers the shipped SP2 coordination models that build on the transport/presence foundation:
- scheduled ready windows
- calendar surface rules
- session scheduling
- activity feed and the delivered REST / WebSocket contracts for those surfaces

## Scheduled Ready Windows

### Model

A scheduled ready window is a future slot published by one member for one group, for example `today 20:00-23:00` or `Saturday all day`.

Rules:

- a member may publish multiple future windows at once
- each window must start in the future and end after it starts
- scheduled ready windows are not RSVP objects
- they do not imply that anyone else has committed to attend
- they complement the immediate `ready` toggle rather than replacing it
- calendar surfaces may combine these windows with SP1 recurring profile availability for comparison, but the datasets remain distinct

### Durable PostgreSQL Model

**ScheduledReadyWindow**

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID | Primary key |
| `group_id` | UUID | FK -> Group |
| `user_id` | UUID | FK -> User |
| `starts_at` | TIMESTAMP | Start of the published ready window |
| `ends_at` | TIMESTAMP | End of the published ready window |
| `source` | VARCHAR | `manual` for direct entry; room for future derived/imported variants |
| `created_at` | TIMESTAMP | Auto-set |
| `updated_at` | TIMESTAMP | Auto-updated |

### REST Contract

- `GET /api/v1/groups/{group_id}/scheduled-ready`
- `POST /api/v1/groups/{group_id}/scheduled-ready`
- `PATCH /api/v1/groups/{group_id}/scheduled-ready/{window_id}`
- `DELETE /api/v1/groups/{group_id}/scheduled-ready/{window_id}`

### WebSocket Contract

Server events:
- `scheduled_ready_updated`
- `scheduled_ready_deleted`

Mutations are REST-backed. WebSocket carries server fan-out after durable writes complete.

### Calendar Surface Rules

- the primary scheduled-ready surface in the shipped planning hub is an upcoming-first agenda preview rather than a blind week-by-week calendar browse
- the default hub view shows the next few upcoming windows in chronological order, grouped by day when needed, and exposes a remaining-count affordance when more windows exist beyond the preview
- grouped days in both the preview and the full agenda sheet use an emphasized day header plus clear separators so the list reads as chronological day clusters instead of a flat row stream
- the remaining-count affordance opens a full upcoming-windows agenda sheet that groups future windows by day and lets members create, edit, and remove only the windows they are authorized to manage from the same coordination surface
- a future filter or toggle may switch the same calendar into a recurring-availability comparison mode backed by SP1 `preferred_gaming_hours`
- recurring availability remains read-only inside that comparison surface unless the user explicitly navigates to profile editing

## Session Scheduling

### Model

Session scheduling is the explicit group planning layer: propose a future time slot, optionally add title/game/notes, and let members RSVP.

Rules:

- `cancelled` keeps a session visible in the planning model for coordination history and follow-through
- `delete` is a distinct destructive removal path for proposer/admin/owner cleanup when the session should disappear from active planner surfaces entirely
- deleting a session should still append a typed activity entry so the group feed preserves that it was removed

### Planner Surface Rules

- the default session card is a compact summary surface rather than a full interaction hub
- compact cards show identity, timing, status, RSVP totals by response type, and only a short notes preview
- tapping a session card opens a dedicated detail sheet for full notes, RSVP details, and the current user's RSVP controls
- edit and delete remain on the card overflow menu so management stays directly reachable without opening the detail sheet

### Durable PostgreSQL Model

**Session**

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID | Primary key |
| `group_id` | UUID | FK -> Group |
| `proposed_by` | UUID | FK -> User |
| `title` | VARCHAR | Optional short label |
| `game` | VARCHAR | Optional game name |
| `starts_at` | TIMESTAMP | Proposed session time |
| `notes` | TEXT | Optional |
| `status` | VARCHAR | `proposed`, `confirmed`, `cancelled` |
| `created_at` | TIMESTAMP | Auto-set |
| `updated_at` | TIMESTAMP | Auto-updated |

**SessionRsvp**

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID | Primary key |
| `session_id` | UUID | FK -> Session |
| `user_id` | UUID | FK -> User |
| `response` | VARCHAR | `in`, `out`, `maybe` |
| `updated_at` | TIMESTAMP | Auto-updated |
| Unique constraint | | `(session_id, user_id)` |

### REST Contract

- `GET /api/v1/groups/{group_id}/scheduled-ready`
- `GET /api/v1/groups/{group_id}/sessions`
- `GET /api/v1/groups/{group_id}/activity`
- `POST /api/v1/groups/{group_id}/scheduled-ready`
- `POST /api/v1/groups/{group_id}/sessions`
- `PATCH /api/v1/groups/{group_id}/scheduled-ready/{window_id}`
- `PATCH /api/v1/groups/{group_id}/sessions/{session_id}`
- `DELETE /api/v1/groups/{group_id}/scheduled-ready/{window_id}`
- `DELETE /api/v1/groups/{group_id}/sessions/{session_id}`
- `POST /api/v1/groups/{group_id}/sessions/{session_id}/rsvp`

### WebSocket Contract

Server events:
- `scheduled_ready_updated`
- `scheduled_ready_deleted`
- `session_proposed`
- `session_updated`
- `session_deleted`
- `session_rsvp_updated`
- `activity_recorded`

Mutations are REST-backed. WebSocket is the shared live-update channel for group members only after the durable REST write commits successfully.

## Activity Feed

### Model

Group activity is a lightweight chronological feed of coordination-relevant events for one group.

**GroupActivityEvent**

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID | Primary key |
| `group_id` | UUID | FK -> Group |
| `actor_user_id` | UUID | FK -> User |
| `type` | VARCHAR | e.g. `scheduled_ready_updated`, `scheduled_ready_deleted`, `session_proposed`, `session_deleted`, `session_rsvp_updated` |
| `message` | TEXT | Compatibility summary; maintained clients localize feed rows from typed event data |
| `session_id` | UUID? | Nullable FK -> Session |
| `scheduled_ready_window_id` | UUID? | Nullable FK -> ScheduledReadyWindow |
| `created_at` | TIMESTAMP | Auto-set |

### REST Contract

- `GET /api/v1/groups/{group_id}/activity`

### WebSocket Contract

Server events:
- `activity_recorded`

## Change Log

| Date | Section | What changed | Why |
|------|---------|--------------|-----|
| 2026-06-04 | Spec topology | Created a dedicated coordination-models spec by extracting scheduled-ready, calendar, and session-planning contracts from the larger SP2 realtime spec | Separates planned future coordination work from the active phase-1 transport contract so each can evolve without excess noise |
| 2026-06-05 | Delivered coordination slice | Marked the coordination models complete, documented the shipped activity model/feed, and clarified that durable scheduled-ready/session mutations are REST-backed with WebSocket server fan-out | Aligns the maintained SP2 contract with the implementation that now closes the gap between the earlier presence-only kickoff and the full coordination slice |
| 2026-06-05 | Audit follow-up contract polish | Added future-window validation, commit-before-fan-out wording, range-based calendar browsing, permission-aware edit affordances, and client-localized activity guidance | Keeps the coordination contract aligned with the corrected backend semantics and the upgraded shipped planning UX |
| 2026-06-06 | Session lifecycle and contracts | Added explicit session deletion semantics, the `DELETE /groups/{group_id}/sessions/{session_id}` REST route, the `session_deleted` websocket event, and the corresponding activity type | Distinguishes planner cleanup from status-based cancellation while keeping other group members in sync and preserving a feed trace that the session was removed |
| 2026-06-06 | Scheduled-ready browsing UX | Replaced the old week-range planning-hub browsing description with an upcoming-first preview plus a full agenda sheet for the remaining windows | Removes the blind week-by-week search flow while keeping the full upcoming list available in a more scannable secondary surface |
| 2026-06-06 | Coordination surface polish | Clarified that grouped ready-window days use emphasized headers and separators, and that session cards are compact summaries that open a richer RSVP/detail sheet | Keeps the shipped planner contract aligned with the latest scanability pass and the new separation between summary cards and detailed session interaction |
