extends Node

var online := false
var initialized := false

func init() -> void:
    initialized = true

func set_online(value: bool) -> void:
    online = value

func is_online() -> bool:
    return online

func _daily_key() -> String:
    return Time.get_date_string_from_system()

func _sync_daily() -> void:
    var daily: Dictionary = SaveSystem.data["monetization"]["ads"]["daily"]
    var today := _daily_key()
    if str(daily.get("date", "")) != today:
        daily["date"] = today
        daily["revive_count"] = 0
        daily["double_coins_count"] = 0
        daily["bonus_coins_count"] = 0
        SaveSystem.save_now()

func can_show_rewarded(slot_id: String) -> bool:
    if not online:
        return false
    _sync_daily()
    var daily: Dictionary = SaveSystem.data["monetization"]["ads"]["daily"]
    var caps := {"revive":5, "double_coins":10, "bonus_coins":3}
    if not caps.has(slot_id):
        return false
    return int(daily.get(slot_id + "_count", 0)) < int(caps[slot_id])

func show_rewarded(slot_id: String, callback: Callable) -> void:
    if not can_show_rewarded(slot_id):
        callback.call(false)
        return
    # Production adapter is intentionally not fabricated in the core build.
    callback.call(false)
