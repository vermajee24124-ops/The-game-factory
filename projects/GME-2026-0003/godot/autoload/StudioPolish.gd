extends Node
## Turbo Rush Studio Polish runtime layer.
## Adds a cohesive showroom and lightweight CC0 environment dressing
## on top of the existing procedural racing foundation.

const GROUP := "StudioPolish"
const ASSET_GROUP := "StudioAssets"
const CYAN := Color("#23C4FF")
const ORANGE := Color("#FF6B2C")
const WHITE := Color("#EAF4FF")

const HERO_SCENE: PackedScene = preload("res://assets/studio/race-future.glb")
const HERO_ALT_SCENE: PackedScene = preload("res://assets/studio/sedan-sports.glb")
const BUILDING_SCENE: PackedScene = preload("res://assets/studio/building-c.glb")
const SKYSCRAPER_SCENE: PackedScene = preload("res://assets/studio/building-skyscraper-b.glb")
const LIGHT_SCENE: PackedScene = preload("res://assets/studio/light-square-double.glb")
const STAND_SCENE: PackedScene = preload("res://assets/studio/grandStandCovered.glb")
const BARRIER_SCENE: PackedScene = preload("res://assets/studio/barrierRed.glb")

var _menu_refresh_queued := false

func _ready() -> void:
    if not get_tree().node_added.is_connected(_on_node_added):
        get_tree().node_added.connect(_on_node_added)
    call_deferred("_enhance_menu")

func _on_node_added(node: Node) -> void:
    if node == null:
        return
    if node.name == "MENU_HERO" and not _menu_refresh_queued:
        _menu_refresh_queued = true
        call_deferred("_refresh_menu_showroom")

func _enhance_menu() -> void:
    var root := get_tree().current_scene
    if root == null:
        return
    var stage := root.get_node_or_null("MenuHeroStage") as Node3D
    if stage:
        enhance_menu(stage)

func _refresh_menu_showroom() -> void:
    _menu_refresh_queued = false
    var root := get_tree().current_scene
    if root == null:
        return
    var stage := root.get_node_or_null("MenuHeroStage") as Node3D
    if stage:
        enhance_menu(stage)

func enhance_menu(stage:Node3D) -> void:
    if stage == null or not is_instance_valid(stage):
        return

    var old := stage.get_node_or_null(ASSET_GROUP)
    if old:
        old.queue_free()

    var g := Node3D.new()
    g.name = ASSET_GROUP
    stage.add_child(g)

    var existing_car := stage.get_node_or_null("MENU_HERO")
    if existing_car:
        existing_car.visible = false

    var car_scene:PackedScene = HERO_SCENE
    if existing_car:
        var selected := str(existing_car.get("name"))
        if not selected.is_empty() and abs(selected.hash()) % 3 == 1:
            car_scene = HERO_ALT_SCENE

    var car := car_scene.instantiate() as Node3D
    if car:
        car.name = "StudioHeroVehicle"
        car.position = Vector3(0, 0.52, 0)
        car.rotation_degrees = Vector3(0, -28, 0)
        car.scale = Vector3.ONE * 2.15
        g.add_child(car)

    _showroom_lights(g)
    _showroom_markers(g)

func _showroom_lights(g:Node3D) -> void:
    var key := SpotLight3D.new()
    key.position = Vector3(-4.0, 6.5, 5.0)
    key.rotation_degrees = Vector3(-38.0, -28.0, 0.0)
    key.light_color = WHITE
    key.light_energy = 7.0
    key.spot_range = 16.0
    key.spot_angle = 45.0
    g.add_child(key)

    var rim := OmniLight3D.new()
    rim.position = Vector3(4.5, 4.0, -2.5)
    rim.light_color = CYAN
    rim.light_energy = 5.0
    rim.omni_range = 12.0
    g.add_child(rim)

    var warm := OmniLight3D.new()
    warm.position = Vector3(-4.0, 2.6, -1.0)
    warm.light_color = ORANGE
    warm.light_energy = 3.5
    warm.omni_range = 9.0
    g.add_child(warm)

func _showroom_markers(g:Node3D) -> void:
    for z in [-5.5, 0.0, 5.5]:
        var marker := MeshInstance3D.new()
        var mesh := BoxMesh.new()
        mesh.size = Vector3(0.10, 0.03, 2.0)
        marker.mesh = mesh
        marker.position = Vector3(6.2, 0.04, z)
        var mat := StandardMaterial3D.new()
        mat.albedo_color = CYAN
        mat.emission_enabled = true
        mat.emission = CYAN
        mat.emission_energy_multiplier = 1.4
        marker.material_override = mat
        g.add_child(marker)

