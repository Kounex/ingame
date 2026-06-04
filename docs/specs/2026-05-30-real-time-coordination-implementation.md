---
spec: real-time-coordination-implementation
version: "1.1"
status: in-progress
last_updated: "2026-06-04"
sub_project: 2
---

# InGame -- Real-Time Coordination Implementation Spec

> Part of the [InGame Product Roadmap](roadmap.md) and the [Real-Time Coordination overview](2026-05-30-real-time-coordination-design.md)

## Scope

This spec covers the implementation-facing SP2 details:
- Flutter providers and UI integration
- backend responsibilities
- testing expectations
- deployment notes

## Flutter Architecture

### Providers

- `websocketConnectionProvider` owns authenticated socket lifecycle
- `websocketConnectionStateProvider` exposes client transport state: `disconnected`, `connecting`, `connected`
- `WebSocketClient` caches the latest `presence_snapshot` for the current connection because the event stream is broadcast and non-replay
- `presenceNotifierProvider` hydrates from that cache on build so bootstrap cannot be lost when the listener attaches after connect
- `WebSocketClient.connect()` attaches the stream listener before awaiting `channel.ready` and only marks transport `connected` after the handshake succeeds
- `presenceNotifierProvider` watches `websocketConnectionStateProvider` so it re-hydrates from the cached bootstrap snapshot when transport reaches `connected`
- `presenceNotifierProvider` normalizes legacy pre-SP2 snapshot payloads (`statuses[].state`, `online_user_ids`) alongside the canonical `members[].connection` shape during backend rollout
- `presenceNotifierProvider` stores per-group member presence derived from snapshot plus events, including expiry-aware ready state
- `presenceLifecycleProvider` sends lifecycle-derived away and active transitions
- REST bootstrap providers remain responsible for initial group and member fetches
- current-user membership mutations that change group scope (`create`, open `join`, `leave`) must refresh the authenticated WebSocket session so the next `presence_snapshot` is scoped to the latest memberships

### UI Integration

- `StatusIndicator` remains the canonical readiness signal
- group member rows use a single live-status composition built from `UserAvatar` plus `StatusIndicator`
- group detail screens expose a group-scoped ready toggle for the current user
- the toggle is disabled unless the WebSocket is `connected`
- the toggle shows reconnect and offline hints when needed
- `toggleReady` rejects commands that cannot be delivered; there is no optimistic ready flip while disconnected
- member surfaces app-wide consume `groupMemberStatusProvider` rather than computing status locally
- later SP2 group surfaces may expose a calendar that can switch between scheduled-ready windows and recurring profile-availability comparison without collapsing those concepts into one model

### Configuration

- REST and WebSocket base URLs must be environment-configurable
- local dev may default to localhost
- deployed builds must support `https` plus `wss`

## Backend Responsibilities

### REST (Phase 1)

- no new session endpoints in phase 1
- existing group and member REST endpoints continue to bootstrap static group context

### WebSocket

- authenticate and attach the user to group scopes
- accept lifecycle and ready-toggle commands
- persist derived connection presence and group-scoped ready state to Redis
- publish fan-out events to Redis channels
- broadcast locally to sockets connected on the same replica
- enforce ready expiry lazily on read and snapshot paths plus lightweight sweeps

## Testing Strategy

### Backend

- WebSocket auth tests: missing, invalid, and valid token
- WebSocket lifecycle tests: connect, disconnect, reconnect
- Redis-backed fan-out tests: event published once and delivered across the subscriber path
- presence snapshot tests: joining client receives expected bootstrap payload with connection and ready metadata
- ready toggle tests: group-scoped ready on and off fan-out
- lifecycle tests: background and resume transitions emit `connection_changed`
- ready expiry tests: stale ready clears and fan-out reflects the cleared state
- reconnect tests: offline-but-ready members remain present in snapshots without an extra reconnect `ready_changed`

### Flutter

- `WebSocketClient` tests: connect, decode, disconnect, reconnect with fresh token, command send helpers, connection-state transitions, `channel.ready` gating, snapshot cache for late subscribers, and cache clear on disconnect
- provider tests: auth transition connect/disconnect, snapshot merge, bootstrap hydration, legacy snapshot normalization, offline-ready hydration, ready updates, ready expiry, lifecycle-derived away handling, ready-first status derivation, connection-state sync, and ready-toggle rejection while disconnected or reconnecting
- widget tests: member list and status rendering from live provider state
- integration tests remain planned for a full login -> open group -> receive live ready change path

### CI Requirements

- `flutter analyze`
- `flutter test`
- backend test suite
- spec freshness check
- API/spec validation
- realtime tests must run in CI before SP2 phase 1 is considered complete

## Deployment Notes

- staging and production run multiple replicas and therefore require Redis subscriber fan-out
- health checks should evolve to include realtime dependencies where feasible
- production WebSocket traffic must use `wss://`

## Change Log

| Date | Section | What changed | Why |
|------|---------|--------------|-----|
| 2026-06-04 | Spec topology | Created a dedicated implementation spec by extracting Flutter architecture, backend responsibilities, testing expectations, and deployment notes from the larger SP2 realtime spec | Keeps delivery-oriented details together without mixing them into the core transport or future coordination model contracts |
| 2026-06-04 | Membership refresh reconnect | Documented that current-user group membership mutations must refresh the authenticated WebSocket session so presence bootstrap rehydrates against the new group scope | Keeps realtime presence aligned immediately after group create/join/leave instead of waiting for a full relog |
