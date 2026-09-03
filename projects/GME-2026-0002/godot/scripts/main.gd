extends Node3D

const BOARD_SIZE := 12.0
const PLAYABLE_HALF := 4.65
const POCKET_RADIUS := 0.62
const COIN_RADIUS := 0.27
const COIN_HEIGHT := 0.14
const STRIKER_RADIUS := 0.38
const STRIKER_Z := 4.15
const MAX_SHOT_DISTANCE := 4.5
const MIN_SHOT_POWER := 16.0
const MAX_SHOT_POWER := 62.0
const SAVE_PATH := "user://pocket_board_3d.json"

var board_root: Node3D
var pieces_root: Node3D
var striker: RigidBody3D
var camera: Camera3D
var aim_line: MeshInstance3D
var aim_marker: MeshInstance3D
var status_label: Label
var score_label: Label
var turn_label: Label
var mode_label: Label
var round_label: Label
var best_label: Label

var pieces: Array[RigidBody3D] = []
var current_player := 1
var scores := [0, 0]
var round_number := 1
var shots := 0
var aiming := false
var aim_world := Vector3.ZERO
var shot_active := false
var settle_time := 0.0
var best_score := 0
var rng := RandomNumberGenerator.new()

var mat_board: StandardMaterial3D
var mat_rail: StandardMaterial3D
var mat_dark: StandardMaterial3D
var mat_light: StandardMaterial3D
var mat_queen: StandardMaterial3D
var mat_striker: StandardMaterial3D
var mat_gold: StandardMaterial3D

func _ready() -> void:
    rng.randomize()
    _make_materials()
    _build_environment()
    _build_board()
    _build_camera()
    _build_ui()
    _load_save()
    _start_round()

func _process(_delta: float) -> void:
    _update_hud()
    _update_aim_visuals()

func _physics_process(delta: float) -> void:
    _process_pockets()
    if shot_active and _all_pieces_stopped():
        settle_time += delta
        if settle_time >= 0.55:
            shot_active = false
            settle_time = 0.0
            _finish_turn()
    else:
        settle_time = 0.0

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("reset_game"):
        _reset_match()
        return
    if event.is_action_pressed("new_round"):
        _start_round()
        return

    if event is InputEventMouseButton:
        var mouse := event as InputEventMouseButton
        if mouse.button_index == MOUSE_BUTTON_LEFT:
            if mouse.pressed:
                if _can_shoot():
                    aiming = true
                    aim_world = _screen_to_board(mouse.position)
            else:
                if aiming:
                    aiming = false
                    _shoot(aim_world)
        return

    if event is InputEventMouseMotion and aiming:
        aim_world = _screen_to_board((event as InputEventMouseMotion).position)
        return

    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        if touch.pressed:
            if _can_shoot():
                aiming = true
                aim_world = _screen_to_board(touch.position)
        elif aiming:
            aiming = false
            _shoot(_screen_to_board(touch.position))
        return

    if event is InputEventScreenDrag and aiming:
        aim_world = _screen_to_board((event as InputEventScreenDrag).position)

func _make_materials() -> void:
    mat_board = _material(Color("d8a55f"), 0.0, 0.6)
    mat_rail = _material(Color("5a2e18"), 0.1, 0.42)
    mat_dark = _material(Color("1c1714"), 0.05, 0.5)
    mat_light = _material(Color("f6f1e5"), 0.0, 0.42)
    mat_queen = _material(Color("c93b38"), 0.08, 0.35)
    mat_striker = _material(Color("dbe7ff"), 0.22, 0.25)
    mat_gold = _material(Color("e8c44b"), 0.18, 0.24)

func _material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = metallic
    material.roughness = roughness
    return material

func _build_environment() -> void:
    var env_node := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("21150f")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("c9b6a0")
    environment.ambient_light_energy = 0.65
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env_node.environment = environment
    add_child(env_node)

    var key := DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
    key.light_energy = 1.2
    key.shadow_enabled = true
    add_child(key)

    var fill := DirectionalLight3D.new()
    fill.rotation_degrees = Vector3(-25.0, 152.0, 0.0)
    fill.light_energy = 0.35
    add_child(fill)

