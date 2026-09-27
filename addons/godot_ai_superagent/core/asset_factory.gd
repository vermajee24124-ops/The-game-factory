class_name SuperAgentAssetFactory
extends RefCounted

var editor: EditorInterface

func _init(editor_interface: EditorInterface) -> void:
    editor = editor_interface

func create_3d_character(args: Dictionary) -> Dictionary:
    var root := editor.get_edited_scene_root()
    if root == null:
        return {"ok": false, "error": "No edited scene."}

    var character_name := _safe_name(str(args.get("name", "AICharacter")))
    var character := CharacterBody3D.new()
    character.name = character_name
    root.add_child(character)
    character.owner = root

    var skin := _color(args.get("skin_color", "#D9A066"), Color(0.85, 0.63, 0.40))
    var outfit := _color(args.get("outfit_color", "#3B82F6"), Color(0.23, 0.51, 0.96))
    var hair := _color(args.get("hair_color", "#2B1B12"), Color(0.17, 0.11, 0.07))

    var body := CapsuleMesh.new()
    body.radius = float(args.get("body_radius", 0.42))
    body.height = float(args.get("body_height", 1.25))
    _add_mesh(character, "Body", body, Vector3(0, 1.08, 0), Vector3.ZERO, _material(outfit))

    var head := SphereMesh.new()
    head.radius = float(args.get("head_radius", 0.38))
    head.height = float(args.get("head_height", 0.76))
    _add_mesh(character, "Head", head, Vector3(0, 2.02, 0), Vector3.ZERO, _material(skin))

    var hair_mesh := SphereMesh.new()
    hair_mesh.radius = 0.395
    hair_mesh.height = 0.35
    _add_mesh(character, "Hair", hair_mesh, Vector3(0, 2.31, 0), Vector3.ZERO, _material(hair))

    var arm := CapsuleMesh.new()
    arm.radius = 0.11
    arm.height = 0.86
    _add_mesh(character, "ArmL", arm, Vector3(-0.55, 1.18, 0), Vector3(0, 0, deg_to_rad(-10)), _material(outfit))
    _add_mesh(character, "ArmR", arm, Vector3(0.55, 1.18, 0), Vector3(0, 0, deg_to_rad(10)), _material(outfit))

    var leg := CapsuleMesh.new()
    leg.radius = 0.14
    leg.height = 0.95
    _add_mesh(character, "LegL", leg, Vector3(-0.20, 0.28, 0), Vector3.ZERO, _material(Color(0.12, 0.16, 0.22)))
    _add_mesh(character, "LegR", leg, Vector3(0.20, 0.28, 0), Vector3.ZERO, _material(Color(0.12, 0.16, 0.22)))

    var eye := SphereMesh.new()
    eye.radius = 0.055
    eye.height = 0.11
    _add_mesh(character, "EyeL", eye, Vector3(-0.14, 2.05, 0.34), Vector3.ZERO, _material(Color.WHITE))
    _add_mesh(character, "EyeR", eye, Vector3(0.14, 2.05, 0.34), Vector3.ZERO, _material(Color.WHITE))

    var collider := CollisionShape3D.new()
    collider.name = "CollisionShape3D"
    var shape := CapsuleShape3D.new()
    shape.radius = 0.42
    shape.height = 2.15
    collider.shape = shape
    character.add_child(collider)
    collider.position = Vector3(0, 1.08, 0)
    collider.owner = root

    var save_path := str(args.get("save_path", ""))
    var saved := ""
    if save_path.begins_with("res://") and save_path.ends_with(".tscn"):
        var packed := PackedScene.new()
        if packed.pack(character) == OK:
            if ResourceSaver.save(packed, save_path) == OK:
                saved = save_path

    return {
        "ok": true,
        "type": "procedural_3d_character",
        "node_path": str(character.get_path()),
        "saved_scene": saved,
        "notes": "Stylized modular character created entirely with Godot primitives. For production-quality humanoids, use the image-to-3D pipeline and then import GLB."
    }

func import_glb(args: Dictionary) -> Dictionary:
    var source := str(args.get("source_path", ""))
    var destination := str(args.get("destination_path", "res://assets/generated/model.glb"))

    if source.is_empty() or not FileAccess.file_exists(source):
        return {"ok": false, "error": "Source GLB does not exist."}
    if not destination.begins_with("res://") or not destination.ends_with(".glb"):
        return {"ok": false, "error": "Destination must be a res:// .glb path."}

    var bytes := FileAccess.get_file_as_bytes(source)
    if bytes.is_empty():
        return {"ok": false, "error": "Source GLB is empty or unreadable."}

    var file := FileAccess.open(destination, FileAccess.WRITE)
    if file == null:
        return {"ok": false, "error": "Cannot open destination GLB."}
    file.store_buffer(bytes)
    file.close()

    editor.get_resource_filesystem().scan()
    return {
        "ok": true,
        "type": "glb_import",
        "path": destination,
        "bytes": bytes.size(),
        "next": "Wait for Godot import, then instantiate the GLB scene and run visual/runtime QA."
    }

func _add_mesh(parent: Node3D, name: String, mesh: Mesh, pos: Vector3, rot: Vector3, material: Material) -> void:
    var node := MeshInstance3D.new()
    node.name = name
    node.mesh = mesh
    node.material_override = material
    parent.add_child(node)
    node.position = pos
    node.rotation = rot
    node.owner = editor.get_edited_scene_root()

func _material(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.72
    material.metallic = 0.0
    return material

func _color(value: Variant, fallback: Color) -> Color:
    var text := str(value)
    if text.is_empty():
        return fallback
    var parsed := Color(text)
    return parsed if parsed.a > 0.0 or text in ["#000000", "#000000ff"] else fallback

func _safe_name(value: String) -> String:
    var cleaned := value.strip_edges()
    if cleaned.is_empty():
        cleaned = "AICharacter"
    return cleaned.replace("/", "_").replace("\\", "_").replace(" ", "_")
