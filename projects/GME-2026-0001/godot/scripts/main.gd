extends Node3D

@onready var player: StuntVehicle = $Player
@onready var world: StuntWorld = $World
@onready var score_label: Label = $HUD/TopBar/Score
@onready var currency_label: Label = $HUD/TopBar/Currency
@onready var speed_label: Label = $HUD/TopBar/Speed
@onready var status_label: Label = $HUD/Status

var run_time := 0.0
var best_score := 0
var touch_start := Vector2.ZERO
var touch_active := false

func _ready() -> void:
    world.setup(player)
    player.coin_collected.connect(_on_coin_collected)
    player.powerup_collected.connect(_on_powerup_collected)
    player.crashed.connect(_on_crashed)
    status_label.text = "GO!"
    _load_local_best()

func _process(delta: float) -> void:
    run_time += delta
    score_label.text = "SCORE  %07d" % player.score
    currency_label.text = "COINS %04d   💎 %03d   ⭐ %02d" % [player.coins, player.diamonds, player.star_gems]
    speed_label.text = "%02d KM/H" % int(abs(player.velocity.z) * 4.0)
    if player.score > best_score:
        best_score = player.score
        _save_local_best()

func _unhandled_input(event: InputEvent) -> void:
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
    status_label.text = "+COIN"

func _on_powerup_collected(kind: String) -> void:
    status_label.text = kind.to_upper()

func _on_crashed() -> void:
    status_label.text = "RECOVER!"
    player.score = max(0, player.score - 100)

func _save_local_best() -> void:
    var file := FileAccess.open("user://progress.json", FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify({"best_score": best_score}))

func _load_local_best() -> void:
    if not FileAccess.file_exists("user://progress.json"):
        return
    var file := FileAccess.open("user://progress.json", FileAccess.READ)
    if not file:
        return
    var parsed = JSON.parse_string(file.get_as_text())
    if parsed is Dictionary:
        best_score = int(parsed.get("best_score", 0))
