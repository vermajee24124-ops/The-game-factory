class_name SuperAgentPermissionGate
extends RefCounted

signal permission_requested(tool_name: String, mode: String)

const SAFE := "safe"
const WRITE := "write"
const DESTRUCTIVE := "destructive"
const EXPORT := "export"

var allow_write := true
var allow_destructive := false
var allow_export := false

func can_run(mode: String) -> bool:
    match mode:
        SAFE:
            return true
        WRITE:
            return allow_write
        DESTRUCTIVE:
            return allow_destructive
        EXPORT:
            return allow_export
        _:
            return false

func request(tool_name: String, mode: String) -> bool:
    if can_run(mode):
        return true
    permission_requested.emit(tool_name, mode)
    return false
