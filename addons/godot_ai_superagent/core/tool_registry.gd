class_name SuperAgentToolRegistry
extends RefCounted

var editor: EditorInterface
var permissions: RefCounted
var tools: Dictionary = {}
var asset_factory: RefCounted

func _init(editor_interface: EditorInterface, permission_gate: RefCounted) -> void:
    editor = editor_interface
    permissions = permission_gate
    asset_factory = preload("res://addons/godot_ai_superagent/core/asset_factory.gd").new(editor_interface)
    _register_tools()

func register_tool(name: String, description: String, mode: String, callback: Callable) -> void:
    tools[name] = {"name":name, "description":description, "mode":mode, "callback":callback}

func list_tools() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for value in tools.values():
        var item: Dictionary = value.duplicate()
        item.erase("callback")
        result.append(item)
    return result

func execute(name: String, args: Dictionary = {}) -> Dictionary:
    if not tools.has(name):
        return {"ok":false, "error":"Unknown tool: %s" % name}
    var spec: Dictionary = tools[name]
    if not permissions.request(name, str(spec["mode"])):
        return {"ok":false, "error":"Permission denied: %s" % name}
    var callback: Callable = spec["callback"]
    return {"ok":true, "tool":name, "output":callback.call(args)}

func _register_tools() -> void:
    register_tool("project.summary", "Inspect edited scene and basic editor state.", "safe", Callable(self, "_project_summary"))
    register_tool("scene.tree", "Read the full edited scene tree.", "safe", Callable(self, "_scene_tree"))
    register_tool("script.current", "Read the current script path.", "safe", Callable(self, "_current_script"))
    register_tool("editor.play", "Run the main scene.", "safe", Callable(self, "_play"))
    register_tool("editor.stop", "Stop the running game.", "safe", Callable(self, "_stop"))
    register_tool("scene.add_node", "Create a node below a parent in the edited scene.", "write", Callable(self, "_add_node"))
    register_tool("scene.set_property", "Set a property on a node in the edited scene.", "write", Callable(self, "_set_property"))
    register_tool("file.read_text", "Read a UTF-8 text file under res://.", "safe", Callable(self, "_read_text"))
    register_tool("file.write_text", "Write a UTF-8 text file under res://.", "write", Callable(self, "_write_text"))
    register_tool("asset.create_3d_character", "Create a stylized 3D character directly inside the edited Godot scene using native 3D primitives.", "write", Callable(self, "_create_3d_character"))
    register_tool("asset.import_glb", "Import a generated GLB into res:// and trigger Godot resource scanning.", "write", Callable(self, "_import_glb"))

func _project_summary(_args: Dictionary) -> Dictionary:
    var root := editor.get_edited_scene_root()
    return {
        "edited_scene": root.scene_file_path if root else "",
        "distraction_free": editor.distraction_free_mode
    }

func _scene_tree(_args: Dictionary) -> Dictionary:
    var root := editor.get_edited_scene_root()
    if root == null:
        return {"scene":"", "nodes":[]}
    return {"scene":root.scene_file_path, "nodes":_flatten(root)}

func _flatten(node: Node) -> Array:
    var rows: Array = [{"name":node.name, "type":node.get_class(), "path":str(node.get_path())}]
    for child in node.get_children():
        rows.append_array(_flatten(child))
    return rows

func _current_script(_args: Dictionary) -> Dictionary:
    var script = editor.get_script_editor().get_current_script()
    return {"path":script.resource_path if script else ""}

func _play(_args: Dictionary) -> Dictionary:
    editor.play_main_scene()
    return {"started":true}

func _stop(_args: Dictionary) -> Dictionary:
    editor.stop_playing()
    return {"stopped":true}

func _add_node(args: Dictionary) -> Dictionary:
    var root := editor.get_edited_scene_root()
    if root == null:
        return {"ok":false, "error":"No edited scene."}
    var parent_path := str(args.get("parent_path", "."))
    var parent: Node = root if parent_path in [".", ""] else root.get_node_or_null(NodePath(parent_path))
    if parent == null:
        return {"ok":false, "error":"Parent not found."}
    var node_type := str(args.get("node_type", "Node3D"))
    if not ClassDB.class_exists(node_type):
        return {"ok":false, "error":"Unknown Godot class: %s" % node_type}
    var node := ClassDB.instantiate(node_type)
    if not (node is Node):
        return {"ok":false, "error":"Type is not a Node."}
    node.name = str(args.get("name", node_type))
    parent.add_child(node)
    node.owner = root
    return {"ok":true, "path":str(node.get_path()), "type":node_type}

func _set_property(args: Dictionary) -> Dictionary:
    var root := editor.get_edited_scene_root()
    if root == null:
        return {"ok":false, "error":"No edited scene."}
    var node := root.get_node_or_null(NodePath(str(args.get("node_path", ""))))
    if node == null:
        return {"ok":false, "error":"Node not found."}
    var prop := str(args.get("property", ""))
    if prop.is_empty():
        return {"ok":false, "error":"Property required."}
    node.set(prop, args.get("value"))
    return {"ok":true, "node_path":str(node.get_path()), "property":prop}

func _read_text(args: Dictionary) -> Dictionary:
    var path := str(args.get("path", ""))
    if not path.begins_with("res://"):
        return {"ok":false, "error":"Only res:// paths are allowed."}
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return {"ok":false, "error":"Could not open file."}
    var value := file.get_as_text()
    file.close()
    return {"ok":true, "path":path, "content":value.left(20000)}

func _write_text(args: Dictionary) -> Dictionary:
    var path := str(args.get("path", ""))
    if not path.begins_with("res://"):
        return {"ok":false, "error":"Only res:// paths are allowed."}
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return {"ok":false, "error":"Could not open file."}
    file.store_string(str(args.get("content", "")))
    file.close()
    return {"ok":true, "path":path}


func _create_3d_character(args: Dictionary) -> Dictionary:
    return asset_factory.create_3d_character(args)

func _import_glb(args: Dictionary) -> Dictionary:
    return asset_factory.import_glb(args)
