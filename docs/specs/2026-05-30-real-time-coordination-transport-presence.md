---
spec: real-time-coordination-transport-presence
version: "1.2"
status: complete
last_updated: "2026-06-06"
sub_project: 2
---

# InGame -- Real-Time Coordination Transport & Presence Spec

> Part of the [InGame Product Roadmap](roadmap.md) and the [Real-Time Coordination overview](2026-05-30-real-time-coordination-design.md)

## Scope

This spec covers the live transport and phase-1 presence contract for SP2:
- WebSocket transport behavior
- event envelope and naming rules
- derived connection presence
- group-scoped ready state
- Redis structures and fan-out rules
- bootstrap and reconnect behavior

## Transport Contract

### WebSocket Endpoint

- **Path:** `/api/v1/ws`
- **Auth:** JWT access token passed as `?token=<access_token>` for the current phase
- **Reconnect:** the client must re-read the latest access token before reconnecting
- **Server behavior:** reject missing or invalid token with a close code and reason

### Event Envelope

All server-to-client realtime events use one envelope shape:

```json
{
  "type": "ready_changed",
  "timestamp": "2026-06-01T20:15:00Z",
  "group_id": "uuid-if-group-scoped",
  "user_id": "uuid",
  "connection": "online",
  "ready": true,
  "ready_since": "1717268100",
  "ready_expires_at": "1717296900"
}
```

Only fields relevant to a given event type are populated. Group-scoped fan-out events include `group_id`.

### Naming Rules

- client-to-server commands use imperative names, for example `presence_lifecycle` and `ready_toggle`
- server-to-client events use past-tense names, for example `ready_changed` and `connection_changed`
- group-scoped fan-out events include `group_id`

## Presence Model

### Derived Connection Presence

- `online` -- authenticated WebSocket connected and client lifecycle is active
- `away` -- authenticated WebSocket connected and client reported background/inactive
- `offline` -- no active authenticated WebSocket connection

Connection presence is not user-set directly in phase 1.

### Group-Scoped Ready State

- `ready` is stored per `(group_id, user_id)`
- it is toggled explicitly by the user in group context
- it persists across disconnect until cleared manually or by the 8-hour fallback expiry
- while a user is offline, other members still render them as `ready` if the ready window is active

### Scheduled Ready Windows

Scheduled ready windows are a later SP2 concept and are documented in the coordination-models spec. They complement, but do not replace, the immediate `ready` toggle.

## Redis Structures

- `user:{id}:connection` -- hash `{state, since}` where `state` is `online` or `away`
- `group:{id}:online` -- set of currently connected user IDs
- `group:{id}:ready_users` -- set of user IDs currently marked ready in the group
- `group:{id}:ready:{user_id}` -- ready metadata `{since, expires_at}` with TTL aligned to the 8-hour fallback
- `group:{id}:events` -- pub/sub channel for fan-out

Expired ready keys are cleared lazily on read/snapshot and may also be swept periodically so connected clients receive `ready_changed` clear events.

## Bootstrap Strategy

When a client connects:

1. authenticate the user
2. load the user's group memberships from PostgreSQL
3. mark the user present in Redis group-online sets
4. send an initial `presence_snapshot` event to the connecting client for all relevant groups
5. broadcast `user_online` to other connected members

The snapshot payload contains, per group:

- members who are currently connected and/or currently ready, with derived `connection`
- group-scoped `ready`, `ready_since`, and `ready_expires_at` when applicable

Presence changes such as `user_online`, `user_offline`, and `connection_changed` must not emit a synthetic `ready_changed`. A `ready_changed` event represents only a real ready transition such as manual toggle, scheduled-ready start, manual clear, or expiry.

Example snapshot fragment:

```json
{
  "type": "presence_snapshot",
  "groups": [
    {
      "group_id": "uuid",
      "members": [
        {
          "user_id": "uuid",
          "connection": "online",
          "ready": true,
          "ready_since": "1717268100",
          "ready_expires_at": "1717296900"
        }
      ]
    }
  ]
}
```

## Multi-Replica Rule

- all broadcast-worthy events must be published to Redis
- each app replica must run a subscriber loop that consumes `group:{id}:events`
- subscriber loops must use a dedicated blocking Redis pub/sub connection instead of the generic request-path command timeout so idle fan-out reads do not churn on healthy replicas
- in-process broadcast may still be used for local delivery, but Redis publication is the source of cross-instance propagation

## WebSocket Commands (Phase 1)

### Client -> Server

- `presence_lifecycle` -- `{ "type": "presence_lifecycle", "state": "active" | "away" }`
- `ready_toggle` -- `{ "type": "ready_toggle", "group_id": "uuid", "ready": true | false }`

The legacy `status_change` command is not part of phase 1 and must not be used for derived presence.

### Server -> Client

- `presence_snapshot`
- `user_online`
- `user_offline`
- `connection_changed`
- `ready_changed`

## Change Log

| Date | Section | What changed | Why |
|------|---------|--------------|-----|
| 2026-06-04 | Spec topology | Created a dedicated transport-and-presence spec by extracting the live transport, Redis, bootstrap, command, and phase-1 presence rules from the larger SP2 realtime spec | Keeps the most contract-sensitive realtime behavior focused and easier to update during phase-1 delivery |
| 2026-06-06 | Multi-replica rule | Required replica subscriber loops to use a dedicated blocking Redis pub/sub connection instead of the generic command timeout | Prevents idle pub/sub reads from failing on healthy Redis replicas and breaking cross-instance websocket fan-out |
| 2026-06-06 | Completion status sync | Marked the transport-and-presence child spec complete to match the shipped SP2 overview and roadmap state | Removes stale in-progress metadata now that the presence-first transport slice is part of the delivered realtime coordination set |
