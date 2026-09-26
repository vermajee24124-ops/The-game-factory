class_name SuperAgentMemoryStore
extends RefCounted

const MEMORY_PATH := "user://godot_ai_superagent_memory.json"

var data: Dictionary = {
    "schema_version": 1,
    "project_facts": {},
    "decisions": [],
    "known_bugs": [],
    "test_history": [],
    "agent_runs": []
}

func _init() -> void:
    load_memory()

func load_memory() -> void:
    if not FileAccess.file_exists(MEMORY_PATH):
        return
    var file := FileAccess.open(MEMORY_PATH, FileAccess.READ)
    if file == null:
        return
    var value = JSON.parse_string(file.get_as_text())
    file.close()
    if value is Dictionary:
        data = value

func save_memory() -> void:
    var file := FileAccess.open(MEMORY_PATH, FileAccess.WRITE)
    if file == null:
        return
    file.store_string(JSON.stringify(data, "  "))
    file.close()

func append_event(kind: String, payload: Dictionary) -> void:
    if not data.has(kind) or not (data[kind] is Array):
        data[kind] = []
    data[kind].append(payload)
    save_memory()
