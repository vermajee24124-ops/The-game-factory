class_name SuperAgentApiKnowledge
extends RefCounted

const CURRICULUM_PATH := "res://knowledge/agent_curriculum.json"
var inventory: Dictionary = {}
var classes: Array[Dictionary] = []

func load_knowledge() -> void:
    inventory = {}
    classes = []
    var file := FileAccess.open(CURRICULUM_PATH, FileAccess.READ)
    if file == null:
        return
    var value = JSON.parse_string(file.get_as_text())
    file.close()
    if not (value is Dictionary):
        return
    inventory = value.get("inventory", {})
    var rows = value.get("class_reference", [])
    if rows is Array:
        for row in rows:
            if row is Dictionary:
                classes.append(row)

func summary() -> Dictionary:
    return {
        "engine": "4.7.2",
        "inventory": inventory,
        "class_count": classes.size(),
    }

func relevant(query: String, limit: int = 12) -> Array[Dictionary]:
    var tokens := query.to_lower().split(" ", false)
    var ranked: Array = []
    for row in classes:
        var hay := (
            str(row.get("name", "")) + " " +
            str(row.get("inherits", "")) + " " +
            str(row.get("brief", "")) +
            " " + str(row.get("name", "")).replace("_", " ")
        ).to_lower()
        var score := 0
        for token in tokens:
            if token.length() >= 3 and hay.contains(token):
                score += 1
        if score > 0:
            ranked.append({"score": score, "class": row})
    ranked.sort_custom(func(a, b): return int(a.score) > int(b.score))
    var out: Array[Dictionary] = []
    for item in ranked.slice(0, limit):
        out.append(item.class)
    return out

func class_runtime_info(class_name_text: String) -> Dictionary:
    if not ClassDB.class_exists(class_name_text):
        return {"ok": false, "error": "Unknown Godot class: %s" % class_name_text}
    var props := ClassDB.class_get_property_list(class_name_text)
    var methods := ClassDB.class_get_method_list(class_name_text)
    var signals := ClassDB.class_get_signal_list(class_name_text)
    var info := {
        "ok": true,
        "engine": "4.7.2",
        "class": class_name_text,
        "is_node": ClassDB.is_parent_class(class_name_text, "Node"),
        "is_resource": ClassDB.is_parent_class(class_name_text, "Resource"),
        "properties": props,
        "methods": methods,
        "signals": signals,
    }
    return info

func global_api_query(query: String) -> Dictionary:
    var q := query.to_lower()
    var names := ClassDB.get_class_list()
    var matches: Array[String] = []
    for name in names:
        if q.is_empty() or str(name).to_lower().contains(q):
            matches.append(name)
    matches.sort()
    return {"query": query, "matches": matches.slice(0, 200), "count": matches.size()}