func enhance_race(world:Node3D, points:Array, widths:Array, environment_id:String) -> void:
    if world == null or not is_instance_valid(world):
        return

    var old := world.get_node_or_null(GROUP)
    if old:
        old.queue_free()

    if points.size() < 4:
        return

    var g := Node3D.new()
    g.name = GROUP
    world.add_child(g)

    var step := maxi(2, int(float(points.size()) / 30.0))
    var count := 0
    for i in range(2, points.size() - 2, step):
        if count >= 42:
            break
        var p:Vector3 = points[i]
        var t:Vector3 = (points[i + 1] - p).normalized()
        var side := Vector3(-t.z, 0, t.x).normalized()
        var w := float(widths[mini(i, widths.size() - 1)])
        var base := p + side * (-1.0 if count % 2 == 0 else 1.0) * (w * 0.5 + 8.0)
        if count % 3 == 0:
            _lamp(g, base, environment_id)
        else:
            _banner(g, base, t, environment_id)
        count += 1

    _horizon(g, environment_id)
    _start_arch(g, points[mini(3, points.size()-1)], points[mini(4, points.size()-1)])
    _dress_with_cc0_assets(g, points, widths, environment_id)

func _dress_with_cc0_assets(g:Node3D, points:Array, widths:Array, env:String) -> void:
    if points.size() < 10 or widths.is_empty():
        return

    var asset_root := Node3D.new()
    asset_root.name = ASSET_GROUP
    g.add_child(asset_root)

    var urban := env in ["sunrise_city", "neon_metro", "industrial_night"]
    var highway := env in ["coastal_highway", "mountain_pass", "snowline", "desert_canyon", "volcanic_rim"]
    var count := 0

    # Keep runtime geometry light: a few large shared GLB instances, no collision.
    if urban:
        for n in range(6):
            var idx := clampi(int(float(n + 1) * float(points.size() - 1) / 7.0), 3, points.size() - 3)
            var sample := _sample(points, widths, idx)
            var packed:PackedScene = SKYSCRAPER_SCENE if n % 2 == 0 else BUILDING_SCENE
            _add_asset(asset_root, packed, sample["position"], sample["side"], float(sample["width"]), 0.0, 5.6 if n % 2 == 0 else 7.2, -1.0 if n % 2 == 0 else 1.0, n)
            count += 1

    if highway:
        for n in range(5):
            var idx := clampi(int(float(n + 1) * float(points.size() - 1) / 6.0), 2, points.size() - 2)
            var sample := _sample(points, widths, idx)
            _add_light_asset(asset_root, sample["position"], sample["side"], float(sample["width"]), 1.0 if n % 2 == 0 else -1.0, n)
            count += 1

    # A small race-day grandstand near the opening section reinforces the event presentation.
    if points.size() > 20:
        var start_idx := mini(8, points.size() - 3)
        var sample := _sample(points, widths, start_idx)
        _add_asset(asset_root, STAND_SCENE, sample["position"], sample["side"], float(sample["width"]), 0.0, 6.0, -1.0, 90)

    # Short barrier run near selected bends gives the road a manufactured race-course feel.
    var barrier_step := maxi(6, int(points.size() / 8))
    for n in range(3):
        var idx := clampi(5 + n * barrier_step, 3, points.size() - 3)
        var sample := _sample(points, widths, idx)
        _add_asset(asset_root, BARRIER_SCENE, sample["position"], sample["side"], float(sample["width"]), 0.0, 4.5, 1.0 if n % 2 == 0 else -1.0, 140 + n)

func _sample(points:Array, widths:Array, idx:int) -> Dictionary:
    var p:Vector3 = points[idx]
    var t:Vector3 = (points[mini(idx + 1, points.size() - 1)] - p).normalized()
    var side := Vector3(-t.z, 0, t.x).normalized()
    return {
        "position": p,
        "side": side,
        "width": float(widths[mini(idx, widths.size() - 1)])
    }

func _add_asset(parent:Node3D, packed:PackedScene, p:Vector3, side:Vector3, width:float, yaw:float, scale_value:float, sign:float, seed:int) -> void:
    if packed == null:
        return
    var node := packed.instantiate() as Node3D
    if node == null:
        return
    node.position = p + side * sign * (width * 0.5 + 12.0)
    node.position.y = p.y
    node.rotation.y = yaw + float(seed % 7) * 0.13
    node.scale = Vector3.ONE * scale_value
    parent.add_child(node)

func _add_light_asset(parent:Node3D, p:Vector3, side:Vector3, width:float, sign:float, seed:int) -> void:
    var node := LIGHT_SCENE.instantiate() as Node3D
    if node == null:
        return
    node.position = p + side * sign * (width * 0.5 + 3.2)
    node.position.y = p.y + 0.04
    node.rotation.y = atan2(side.x, side.z)
    node.scale = Vector3.ONE * 8.0
    parent.add_child(node)

