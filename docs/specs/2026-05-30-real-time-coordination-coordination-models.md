---
spec: real-time-coordination-models
version: "1.0"
status: planned
last_updated: "2026-06-04"
sub_project: 2
---

# InGame -- Real-Time Coordination Models Spec

> Part of the [InGame Product Roadmap](roadmap.md) and the [Real-Time Coordination overview](2026-05-30-real-time-coordination-design.md)

## Scope

This spec covers the planned SP2 coordination models that build on the phase-1 transport foundation:
- scheduled ready windows
- calendar surface rules
- session scheduling
- planned REST and WebSocket contracts for those future surfaces

## Scheduled Ready Windows

### Model

A scheduled ready window is a future slot published by one member for one group, for example `today 20:00-23:00` or `Saturday all day`.

Rules:

- a member may publish multiple future windows at once
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

### Planned REST Contract

- `GET /api/v1/groups/{group_id}/scheduled-ready`
- `POST /api/v1/groups/{group_id}/scheduled-ready`
- `PATCH /api/v1/groups/{group_id}/scheduled-ready/{window_id}`
- `DELETE /api/v1/groups/{group_id}/scheduled-ready/{window_id}`

### Planned WebSocket Contract

Client commands:
- `scheduled_ready_upsert`
- `scheduled_ready_delete`

Server events:
- `scheduled_ready_updated`
- `scheduled_ready_deleted`

### Calendar Surface Rules

- the primary group calendar view shows scheduled ready windows for all visible members in the selected time range
- a filter or toggle may switch the same calendar into a recurring-availability comparison mode backed by SP1 `preferred_gaming_hours`
- recurring availability is read-only inside that comparison surface unless the user explicitly navigates to profile editing

## Session Scheduling

### Model

Session scheduling is the explicit group planning layer: propose a future time slot, optionally add title/game/notes, and let members RSVP.

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

### Planned REST Contract

- `GET /api/v1/groups/{group_id}/presence`
- `GET /api/v1/groups/{group_id}/scheduled-ready`
- `GET /api/v1/groups/{group_id}/sessions`
- `POST /api/v1/groups/{group_id}/scheduled-ready`
- `POST /api/v1/groups/{group_id}/sessions`
- `PATCH /api/v1/groups/{group_id}/scheduled-ready/{window_id}`
- `PATCH /api/v1/groups/{group_id}/sessions/{session_id}`
- `DELETE /api/v1/groups/{group_id}/scheduled-ready/{window_id}`
- `POST /api/v1/groups/{group_id}/sessions/{session_id}/rsvp`

### Planned WebSocket Contract

Client commands:
- `scheduled_ready_upsert`
- `scheduled_ready_delete`
- `session_propose`
- `session_update`
- `session_rsvp`

Server events:
- `scheduled_ready_updated`
- `scheduled_ready_deleted`
- `session_proposed`
- `session_updated`
- `session_rsvp_updated`

## Change Log

| Date | Section | What changed | Why |
|------|---------|--------------|-----|
| 2026-06-04 | Spec topology | Created a dedicated coordination-models spec by extracting scheduled-ready, calendar, and session-planning contracts from the larger SP2 realtime spec | Separates planned future coordination work from the active phase-1 transport contract so each can evolve without excess noise |
