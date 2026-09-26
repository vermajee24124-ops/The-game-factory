@tool
extends VBoxContainer

var registry: RefCounted
var loop: RefCounted
var output: RichTextLabel
var prompt: TextEdit

func _init(_editor: EditorInterface, tool_registry: RefCounted, _gate: RefCounted, _memory: RefCounted, agent_loop: RefCounted) -> void:
    registry = tool_registry
    loop = agent_loop
    custom_minimum_size = Vector2(430, 0)

func _ready() -> void:
    loop.attach(self)
    loop.event.connect(_on_event)

    var title := Label.new()
    title.text = "Godot AI SuperAgent"
    title.add_theme_font_size_override("font_size", 20)
    add_child(title)

    var info := Label.new()
    info.text = "Inspect → Plan → Act → Observe → Verify → Repair"
    add_child(info)

    prompt = TextEdit.new()
    prompt.placeholder_text = "Build, debug, optimize, or inspect this project..."
    prompt.custom_minimum_size = Vector2(0, 120)
    add_child(prompt)

    var run := Button.new()
    run.text = "Run Agent"
    run.pressed.connect(_run_agent)
    add_child(run)

    var inspect := Button.new()
    inspect.text = "Inspect Scene"
    inspect.pressed.connect(_inspect)
    add_child(inspect)

    var tools := Button.new()
    tools.text = "Show Tools"
    tools.pressed.connect(_tools)
    add_child(tools)

    output = RichTextLabel.new()
    output.bbcode_enabled = true
    output.fit_content = false
    output.custom_minimum_size = Vector2(0, 430)
    add_child(output)
    _log("Ready. Set FREELLMAPI_API_KEY in the editor process environment.")

func _run_agent() -> void:
    loop.start(prompt.text)

func _inspect() -> void:
    _log(JSON.stringify(registry.execute("scene.tree"), "  "))

func _tools() -> void:
    _log(JSON.stringify(registry.list_tools(), "  "))

func _on_event(kind: String, payload: Dictionary) -> void:
    _log("[%s] %s" % [kind, JSON.stringify(payload)])

func _log(value: String) -> void:
    if is_instance_valid(output):
        output.append_text(value + "\n")
