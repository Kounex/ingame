import uuid
from datetime import time

import pytest

from app.notifications.evaluator import (
    evaluate_conditions,
    is_in_quiet_hours,
    should_notify,
)


def test_skip_actor():
    actor_id = uuid.uuid4()
    assert should_notify(
        user_id=actor_id,
        actor_user_id=actor_id,
        event_type="session_proposed",
        preference_enabled=True,
        group_muted=False,
        conditions=None,
        context={},
        quiet_hours=None,
    ) is False


def test_group_muted():
    assert should_notify(
        user_id=uuid.uuid4(),
        actor_user_id=uuid.uuid4(),
        event_type="session_proposed",
        preference_enabled=True,
        group_muted=True,
        conditions=None,
        context={},
        quiet_hours=None,
    ) is False


def test_event_type_disabled():
    assert should_notify(
        user_id=uuid.uuid4(),
        actor_user_id=uuid.uuid4(),
        event_type="session_proposed",
        preference_enabled=False,
        group_muted=False,
        conditions=None,
        context={},
        quiet_hours=None,
    ) is False


def test_allowed_when_enabled():
    assert should_notify(
        user_id=uuid.uuid4(),
        actor_user_id=uuid.uuid4(),
        event_type="session_proposed",
        preference_enabled=True,
        group_muted=False,
        conditions=None,
        context={},
        quiet_hours=None,
    ) is True


def test_conditions_only_if_rsvp_match():
    assert evaluate_conditions(
        conditions={"only_if_rsvp": ["in", "maybe"]},
        context={"user_rsvp": "in"},
    ) is True


def test_conditions_only_if_rsvp_no_match():
    assert evaluate_conditions(
        conditions={"only_if_rsvp": ["in", "maybe"]},
        context={"user_rsvp": "out"},
    ) is False


def test_conditions_only_if_rsvp_no_rsvp():
    assert evaluate_conditions(
        conditions={"only_if_rsvp": ["in", "maybe"]},
        context={},
    ) is False


def test_conditions_only_if_role_match():
    assert evaluate_conditions(
        conditions={"only_if_role": ["owner", "admin"]},
        context={"user_role": "owner"},
    ) is True


def test_conditions_only_if_role_no_match():
    assert evaluate_conditions(
        conditions={"only_if_role": ["owner", "admin"]},
        context={"user_role": "member"},
    ) is False


def test_conditions_min_rsvp_count_met():
    assert evaluate_conditions(
        conditions={"min_rsvp_count": 3},
        context={"positive_rsvp_count": 5},
    ) is True


def test_conditions_min_rsvp_count_not_met():
    assert evaluate_conditions(
        conditions={"min_rsvp_count": 3},
        context={"positive_rsvp_count": 1},
    ) is False


def test_conditions_unknown_key_ignored():
    assert evaluate_conditions(
        conditions={"future_condition": "whatever"},
        context={},
    ) is True


def test_conditions_none():
    assert evaluate_conditions(conditions=None, context={}) is True


def test_quiet_hours_inside():
    assert is_in_quiet_hours(
        start=time(22, 0),
        end=time(8, 0),
        tz_name="UTC",
        check_hour=23,
        check_minute=30,
    ) is True


def test_quiet_hours_outside():
    assert is_in_quiet_hours(
        start=time(22, 0),
        end=time(8, 0),
        tz_name="UTC",
        check_hour=12,
        check_minute=0,
    ) is False


def test_quiet_hours_same_day_range():
    assert is_in_quiet_hours(
        start=time(9, 0),
        end=time(17, 0),
        tz_name="UTC",
        check_hour=12,
        check_minute=0,
    ) is True


def test_should_notify_with_quiet_hours_blocked():
    assert should_notify(
        user_id=uuid.uuid4(),
        actor_user_id=uuid.uuid4(),
        event_type="session_proposed",
        preference_enabled=True,
        group_muted=False,
        conditions=None,
        context={},
        quiet_hours={"start": time(22, 0), "end": time(8, 0), "tz": "UTC"},
        now_hour=23,
        now_minute=30,
    ) is False


def test_should_notify_with_conditions_blocking():
    assert should_notify(
        user_id=uuid.uuid4(),
        actor_user_id=uuid.uuid4(),
        event_type="session_updated",
        preference_enabled=True,
        group_muted=False,
        conditions={"only_if_rsvp": ["in", "maybe"]},
        context={"user_rsvp": "out"},
        quiet_hours=None,
    ) is False
