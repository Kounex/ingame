from app.notifications.copy import build_notification_copy


def test_ready_changed():
    title, body = build_notification_copy(
        event_type="ready_changed",
        actor_name="Alex",
        group_name="Friday Gamers",
    )
    assert title == "Alex is ready to play"
    assert body == "Alex is ready in Friday Gamers"


def test_session_proposed():
    title, body = build_notification_copy(
        event_type="session_proposed",
        actor_name="Alex",
        group_name="Friday Gamers",
        session_title="Valorant Night",
        formatted_time="Tomorrow at 8 PM",
    )
    assert title == "New session in Friday Gamers"
    assert body == "Alex proposed: Valorant Night — Tomorrow at 8 PM"


def test_session_proposed_with_game_fallback():
    title, body = build_notification_copy(
        event_type="session_proposed",
        actor_name="Alex",
        group_name="Friday Gamers",
        game="Valorant",
        formatted_time="Tomorrow at 8 PM",
    )
    assert body == "Alex proposed: Valorant — Tomorrow at 8 PM"


def test_session_updated():
    title, body = build_notification_copy(
        event_type="session_updated",
        actor_name="Alex",
        group_name="Friday Gamers",
        session_title="Valorant Night",
    )
    assert title == "Session updated in Friday Gamers"
    assert body == "Alex updated: Valorant Night"


def test_session_rsvp_updated():
    title, body = build_notification_copy(
        event_type="session_rsvp_updated",
        actor_name="Alex",
        group_name="Friday Gamers",
        rsvp_response="in",
        session_title="Valorant Night",
    )
    assert title == "RSVP update in Friday Gamers"
    assert body == "Alex is now in for Valorant Night"


def test_join_request_pending():
    title, body = build_notification_copy(
        event_type="join_request_pending",
        actor_name="Alex",
        group_name="Friday Gamers",
    )
    assert title == "Join request in Friday Gamers"
    assert body == "Alex wants to join Friday Gamers"


def test_unknown_event_type():
    title, body = build_notification_copy(
        event_type="unknown_event",
        actor_name="Alex",
        group_name="Friday Gamers",
    )
    assert title == "Activity in Friday Gamers"
    assert body == "New activity from Alex"
