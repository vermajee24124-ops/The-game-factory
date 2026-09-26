@tool
extends EditorPlugin

const Dock = preload("res://addons/godot_ai_superagent/core/super_agent_dock.gd")
const Registry = preload("res://addons/godot_ai_superagent/core/tool_registry.gd")
const Gate = preload("res://addons/godot_ai_superagent/core/permission_gate.gd")
const Memory = preload("res://addons/godot_ai_superagent/core/memory_store.gd")
const Skills = preload("res://addons/godot_ai_superagent/core/skill_store.gd")
const Loop = preload("res://addons/godot_ai_superagent/core/agent_loop.gd")
const Client = preload("res://addons/godot_ai_superagent/core/model_client.gd")

var dock: Control
var registry: RefCounted
var gate: RefCounted
var memory: RefCounted
var skills: RefCounted
var loop: RefCounted
var client: RefCounted

func _enter_tree() -> void:
    gate = Gate.new()
    memory = Memory.new()
    skills = Skills.new()
    skills.load_skills()
    registry = Registry.new(get_editor_interface(), gate)
    client = Client.new()
    loop = Loop.new(registry, client, memory, skills)
    dock = Dock.new(get_editor_interface(), registry, gate, memory, loop)
    add_control_to_dock(DOCK_SLOT_RIGHT_BL, dock)

func _exit_tree() -> void:
    if is_instance_valid(dock):
        remove_control_from_docks(dock)
        dock.queue_free()
    dock = null
    registry = null
    gate = null
    memory = null
    skills = null
    loop = null
    client = null