func _build_board() -> void:
    board_root = Node3D.new()
    board_root.name = "Board"
    add_child(board_root)

    pieces_root = Node3D.new()
    pieces_root.name = "Pieces"
    add_child(pieces_root)

    _add_static_box(Vector3(BOARD_SIZE, 0.45, BOARD_SIZE), Vector3(0, -0.28, 0), mat_rail, Vector3(BOARD_SIZE, 0.45, BOARD_SIZE))
    _add_static_box(Vector3(11.0, 0.26, 0.42), Vector3(0, 0.18, -5.22), mat_rail, Vector3(11.0, 0.26, 0.42))
    _add_static_box(Vector3(11.0, 0.26, 0.42), Vector3(0, 0.18, 5.22), mat_rail, Vector3(11.0, 0.26, 0.42))
    _add_static_box(Vector3(0.42, 0.26, 11.0), Vector3(-5.22, 0.18, 0), mat_rail, Vector3(0.42, 0.26, 11.0))
    _add_static_box(Vector3(0.42, 0.26, 11.0), Vector3(5.22, 0.18, 0), mat_rail, Vector3(0.42, 0.26, 11.0))

    var surface := MeshInstance3D.new()
    var board_mesh := BoxMesh.new()
    board_mesh.size = Vector3(10.2, 0.12, 10.2)
    surface.mesh = board_mesh
    surface.material_override = mat_board
    surface.position = Vector3(0, 0.0, 0)
    board_root.add_child(surface)

    _add_decorative_marks()
    _add_pockets()
    _add_baseline()

func _add_static_box(_ignored_size: Vector3, pos: Vector3, material: Material, collision_size: Vector3) -> void:
    var body := StaticBody3D.new()
    body.position = pos
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = collision_size
    mesh.mesh = box
    mesh.material_override = material
    body.add_child(mesh)
    var shape := CollisionShape3D.new()
    var box_shape := BoxShape3D.new()
    box_shape.size = collision_size
    shape.shape = box_shape
    body.add_child(shape)
    board_root.add_child(body)

func _add_decorative_marks() -> void:
    var center_ring := MeshInstance3D.new()
    var torus := TorusMesh.new()
    torus.inner_radius = 1.05
    torus.outer_radius = 1.10
    torus.rings = 48
    torus.ring_segments = 12
    center_ring.mesh = torus
    center_ring.material_override = mat_gold
    center_ring.position = Vector3(0, 0.08, 0)
    board_root.add_child(center_ring)

    var center_disc := MeshInstance3D.new()
    var disc := CylinderMesh.new()
    disc.top_radius = 0.36
    disc.bottom_radius = 0.36
    disc.height = 0.05
    center_disc.mesh = disc
    center_disc.material_override = mat_queen
    center_disc.position = Vector3(0, 0.08, 0)
    board_root.add_child(center_disc)

func _add_pockets() -> void:
    var coords := [
        Vector3(-4.85, 0.08, -4.85),
        Vector3(4.85, 0.08, -4.85),
        Vector3(-4.85, 0.08, 4.85),
        Vector3(4.85, 0.08, 4.85),
    ]
    for pos in coords:
        var pocket := MeshInstance3D.new()
        var mesh := CylinderMesh.new()
        mesh.top_radius = POCKET_RADIUS
        mesh.bottom_radius = POCKET_RADIUS
        mesh.height = 0.08
        pocket.mesh = mesh
        pocket.material_override = mat_dark
        pocket.position = pos
        board_root.add_child(pocket)

func _add_baseline() -> void:
    for x in [-2.65, 2.65]:
        var mark := MeshInstance3D.new()
        var cylinder := CylinderMesh.new()
        cylinder.top_radius = 0.13
        cylinder.bottom_radius = 0.13
        cylinder.height = 0.045
        mark.mesh = cylinder
        mark.material_override = mat_dark
        mark.position = Vector3(x, 0.09, STRIKER_Z)
        board_root.add_child(mark)

    var line := MeshInstance3D.new()
    var line_mesh := BoxMesh.new()
    line_mesh.size = Vector3(6.0, 0.035, 0.08)
    line.mesh = line_mesh
    line.material_override = mat_dark
    line.position = Vector3(0, 0.09, STRIKER_Z)
    board_root.add_child(line)

