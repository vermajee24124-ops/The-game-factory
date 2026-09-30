extends Node
var online: bool = false
var initialized: bool = false

func init()->void:
    initialized=true

func is_online()->bool:
    return online

func can_show_rewarded(_slot_id:String)->bool:
    return online

func show_rewarded(_slot_id:String, callback:Callable)->void:
    # Native provider is an adapter point. Base build never fabricates a reward offline.
    callback.call(false)
