class_name SuperAgentModelClient
extends RefCounted

signal completed(result: Dictionary)
signal failed(error: String)

var http: HTTPRequest
var owner_node: Node
var base_url := ""
var model := "auto"
var api_key := ""

func _init() -> void:
    base_url = str(ProjectSettings.get_setting("godot_ai_superagent/base_url", "http://localhost:3001"))
    model = str(ProjectSettings.get_setting("godot_ai_superagent/model", "auto"))
    api_key = OS.get_environment("FREELLMAPI_API_KEY")

func attach(node: Node) -> void:
    owner_node = node
    if is_instance_valid(http):
        return
    http = HTTPRequest.new()
    owner_node.add_child(http)
    http.request_completed.connect(_on_request_completed)

func ready() -> bool:
    return is_instance_valid(http) and not base_url.is_empty() and not api_key.is_empty()

func request_json(messages: Array, token_limit: int = 1800) -> void:
    if not ready():
        failed.emit("Model not configured: set FREELLMAPI_API_KEY and the base URL.")
        return
    var url := base_url.rstrip("/")
    if not url.ends_with("/v1"):
        url += "/v1"
    url += "/chat/completions"
    var payload := {
        "model": model,
        "messages": messages,
        "temperature": 0.15,
        "max_tokens": token_limit
    }
    var headers := PackedStringArray([
        "Content-Type: application/json",
        "Authorization: Bearer %s" % api_key
    ])
    var err := http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
    if err != OK:
        failed.emit("HTTP request setup failed: %s" % err)

func _on_request_completed(_result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    if code < 200 or code >= 300:
        failed.emit("Model HTTP %s: %s" % [code, body.get_string_from_utf8().left(1600)])
        return
    var parsed = JSON.parse_string(body.get_string_from_utf8())
    if not (parsed is Dictionary):
        failed.emit("Model returned invalid JSON.")
        return
    var choices: Array = parsed.get("choices", [])
    if choices.is_empty():
        failed.emit("Model returned no choices.")
        return
    var message: Dictionary = choices[0].get("message", {})
    completed.emit({
        "content": str(message.get("content", "")),
        "model": str(parsed.get("model", model)),
        "usage": parsed.get("usage", {})
    })
