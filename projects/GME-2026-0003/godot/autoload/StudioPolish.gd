extends Node
## Turbo Rush Studio Polish runtime layer.
## Augments the existing game without replacing its core systems.

const GROUP := "StudioPolish"
const CYAN := Color("#23C4FF")
const ORANGE := Color("#FF6B2C")
const WHITE := Color("#EAF4FF")

func _ready() -> void:
    call_deferred("_enhance_menu")

func _enhance_menu() -> void:
    var root := get_tree().current_scene
    if root == null:
        return
    var stage := root.get_node_or_null("MenuHeroStage") as Node3D
    if stage:
        enhance_menu(stage)

func enhance_menu(stage:Node3D) -> void:
    if stage.get_node_or_null(GROUP):
        return
    var g := Node3D.new()
    g.name = GROUP
    stage.add_child(g)

    var ring := MeshInstance3D.new()
    var rm := TorusMesh.new()
    rm.inner_radius = 5.7
    rm.outer_radius = 5.95
    ring.mesh = rm
    ring.position.y = 0.36
    var rmat := StandardMaterial3D.new()
    rmat.albedo_color = CYAN
    rmat.emission_enabled = true
    rmat.emission = CYAN
    rmat.emission_energy_multiplier = 1.8
    ring.material_override = rmat
    g.add_child(ring)

    for side in [-1.0, 1.0]:
        for z in [-6.0, -2.0, 2.0, 6.0]:
            var pillar := MeshInstance3D.new()
            var pm := BoxMesh.new()
            pm.size = Vector3(0.16, 3.0, 0.16)
            pillar.mesh = pm
            pillar.position = Vector3(side * 10.0, 1.5, z)
            var mat := StandardMaterial3D.new()
            mat.albedo_color = Color("#17233A")
            mat.metallic = 0.7
            mat.roughness = 0.25
            pillar.material_override = mat
            g.add_child(pillar)

            var light := OmniLight3D.new()
            light.position = pillar.position + Vector3(0, 2.0, 0)
            light.light_color = ORANGE if side < 0.0 else CYAN
            light.light_energy = 2.2
            light.omni_range = 5.0
            g.add_child(light)

func enhance_race(world:Node3D, points:Array, widths:Array, environment_id:String) -> void:
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
