extends Node3D

@onready var player: StuntVehicle = $Player
@onready var world: StuntWorld = $World
@onready var mode_controller: ModeController = $ModeController
@onready var save_manager: SaveManager = $SaveManager
@onready var score_label: Label = $HUD/TopBar/Score
@onready var currency_label: Label = $HUD/TopBar/Currency
@onready var speed_label: Label = $HUD/TopBar/Speed
@onready var status_label: Label = $HUD/Status

var run_time := 0.0
var best_score := 0
var touch_start := Vector2.ZERO
var touch_active := false
var profile := {
    "coins": 0,
    "diamonds": 0,
    "star_gems": 0,
    "best_score": 0,
    "level": 1,
    "unlocked_worlds": ["new_york_city_rush"],
    "selected_vehicle": "Blocky Buggy"
}

func _ready() -> void:
    world.setup(player)
    player.coin_collected.connect(_on_coin_collected)
    player.powerup_collected.connect(_on_powerup_collected)
    player.crashed.connect(_on_crashed)
    mode_controller.mode_changed.connect(_on_mode_changed)
    mode_controller.world_changed.connect(_on_world_changed)
    profile = save_manager.load_profile(profile)
    best_score = int(profile.get("best_score", 0))
    status_label.text = "ENDLESS RAMP RUN"

func _process(delta: float) -> void:
    run_time += delta
    score_label.text = "SCORE  %07d" % player.score
    currency_label.text = "COINS %04d   DIAMONDS %03d   STARS %02d" % [player.coins, player.diamonds, player.star_gems]
    speed_label.text = "%02d KM/H" % int(abs(player.velocity.z) * 4.0)
    if player.score > best_score:
        best_score = player.score
        profile["best_score"] = best_score
        _save_profile()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_1: mode_controller.set_mode(ModeController.Mode.ENDLESS_RAMP_RUN)
            KEY_2: mode_controller.set_mode(ModeController.Mode.STUNT_CHALLENGE)
            KEY_3: mode_controller.set_mode(ModeController.Mode.GARAGE_BUILDER)
            KEY_4: mode_controller.set_mode(ModeController.Mode.ARENA_BATTLE)
    if event.is_action_pressed("move_left"):
        player.move_left()
    elif event.is_action_pressed("move_right"):
        player.move_right()
    elif event.is_action_pressed("jump"):
        player.jump()
    elif event.is_action_pressed("boost"):
        player.set_boost(true)
        get_tree().create_timer(2.0).timeout.connect(func(): player.set_boost(false))
    elif event.is_action_pressed("powerup"):
        player.use_powerup("boost")
    elif event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        if touch.pressed:
            touch_start = touch.position
            touch_active = true
        elif touch_active:
            _handle_swipe(touch.position - touch_start)
            touch_active = false
    elif event is InputEventScreenDrag and touch_active:
        var drag := event as InputEventScreenDrag
        if drag.relative.length() > 40.0:
            _handle_swipe(drag.relative)
            touch_active = false

func _handle_swipe(delta: Vector2) -> void:
    if abs(delta.x) > abs(delta.y):
        if delta.x > 0:
            player.move_right()
        else:
            player.move_left()
    elif delta.y < 0:
        player.jump()
    else:
        player.set_boost(false)

func _on_coin_collected(_amount: int) -> void:
    profile["coins"] = int(profile.get("coins", 0)) + 1
    status_label.text = "+COIN"

func _on_powerup_collected(kind: String) -> void:
    status_label.text = kind.to_upper()

func _on_crashed() -> void:
    status_label.text = "RECOVER!"
    player.score = max(0, player.score - 100)

func _on_mode_changed(mode: ModeController.Mode) -> void:
    var names := ["ENDLESS RAMP RUN", "STUNT CHALLENGE", "GARAGE BUILDER", "ARENA BATTLE"]
    status_label.text = names[int(mode)]

func _on_world_changed(world_id: String) -> void:
    status_label.text = world_id.replace("_", " ").to_upper()

func _save_profile() -> void:
    profile["best_score"] = best_score
    profile["coins"] = player.coins
    profile["diamonds"] = player.diamonds
    profile["star_gems"] = player.star_gems
    save_manager.save_profile(profile)
