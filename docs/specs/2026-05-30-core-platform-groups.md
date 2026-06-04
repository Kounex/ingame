---
spec: core-platform-groups
version: "1.0"
status: complete
last_updated: "2026-06-04"
sub_project: 1
---

# InGame -- Core Platform Groups Spec

> Part of the [InGame Product Roadmap](roadmap.md) and the [Core Platform overview](2026-05-30-core-platform-design.md)

## Scope

This spec covers the SP1 group-domain contract:
- groups and memberships
- invites and discoverability
- join requests
- RBAC
- group detail and settings behavior

## Core Data Models

### Group

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID | Primary key |
| `name` | VARCHAR | Required |
| `description` | TEXT | Nullable |
| `invite_code` | VARCHAR | Unique short alphanumeric code |
| `is_discoverable` | BOOLEAN | Default `false` |
| `join_mode` | VARCHAR | `open` or `approval`; relevant when discoverable |
| `avatar_url` | VARCHAR | Nullable |
| `created_by` | UUID | FK -> User |
| `created_at` | TIMESTAMP | Auto-set |
| `updated_at` | TIMESTAMP | Auto-updated |

### GroupMembership

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID | Primary key |
| `user_id` | UUID | FK -> User |
| `group_id` | UUID | FK -> Group |
| `role` | VARCHAR | `owner`, `admin`, `member` |
| `joined_at` | TIMESTAMP | Auto-set |
| Unique constraint | | (`user_id`, `group_id`) |

### JoinRequest

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID | Primary key |
| `user_id` | UUID | FK -> User |
| `group_id` | UUID | FK -> Group |
| `status` | VARCHAR | `pending`, `approved`, `denied` |
| `created_at` | TIMESTAMP | Auto-set |
| `resolved_by` | UUID | FK -> User, nullable |
| `resolved_at` | TIMESTAMP | Nullable |
| Unique constraint | | (`user_id`, `group_id`) where status is `pending` |

## RBAC Contract

Group roles use three levels:

| Role | Purpose |
|------|---------|
| `owner` | Final authority for the group; can manage admins and destructive group actions |
| `admin` | Trusted day-to-day group manager without ownership transfer or owner-only destructive powers |
| `member` | Standard participant |

### Action Matrix

| Action | Owner | Admin | Member |
|--------|-------|-------|--------|
| View group details and members | Yes | Yes | Yes |
| Open/share invite UI | Yes | Yes | Yes |
| Leave group | Yes, unless ownership transfer/delete is required first | Yes | Yes |
| Edit name / description / avatar | Yes | Yes | No |
| Change discoverability / join mode | Yes | Yes | No |
| View pending join requests | Yes | Yes | No |
| Approve / deny join requests | Yes | Yes | No |
| Remove non-owner members | Yes | Yes | No |
| Promote member to admin | Yes | No | No |
| Demote admin to member | Yes | No | No |
| Transfer ownership | Yes | No | No |
| Delete group | Yes | No | No |

### Enforcement Notes

- Backend authorization is the source of truth.
- Flutter should mirror the same matrix so unavailable actions are not shown.
- Membership is the minimum requirement for private group detail access.

### RBAC Endpoint Contract

- `PATCH /api/v1/groups/{group_id}/members/{user_id}/role` -- owner-only role change between `admin` and `member`; cannot target the current owner
- `POST /api/v1/groups/{group_id}/transfer-ownership` -- owner-only ownership transfer to an existing non-owner member
- `DELETE /api/v1/groups/{group_id}/leave` -- self-leave route; returns `403 group.owner_cannot_leave` while the caller is still the owner
- `DELETE /api/v1/groups/{group_id}/members/{user_id}` -- remove-member route for owner/admin moderation of non-owner members

## API Response Shapes

These response schemas are contract-sensitive for Flutter.

### GroupMemberResponse

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | Membership ID |
| `user_id` | UUID | FK -> User |
| `display_name` | String | Resolved from User |
| `avatar_url` | String? | Resolved from User |
| `role` | String | `owner`, `admin`, `member` |
| `joined_at` | DateTime | |

### JoinRequestResponse

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | Join request ID |
| `user` | Object | Nested `{id, display_name, avatar_url}` |
| `group_id` | UUID | FK -> Group |
| `status` | String | `pending`, `approved`, `denied` |
| `created_at` | DateTime | |
| `resolved_by` | UUID? | Admin/owner who resolved |
| `resolved_at` | DateTime? | |

## Group User Flows

### Create Group

`Home` -> `Create Group` -> enter name, description, avatar -> choose visibility -> choose join mode when discoverable -> create -> optional invite sharing

### Join Via Invite Link

Receive `https://in-game.app/join/{code}` -> native app or browser opens -> group preview -> if auth/onboarding is required, preserve the join target through those flows -> join -> refresh groups list -> open group detail

### Join Via Directory

`Discover` -> browse/search discoverable groups -> preview -> join instantly for `open` groups or send a join request for `approval` groups

### Group Detail

`Home` -> group card -> group detail with member list and group info

### Group Detail Actions

Overflow menu actions:
- `Invite`
- `Settings`
- `Leave Group`

Invite and leave remain available to all members. Settings remains role-aware.

### Join Request Approval

The group settings screen shows a `PENDING REQUESTS (N)` section between members and destructive controls. Each request shows:

- requester avatar
- display name
- relative timestamp
- approve action
- deny action with confirmation

Resolving a request refreshes the group detail.

## Discoverability Rules

- Private groups are not shown in discovery.
- Discoverable groups use `join_mode`:
  - `open` -> instant join
  - `approval` -> join request flow
- The discover endpoint excludes groups the current user already belongs to.

## Change Log

| Date | Section | What changed | Why |
|------|---------|--------------|-----|
| 2026-06-04 | Spec topology | Created a dedicated groups spec by extracting group, membership, RBAC, invite, and join-request contracts from the larger SP1 core-platform spec | Keeps group-domain behavior reviewable without forcing every SP1 update through one oversized spec |
