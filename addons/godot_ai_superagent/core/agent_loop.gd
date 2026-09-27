class_name SuperAgentLoop
extends RefCounted

signal event(kind: String, payload: Dictionary)

const MAX_STEPS := 24
var registry: RefCounted
var model: RefCounted
var memory: RefCounted
var skills: RefCounted
var api_knowledge: RefCounted
var step_count := 0
var active := false
var goal := ""

func _init(tool_registry: RefCounted, model_client: RefCounted, memory_store: RefCounted, skill_store: RefCounted = null) -> void:
    registry = tool_registry
    model = model_client
    memory = memory_store
    skills = skill_store
    api_knowledge = preload("res://addons/godot_ai_superagent/core/api_knowledge.gd").new()
    api_knowledge.load_knowledge()
    model.completed.connect(_on_model_completed)
    model.failed.connect(_on_model_failed)

func attach(node: Node) -> void:
    model.attach(node)

func start(user_goal: String) -> void:
    goal = user_goal.strip_edges()
    if goal.is_empty():
        return
    step_count = 0
    active = true
    event.emit("start", {"goal": goal})
    memory.append_event("agent_runs", {"kind":"start", "goal":goal})
    _ask()

func stop() -> void:
    active = false
    event.emit("stop", {})

func _ask() -> void:
    if not active or step_count >= MAX_STEPS:
        active = false
        event.emit("complete", {"reason":"step_limit"})
        return

    var tools_text := JSON.stringify(registry.list_tools())
    var relevant_skills: Array = skills.relevant(goal, 8) if skills != null else []
    var skill_text := JSON.stringify(relevant_skills)
    var relevant_api: Array = api_knowledge.relevant(goal, 12)
    var api_text := JSON.stringify(relevant_api)

    var prompt := (
        "Goal: %s\n"
        + "Available executable tools: %s\n"
        + "Relevant learned skills: %s\n"
        + "Relevant Godot 4.7.2 API knowledge: %s\n"
        + "Step: %d/%d\n"
        + "Return exactly one JSON object with action=tool_call or action=final. "
        + "Use live API knowledge before guessing a class, method, property or signal. "
        + "After meaningful writes, use a read/verification tool and save the scene when appropriate."
    ) % [goal, tools_text, skill_text, api_text, step_count + 1, MAX_STEPS]

    model.request_json([
        {"role":"system","content":"You are a careful Godot 4.7.2 autonomous game engineer. Use only supplied executable tools, learned skills, and API evidence. Never invent APIs. Verify meaningful changes."},
        {"role":"user","content":prompt}
    ])

func _on_model_completed(result: Dictionary) -> void:
    if not active:
        return
    step_count += 1

    var parsed = JSON.parse_string(str(result.get("content", "")))
    if not (parsed is Dictionary):
        memory.append_event("test_history", {"kind":"invalid_model_json", "step":step_count})
        _ask()
        return

    var action := str(parsed.get("action", ""))
    if action == "tool_call":
        var tool := str(parsed.get("tool", ""))
        var args = parsed.get("args", {})
        if not (args is Dictionary):
            args = {}
        var tool_result := registry.execute(tool, args)
        memory.append_event("test_history", {"kind":"tool", "step":step_count, "tool":tool, "result":tool_result})
        event.emit("tool", {"tool":tool, "result":tool_result})
        _ask()
    elif action == "final":
        active = false
        var value := str(parsed.get("result", ""))
        memory.append_event("test_history", {"kind":"final", "step":step_count, "result":value, "evidence":parsed.get("evidence", [])})
        event.emit("final", {"result":value, "evidence":parsed.get("evidence", [])})
    else:
        memory.append_event("test_history", {"kind":"unknown_action", "step":step_count})
        _ask()

func _on_model_failed(error_text: String) -> void:
    active = false
    memory.append_event("test_history", {"kind":"model_error", "error":error_text})
    event.emit("error", {"error":error_text})
