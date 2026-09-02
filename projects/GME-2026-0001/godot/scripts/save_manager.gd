extends Node
class_name SaveManager

const SAVE_PATH := "user://blocky_ramp_rush_save.json"
const SCHEMA_VERSION := 1

func save_profile(profile: Dictionary) -> bool:
    var payload := {
        "schema_version": SCHEMA_VERSION,
        "saved_at": Time.get_datetime_string_from_system(true),
        "profile": profile,
    }
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(payload))
    return true

func load_profile(default_profile: Dictionary) -> Dictionary:
    if not FileAccess.file_exists(SAVE_PATH):
        return default_profile.duplicate(true)
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return default_profile.duplicate(true)
    var parsed = JSON.parse_string(file.get_as_text())
    if not parsed is Dictionary:
        return default_profile.duplicate(true)
    var profile = parsed.get("profile", {})
    return profile if profile is Dictionary else default_profile.duplicate(true)