func _build_camera() -> void:
    camera = Camera3D.new()
    camera.position = Vector3(0, 15.0, 10.2)
    camera.rotation_degrees = Vector3(-52.0, 0.0, 0.0)
    camera.current = true
    add_child(camera)

func _build_ui() -> void:
    var canvas := CanvasLayer.new()
    add_child(canvas)

    var panel := ColorRect.new()
    panel.color = Color(0.09, 0.055, 0.035, 0.90)
    panel.position = Vector2(18, 18)
    panel.size = Vector2(1244, 78)
    canvas.add_child(panel)

    var title := Label.new()
    title.text = "POCKET BOARD 3D"
    title.position = Vector2(24, 12)
    title.add_theme_font_size_override("font_size", 25)
    panel.add_child(title)

    mode_label = Label.new()
    mode_label.text = "OFFLINE • PASS & PLAY"
    mode_label.position = Vector2(24, 45)
    mode_label.add_theme_font_size_override("font_size", 14)
    panel.add_child(mode_label)

    turn_label = Label.new()
    turn_label.position = Vector2(330, 25)
    turn_label.add_theme_font_size_override("font_size", 20)
    panel.add_child(turn_label)

    score_label = Label.new()
    score_label.position = Vector2(600, 25)
    score_label.add_theme_font_size_override("font_size", 20)
    panel.add_child(score_label)

    round_label = Label.new()
    round_label.position = Vector2(900, 25)
    round_label.add_theme_font_size_override("font_size", 18)
    panel.add_child(round_label)

    best_label = Label.new()
    best_label.position = Vector2(1085, 25)
    best_label.add_theme_font_size_override("font_size", 18)
    panel.add_child(best_label)

    status_label = Label.new()
    status_label.position = Vector2(280, 115)
    status_label.size = Vector2(720, 52)
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status_label.add_theme_font_size_override("font_size", 22)
    canvas.add_child(status_label)

    var hint := Label.new()
    hint.text = "DRAG FROM THE STRIKER • RELEASE TO SHOOT • R = RESET • N = NEW ROUND"
    hint.position = Vector2(220, 668)
    hint.size = Vector2(840, 35)
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.add_theme_font_size_override("font_size", 14)
    canvas.add_child(hint)

    var reset := Button.new()
    reset.text = "RESET"
    reset.position = Vector2(1115, 116)
    reset.size = Vector2(130, 46)
    reset.pressed.connect(_reset_match)
    canvas.add_child(reset)

func _start_round() -> void:
    for piece in pieces:
        if is_instance_valid(piece):
            piece.queue_free()
    pieces.clear()

    current_player = 1
    scores = [0, 0]
    shots = 0
    shot_active = false
    settle_time = 0.0
    _spawn_rack()
    _spawn_striker()
    status_label.text = "Your turn: aim the striker and release."

func _reset_match() -> void:
    round_number = 1
    scores = [0, 0]
    _start_round()

func _spawn_rack() -> void:
    var spacing := 0.64
    var rows := 5
    var index := 0
    for row in range(-2, 3):
        var width := rows - abs(row)
        for col in range(width):
            var x := (col - float(width - 1) * 0.5) * spacing
            var z := row * spacing * 0.86
            var piece_type := "white" if index % 2 == 0 else "black"
            if index == 0:
                piece_type = "queen"
            _spawn_piece(Vector3(x, 0.18, z), piece_type)
            index += 1

    for i in range(9):
        var angle := float(i) * TAU / 9.0
        var pos := Vector3(cos(angle) * 1.55, 0.18, sin(angle) * 1.55)
        _spawn_piece(pos, "black" if i % 2 == 0 else "white")

