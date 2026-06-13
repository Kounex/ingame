import uuid
from datetime import time


def should_notify(
    *,
    user_id: uuid.UUID,
    actor_user_id: uuid.UUID,
    event_type: str,
    preference_enabled: bool,
    group_muted: bool,
    conditions: dict | None,
    context: dict,
    quiet_hours: dict | None,
    now_hour: int | None = None,
    now_minute: int | None = None,
) -> bool:
    if user_id == actor_user_id:
        return False

    if group_muted:
        return False

    if not preference_enabled:
        return False

    if not evaluate_conditions(conditions=conditions, context=context):
        return False

    if quiet_hours is not None:
        from datetime import datetime, timezone as tz
        now = datetime.now(tz.utc)
        h = now_hour if now_hour is not None else now.hour
        m = now_minute if now_minute is not None else now.minute
        if is_in_quiet_hours(
            start=quiet_hours["start"],
            end=quiet_hours["end"],
            tz_name=quiet_hours.get("tz", "UTC"),
            check_hour=h,
            check_minute=m,
        ):
            return False

    return True


def evaluate_conditions(
    *, conditions: dict | None, context: dict
) -> bool:
    if conditions is None:
        return True

    if "only_if_rsvp" in conditions:
        user_rsvp = context.get("user_rsvp")
        if user_rsvp not in conditions["only_if_rsvp"]:
            return False

    if "only_if_role" in conditions:
        user_role = context.get("user_role")
        if user_role not in conditions["only_if_role"]:
            return False

    if "min_rsvp_count" in conditions:
        positive_count = context.get("positive_rsvp_count", 0)
        if positive_count < conditions["min_rsvp_count"]:
            return False

    return True


def is_in_quiet_hours(
    *,
    start: time,
    end: time,
    tz_name: str,
    check_hour: int,
    check_minute: int,
) -> bool:
    check = time(check_hour, check_minute)

    if start <= end:
        return start <= check < end
    else:
        return check >= start or check < end