func _lamp(g:Node3D, p:Vector3, env:String) -> void:
    var pole := MeshInstance3D.new()
    var m := CylinderMesh.new()
    m.top_radius = 0.05
    m.bottom_radius = 0.08
    m.height = 4.2
    pole.mesh = m
    pole.position = p + Vector3.UP * 2.1
    var pm := StandardMaterial3D.new()
    pm.albedo_color = Color("#3B4A60")
    pm.metallic = 0.75
    pm.roughness = 0.3
    pole.material_override = pm
    g.add_child(pole)

    var head := MeshInstance3D.new()
    var hm := BoxMesh.new()
    hm.size = Vector3(0.4, 0.1, 0.2)
    head.mesh = hm
    head.position = p + Vector3.UP * 4.2
    var glow := StandardMaterial3D.new()
    glow.albedo_color = CYAN if env == "neon_metro" else WHITE
    glow.emission_enabled = true
    glow.emission = glow.albedo_color
    glow.emission_energy_multiplier = 2.8
    head.material_override = glow
    g.add_child(head)

    var l := OmniLight3D.new()
    l.position = head.position
    l.light_color = glow.albedo_color
    l.light_energy = 1.8
    l.omni_range = 7.0
    g.add_child(l)

func _banner(g:Node3D, p:Vector3, t:Vector3, env:String) -> void:
    var side := Vector3(-t.z, 0, t.x).normalized()
    for s in [-1.0, 1.0]:
        var post := MeshInstance3D.new()
        var pm := BoxMesh.new()
        pm.size = Vector3(0.13, 3.0, 0.13)
        post.mesh = pm
        post.position = p + side * s * 1.15 + Vector3.UP * 1.5
        var mat := StandardMaterial3D.new()
        mat.albedo_color = Color("#25334B")
        mat.metallic = 0.65
        post.material_override = mat
        g.add_child(post)
    var board := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = Vector3(2.7, 0.68, 0.1)
    board.mesh = bm
    board.position = p + Vector3.UP * 2.9
    board.rotation.y = atan2(t.x, t.z)
    var bmat := StandardMaterial3D.new()
    bmat.albedo_color = CYAN if env == "neon_metro" else ORANGE
    bmat.emission_enabled = true
    bmat.emission = bmat.albedo_color
    bmat.emission_energy_multiplier = 0.75
    board.material_override = bmat
    g.add_child(board)

func _horizon(g:Node3D, env:String) -> void:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color("#18243A") if env != "desert_canyon" else Color("#5B3B2D")
    mat.roughness = 0.85
    for i in range(16):
        var b := MeshInstance3D.new()
        var bm := BoxMesh.new()
        var h := 7.0 + float((i * 13) % 18)
        bm.size = Vector3(7.0 + float(i % 3) * 2.0, h, 7.0)
        b.mesh = bm
        b.position = Vector3(float(i - 8) * 13.0, h * 0.5, 120.0 + float((i * 17) % 90))
        b.material_override = mat
        g.add_child(b)

func _start_arch(g:Node3D, p:Vector3, next_p:Vector3) -> void:
    var t := (next_p - p).normalized()
    var side := Vector3(-t.z, 0, t.x).normalized()
    for s in [-1.0, 1.0]:
        var post := MeshInstance3D.new()
        var pm := BoxMesh.new()
        pm.size = Vector3(0.3, 6.0, 0.3)
        post.mesh = pm
        post.position = p + side * s * 7.3 + Vector3.UP * 3.0
        var mat := StandardMaterial3D.new()
        mat.albedo_color = ORANGE if s < 0.0 else CYAN
        mat.emission_enabled = true
        mat.emission = mat.albedo_color
        mat.emission_energy_multiplier = 0.7
        post.material_override = mat
        g.add_child(post)
    var top := MeshInstance3D.new()
    var tm := BoxMesh.new()
    tm.size = Vector3(14.6, 0.4, 0.4)
    top.mesh = tm
    top.position = p + Vector3.UP * 6.0
    top.rotation.y = atan2(t.x, t.z)
    var tmat := StandardMaterial3D.new()
    tmat.albedo_color = Color("#121B2C")
    tmat.metallic = 0.55
    tmat.roughness = 0.25
    top.material_override = tmat
    g.add_child(top)

func camera_feedback(camera:Camera3D, speed:float, boosting:bool, shake:float, delta:float) -> void:
    if camera == null or not is_instance_valid(camera):
        return
    var r := clampf(speed / 48.0, 0.0, 1.25)
    var target := 69.0 + r * 7.0 + (3.0 if boosting else 0.0)
    camera.fov = lerpf(camera.fov, target, minf(1.0, delta * 5.0))
    camera.rotation.x = lerpf(camera.rotation.x, sin(Time.get_ticks_msec() * 0.012) * 0.012 + shake * 0.01, minf(1.0, delta * 6.0))
