---
spec: core-platform-groups
version: "1.4"
status: complete
last_updated: "2026-06-06"
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
| `join_mode` | VARCHAR | `open` or `approval`; governs whether new members join instantly or must create a join request before becoming a member |
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

### GroupResponse

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | Group ID |
| `name` | String | Group display name |
| `description` | String? | Nullable group description |
| `invite_code` | String | Shareable invite code |
| `is_discoverable` | Boolean | Directory visibility |
| `join_mode` | String | `open` or `approval` |
| `avatar_url` | String? | Nullable group avatar |
| `created_by` | UUID | Owner user id |
| `created_at` | DateTime | |
| `updated_at` | DateTime? | |
| `member_count` | Int | Preview/member-count hint for list and invite surfaces |
| `has_pending_join_request` | Boolean | `true` when the authenticated viewer already has a pending request for this group; used by discover and invite-preview surfaces to render `Request Sent` from backend truth instead of widget-local state |

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

Receive `https://in-game.app/join/{code}` -> native app or browser opens -> group preview -> if auth/onboarding is required, preserve the join target through those flows -> join instantly for `open` groups or create a join request through the invite-code flow for `approval` groups -> refresh groups list and open group detail only after a real membership is created

### Join Via Directory

`Discover` -> browse/search discoverable groups -> preview -> join instantly for `open` groups or send a join request through the discoverable group id for `approval` groups

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
- Join requests are only valid for groups whose `join_mode` is `approval`; open groups reject request creation and expect direct joins instead.
- Private approval groups are requestable only through a valid invite-code preview flow, not by raw group id submission.
- A join request is single-use: once it has been approved or denied, later resolve attempts are rejected rather than mutating historical state.
- Approval must only create a membership when the requester is not already a member.

## Discoverability Rules

- Private groups are not shown in discovery.
- Invite-link and discover-entry joins both use `join_mode`:
  - `open` -> instant join
  - `approval` -> join request flow
- Raw group-id join-request creation is only valid for discoverable approval groups; private approval groups require a valid invite code.
- The discover endpoint excludes groups the current user already belongs to.
- Discoverable-group rows and invite previews expose whether the authenticated viewer already has a pending join request so approval CTAs stay disabled across refreshes and revisits.

## Change Log

| Date | Section | What changed | Why |
|------|---------|--------------|-----|
| 2026-06-04 | Spec topology | Created a dedicated groups spec by extracting group, membership, RBAC, invite, and join-request contracts from the larger SP1 core-platform spec | Keeps group-domain behavior reviewable without forcing every SP1 update through one oversized spec |
| 2026-06-06 | Join-mode enforcement | Clarified that `join_mode` governs invite-link joins as well as discovery, so approval groups create join requests instead of adding members directly | Closes the policy gap where invite previews already showed approval-required groups but the backend still allowed direct membership via invite code |
| 2026-06-06 | Join-request contract hardening | Documented that open groups reject join requests and that request resolution is single-use and cannot approve an already-member user | Keeps backend join-request behavior aligned with the maintained group contract and prevents stale-request state from mutating after approval |
| 2026-06-06 | Invite-scoped private requests | Clarified that private approval groups can only receive join requests through invite-code flows while discoverable approval groups may use raw group-id requests | Closes the private-group loophole where leaked UUIDs could create approval requests without an invite |
| 2026-06-06 | Pending-request preview state | Added `has_pending_join_request` to the maintained group response contract and documented that discover/invite preview surfaces render approval CTA state from backend truth | Prevents refresh/revisit regressions where `Request to Join` came back after a successful request because the UI only remembered local widget state |
