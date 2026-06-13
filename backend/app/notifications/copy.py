def build_notification_copy(
    *,
    event_type: str,
    actor_name: str,
    group_name: str,
    session_title: str | None = None,
    game: str | None = None,
    formatted_time: str | None = None,
    rsvp_response: str | None = None,
) -> tuple[str, str]:
    label = session_title or game or "a session"

    if event_type == "ready_changed":
        return (
            f"{actor_name} is ready to play",
            f"{actor_name} is ready in {group_name}",
        )

    if event_type == "session_proposed":
        time_part = f" — {formatted_time}" if formatted_time else ""
        return (
            f"New session in {group_name}",
            f"{actor_name} proposed: {label}{time_part}",
        )

    if event_type == "session_updated":
        return (
            f"Session updated in {group_name}",
            f"{actor_name} updated: {label}",
        )

    if event_type == "session_rsvp_updated":
        return (
            f"RSVP update in {group_name}",
            f"{actor_name} is now {rsvp_response} for {label}",
        )

    if event_type == "join_request_pending":
        return (
            f"Join request in {group_name}",
            f"{actor_name} wants to join {group_name}",
        )

    return (
        f"Activity in {group_name}",
        f"New activity from {actor_name}",
    )