func _spawn_piece(pos: Vector3, piece_type: String) -> RigidBody3D:
    var body := RigidBody3D.new()
    body.position = pos
    body.mass = 0.65 if piece_type != "queen" else 0.7
    body.linear_damp = 0.75
    body.angular_damp = 1.1
    body.lock_rotation = true
    body.add_to_group("coins")
    body.set_meta("piece_type", piece_type)

    var mesh := MeshInstance3D.new()
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = COIN_RADIUS
    cylinder.bottom_radius = COIN_RADIUS
    cylinder.height = COIN_HEIGHT
    cylinder.radial_segments = 32
    mesh.mesh = cylinder
    if piece_type == "white":
        mesh.material_override = mat_light
    elif piece_type == "black":
        mesh.material_override = mat_dark
    else:
        mesh.material_override = mat_queen
    body.add_child(mesh)

    var shape := CollisionShape3D.new()
    var cylinder_shape := CylinderShape3D.new()
    cylinder_shape.radius = COIN_RADIUS
    cylinder_shape.height = COIN_HEIGHT
    shape.shape = cylinder_shape
    body.add_child(shape)

    var physics := PhysicsMaterial.new()
    physics.friction = 0.14
    physics.bounce = 0.18
    body.physics_material_override = physics

    pieces_root.add_child(body)
    pieces.append(body)
    return body

func _spawn_striker() -> void:
    striker = RigidBody3D.new()
    striker.position = Vector3(0, 0.22, STRIKER_Z)
    striker.mass = 1.45
    striker.linear_damp = 0.65
    striker.angular_damp = 1.0
    striker.lock_rotation = true
    striker.add_to_group("striker")

    var mesh := MeshInstance3D.new()
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = STRIKER_RADIUS
    cylinder.bottom_radius = STRIKER_RADIUS
    cylinder.height = 0.16
    cylinder.radial_segments = 32
    mesh.mesh = cylinder
    mesh.material_override = mat_striker
    striker.add_child(mesh)

    var ring := MeshInstance3D.new()
    var torus := TorusMesh.new()
    torus.inner_radius = 0.30
    torus.outer_radius = 0.34
    torus.rings = 32
    torus.ring_segments = 8
    ring.mesh = torus
    ring.material_override = mat_gold
    ring.position.y = 0.09
    striker.add_child(ring)

    var shape := CollisionShape3D.new()
    var cylinder_shape := CylinderShape3D.new()
    cylinder_shape.radius = STRIKER_RADIUS
    cylinder_shape.height = 0.16
    shape.shape = cylinder_shape
    striker.add_child(shape)

    var physics := PhysicsMaterial.new()
    physics.friction = 0.12
    physics.bounce = 0.20
    striker.physics_material_override = physics
    pieces_root.add_child(striker)

func _can_shoot() -> bool:
    if shot_active or not is_instance_valid(striker):
        return false
    if _remaining_coins() <= 0:
        return false
    return striker.linear_velocity.length() < 0.1

func _screen_to_board(screen_pos: Vector2) -> Vector3:
    var origin := camera.project_ray_origin(screen_pos)
    var direction := camera.project_ray_normal(screen_pos)
    if abs(direction.y) < 0.0001:
        return Vector3.ZERO
    var t := -origin.y / direction.y
    if t < 0.0:
        return Vector3.ZERO
    return origin + direction * t

func _shoot(target: Vector3) -> void:
    if not _can_shoot():
        return
    var flat := Vector3(target.x, 0.0, target.z) - Vector3(striker.position.x, 0.0, striker.position.z)
    var distance := clamp(flat.length(), 0.0, MAX_SHOT_DISTANCE)
    if distance < 0.25:
        status_label.text = "Aim farther from the striker."
        return
    var dir := flat.normalized()
    var power := lerp(MIN_SHOT_POWER, MAX_SHOT_POWER, distance / MAX_SHOT_DISTANCE)
    striker.apply_central_impulse(dir * power)
    shots += 1
    shot_active = true
    settle_time = 0.0
    status_label.text = "Shot %d • Player %d" % [shots, current_player]

func _process_pockets() -> void:
    var pocket_positions := [
        Vector3(-4.85, 0.0, -4.85),
        Vector3(4.85, 0.0, -4.85),
        Vector3(-4.85, 0.0, 4.85),
        Vector3(4.85, 0.0, 4.85),
    ]

    for piece in pieces.duplicate():
        if not is_instance_valid(piece):
            continue
        if piece.position.y < -0.5:
            continue
        for pocket in pocket_positions:
            if Vector2(piece.position.x - pocket.x, piece.position.z - pocket.z).length() <= POCKET_RADIUS:
                var kind := str(piece.get_meta("piece_type", "white"))
                var points := 1 if kind != "queen" else 3
                scores[current_player - 1] += points
                status_label.text = "+%d  %s piece" % [points, kind.to_upper()]
                piece.queue_free()
                pieces.erase(piece)
                break

    if is_instance_valid(striker):
        for pocket in pocket_positions:
            if Vector2(striker.position.x - pocket.x, striker.position.z - pocket.z).length() <= POCKET_RADIUS:
                scores[current_player - 1] = max(0, scores[current_player - 1] - 1)
                status_label.text = "Striker pocketed • -1"
                _reset_striker()
                break

