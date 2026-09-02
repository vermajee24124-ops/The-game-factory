extends Node3D
class_name StuntWorld

const CHUNK_LENGTH := 28.0
const LANE_WIDTH := 4.0
const CHUNK_COUNT := 28
const ROAD_WIDTH := 14.0

var rng := RandomNumberGenerator.new()
var next_z := 0.0
var chunks: Array[Node3D] = []
var player: Node3D

func _ready() -> void:
    rng.seed = 20260902
    _build_initial_world()

func setup(target_player: Node3D) -> void:
    player = target_player

func _physics_process(_delta: float) -> void:
    if player == null:
        return
    while next_z > player.global_position.z - 260.0:
        _spawn_chunk()
    _recycle_chunks(player.global_position.z)

func _build_initial_world() -> void:
    next_z = 0.0
    for i in CHUNK_COUNT:
        _spawn_chunk(i == 0)

func _spawn_chunk(safe := false) -> void:
    var chunk := Node3D.new()
    chunk.name = "Chunk_%03d" % chunks.size()
    add_child(chunk)
    var z := next_z - CHUNK_LENGTH * 0.5
    next_z -= CHUNK_LENGTH
    chunk.position = Vector3(0.0, 0.0, z)

    var track := StaticBody3D.new()
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(ROAD_WIDTH, 0.8, CHUNK_LENGTH)
    mesh.mesh = box
    mesh.position.y = -0.4
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.08, 0.11, 0.15)
    mesh.material_override = mat

    var shape := CollisionShape3D.new()
    var collider := BoxShape3D.new()
    collider.size = box.size
    shape.shape = collider
    shape.position.y = -0.4
    track.add_child(mesh)
    track.add_child(shape)
    chunk.add_child(track)

    _add_lane_markers(chunk)
    if safe:
        return

    var roll := rng.randi_range(0, 99)
    if roll < 35:
        _add_collectibles(chunk)
    elif roll < 70:
        _add_obstacles(chunk)
    else:
        _add_ramp(chunk)
        _add_collectibles(chunk)

    chunks.append(chunk)

func _add_lane_markers(chunk: Node3D) -> void:
    for lane_x in [-LANE_WIDTH * 0.5, LANE_WIDTH * 0.5]:
        var marker := MeshInstance3D.new()
        var box := BoxMesh.new()
        box.size = Vector3(0.12, 0.03, CHUNK_LENGTH - 2.0)
        marker.mesh = box
        marker.position = Vector3(lane_x, 0.03, 0.0)
        var mat := StandardMaterial3D.new()
        mat.albedo_color = Color(0.85, 0.85, 0.75)
        marker.material_override = mat
        chunk.add_child(marker)

func _add_collectibles(chunk: Node3D) -> void:
    var lane := rng.randi_range(0, 2)
    var x := (lane - 1) * LANE_WIDTH
    for i in 5:
        _spawn_coin(chunk, Vector3(x, 1.3 + sin(i * 0.8) * 0.3, 8.0 - i * 3.5))
    if rng.randi_range(0, 4) == 0:
        _spawn_diamond(chunk, Vector3(x, 1.5, -9.0))

func _spawn_coin(chunk: Node3D, local_pos: Vector3) -> void:
    var area := Area3D.new()
    area.name = "Coin"
    var mesh := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.32
    sphere.height = 0.64
    mesh.mesh = sphere
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(1.0, 0.78, 0.08)
    mat.emission_enabled = true
    mat.emission = Color(0.25, 0.18, 0.01)
    mesh.material_override = mat
    var shape := CollisionShape3D.new()
    var capsule := SphereShape3D.new()
    capsule.radius = 0.45
    shape.shape = capsule
    area.add_child(mesh)
    area.add_child(shape)
    area.position = local_pos
    area.body_entered.connect(_on_collectible_body_entered.bind(area, "coin"))
    chunk.add_child(area)

func _spawn_diamond(chunk: Node3D, local_pos: Vector3) -> void:
    var area := Area3D.new()
    area.name = "Diamond"
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(0.45, 0.65, 0.45)
    mesh.mesh = box
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.15, 0.65, 1.0)
    mat.emission_enabled = true
    mat.emission = Color(0.02, 0.15, 0.35)
    mesh.material_override = mat
    var shape := CollisionShape3D.new()
    var sphere := SphereShape3D.new()
    sphere.radius = 0.5
    shape.shape = sphere
    area.add_child(mesh)
    area.add_child(shape)
    area.position = local_pos
    area.body_entered.connect(_on_collectible_body_entered.bind(area, "diamond"))
    chunk.add_child(area)

func _add_obstacles(chunk: Node3D) -> void:
    var lane := rng.randi_range(0, 2)
    var x := (lane - 1) * LANE_WIDTH
    _spawn_obstacle(chunk, Vector3(x, 1.0, rng.randf_range(-7.0, 7.0)))

func _spawn_obstacle(chunk: Node3D, local_pos: Vector3) -> void:
    var body := StaticBody3D.new()
    body.name = "Obstacle"
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(2.4, 2.0, 2.0)
    mesh.mesh = box
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.84, 0.23, 0.08)
    mesh.material_override = mat
    var shape := CollisionShape3D.new()
    var collider := BoxShape3D.new()
    collider.size = box.size
    shape.shape = collider
    body.add_child(mesh)
    body.add_child(shape)
    body.position = local_pos
    chunk.add_child(body)

func _add_ramp(chunk: Node3D) -> void:
    var ramp := StaticBody3D.new()
    ramp.name = "Ramp"
    ramp.position = Vector3(0.0, 1.1, -4.0)
    ramp.rotation_degrees.x = -16.0
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(ROAD_WIDTH, 1.0, 10.0)
    mesh.mesh = box
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.16, 0.34, 0.58)
    mesh.material_override = mat
    var shape := CollisionShape3D.new()
    var collider := BoxShape3D.new()
    collider.size = box.size
    shape.shape = collider
    ramp.add_child(mesh)
    ramp.add_child(shape)
    chunk.add_child(ramp)

func _on_collectible_body_entered(body: Node3D, area: Area3D, kind: String) -> void:
    if not body is StuntVehicle:
        return
    var vehicle := body as StuntVehicle
    if kind == "coin":
        vehicle.add_coin()
    elif kind == "diamond":
        vehicle.add_diamond()
    area.queue_free()

func _recycle_chunks(player_z: float) -> void:
    for chunk in chunks.duplicate():
        if chunk.global_position.z > player_z + 140.0:
            chunks.erase(chunk)
            chunk.queue_free()
