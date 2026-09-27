class_name SuperAgentRuntimeTooling
extends RefCounted

var editor: EditorInterface
var api: RefCounted

func _init(editor_interface: EditorInterface, api_store: RefCounted) -> void:
    editor = editor_interface
    api = api_store

func class_info(args: Dictionary) -> Dictionary:
    var class_name_text := str(args.get("class_name", ""))
    return api.class_runtime_info(class_name_text)

func query_classes(args: Dictionary) -> Dictionary:
    return api.global_api_query(str(args.get("query", "")))

func knowledge_summary(_args: Dictionary) -> Dictionary:
    return api.summary()