func _reset_striker() -> void:
    if not is_instance_valid(striker):
        return
    striker.freeze = true
    striker.linear_velocity = Vector3.ZERO
    striker.angular_velocity = Vector3.ZERO
    striker.position = Vector3(0, 0.22, STRIKER_Z)
    striker.freeze = false

func _all_pieces_stopped() -> bool:
    if is_instance_valid(striker) and striker.linear_velocity.length() > 0.12:
        return false
    for piece in pieces:
        if is_instance_valid(piece) and piece.linear_velocity.length() > 0.12:
            return false
    return true

func _finish_turn() -> void:
    if _remaining_coins() == 0:
        var winner := 1 if scores[0] >= scores[1] else 2
        var total := max(scores[0], scores[1])
        best_score = max(best_score, total)
        _save_progress()
        status_label.text = "Round complete • Player %d leads %d-%d" % [winner, scores[0], scores[1]]
        round_number += 1
        return
    current_player = 2 if current_player == 1 else 1
    _reset_striker()
    status_label.text = "Player %d turn" % current_player

func _remaining_coins() -> int:
    var count := 0
    for piece in pieces:
        if is_instance_valid(piece):
            count += 1
    return count

func _update_aim_visuals() -> void:
    if not aiming or not is_instance_valid(striker):
        if is_instance_valid(aim_line):
            aim_line.visible = false
        if is_instance_valid(aim_marker):
            aim_marker.visible = false
        return

    var start := striker.position + Vector3(0, 0.16, 0)
    var end := aim_world
    var flat := Vector3(end.x - start.x, 0.0, end.z - start.z)
    var distance := clamp(flat.length(), 0.0, MAX_SHOT_DISTANCE)
    if distance < 0.05:
        return
    var mid := start.lerp(start + flat.normalized() * distance, 0.5)

    if not is_instance_valid(aim_line):
        aim_line = MeshInstance3D.new()
        var mesh := BoxMesh.new()
        mesh.size = Vector3(0.06, 0.03, 1.0)
        aim_line.mesh = mesh
        aim_line.material_override = mat_gold
        add_child(aim_line)

    aim_line.visible = true
    aim_line.position = Vector3(mid.x, 0.17, mid.z)
    aim_line.scale.z = max(0.2, distance)
    aim_line.look_at(Vector3(start.x, 0.17, start.z), Vector3.UP)

    if not is_instance_valid(aim_marker):
        aim_marker = MeshInstance3D.new()
        var marker_mesh := SphereMesh.new()
        marker_mesh.radius = 0.11
        marker_mesh.height = 0.22
        aim_marker.mesh = marker_mesh
        aim_marker.material_override = mat_gold
        add_child(aim_marker)
    aim_marker.visible = true
    aim_marker.position = Vector3(start.x, 0.18, start.z) + flat.normalized() * distance

func _update_hud() -> void:
    if is_instance_valid(turn_label):
        turn_label.text = "PLAYER %d" % current_player
    if is_instance_valid(score_label):
        score_label.text = "P1 %d   •   P2 %d" % [scores[0], scores[1]]
    if is_instance_valid(round_label):
        round_label.text = "ROUND %02d" % round_number
    if is_instance_valid(best_label):
        best_label.text = "BEST %d" % best_score

func _save_progress() -> void:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        return
    var data := {"best_score": best_score, "round_number": round_number}
    file.store_string(JSON.stringify(data))

func _load_save() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return
    var value = JSON.parse_string(file.get_as_text())
    if value is Dictionary:
        best_score = int(value.get("best_score", 0))
        round_number = max(1, int(value.get("round_number", 1)))
