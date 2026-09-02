extends Node
class_name ModeController

enum Mode { ENDLESS_RAMP_RUN, STUNT_CHALLENGE, GARAGE_BUILDER, ARENA_BATTLE }

var current_mode: Mode = Mode.ENDLESS_RAMP_RUN
var current_world := "new_york_city_rush"
var unlocked_worlds := {
    "new_york_city_rush": true,
    "dubai_desert_drift": false,
    "singapore_garden_run": false,
    "london_fog_ramp": false,
    "tokyo_neon_nights": false,
    "space_station": false,
}

signal mode_changed(mode: Mode)
signal world_changed(world_id: String)

func set_mode(mode: Mode) -> void:
    current_mode = mode
    mode_changed.emit(mode)

func set_world(world_id: String) -> bool:
    if not unlocked_worlds.get(world_id, false):
        return false
    current_world = world_id
    world_changed.emit(world_id)
    return true

func unlock_world(world_id: String) -> void:
    if world_id in unlocked_worlds:
        unlocked_worlds[world_id] = true
