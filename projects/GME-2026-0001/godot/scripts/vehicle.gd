extends CharacterBody3D
class_name StuntVehicle

@export var forward_speed := 18.0
@export var boost_speed := 34.0
@export var lane_width := 4.0
@export var lane_change_speed := 12.0
@export var jump_velocity := 9.0
@export var gravity := 18.0

var lane := 1
var boosting := false
var score := 0
var coins := 0
var diamonds := 0
var star_gems := 0

signal coin_collected(amount: int)
signal powerup_collected(kind: String)
signal crashed

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = -0.1

    var target_x := (lane - 1) * lane_width
    global_position.x = move_toward(global_position.x, target_x, lane_change_speed * delta)
    velocity.z = -(boost_speed if boosting else forward_speed)
    move_and_slide()

    if global_position.y < -12.0:
        crashed.emit()
        global_position = Vector3(0.0, 2.0, 4.0)
        velocity = Vector3.ZERO
        lane = 1

func move_left() -> void:
    lane = clampi(lane - 1, 0, 2)

func move_right() -> void:
    lane = clampi(lane + 1, 0, 2)

func jump() -> void:
    if is_on_floor():
        velocity.y = jump_velocity
        score += 25

func set_boost(active: bool) -> void:
    boosting = active

func add_coin(amount := 1) -> void:
    coins += amount
    score += amount * 10
    coin_collected.emit(amount)

func add_diamond(amount := 1) -> void:
    diamonds += amount
    score += amount * 100

func add_star_gem(amount := 1) -> void:
    star_gems += amount
    score += amount * 500

func use_powerup(kind: String) -> void:
    powerup_collected.emit(kind)
    match kind:
        "boost":
            set_boost(true)
            await get_tree().create_timer(3.0).timeout
            set_boost(false)
        "shield":
            score += 50
        "multiplier":
            score += 100
