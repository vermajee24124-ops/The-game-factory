extends Node

var available := false
var initialized := false
var _reward_callback: Callable
var _js_reward_callback = null

func init() -> void:
    if initialized or not OS.has_feature("web"):
        return
    initialized = true
    _js_reward_callback = JavaScriptBridge.create_callback(_on_reward_callback)
    var window = JavaScriptBridge.get_interface("window")
    window.__turboRushRewardCallback = _js_reward_callback
    available = bool(JavaScriptBridge.eval("!!(window.TurboRushWebAds && window.TurboRushWebAds.available)"))

func is_available() -> bool:
    if OS.has_feature("web") and not initialized:
        init()
    return available

func show_startup_banners() -> void:
    if not is_available():
        return
    var window = JavaScriptBridge.get_interface("window")
    if window.TurboRushWebAds:
        window.TurboRushWebAds.showStartupBanners()

func hide_startup_banners() -> void:
    if not OS.has_feature("web"):
        return
    var window = JavaScriptBridge.get_interface("window")
    if window.TurboRushWebAds:
        window.TurboRushWebAds.hideStartupBanners()

func show_midgame() -> void:
    if not is_available():
        return
    var window = JavaScriptBridge.get_interface("window")
    if window.TurboRushWebAds:
        window.TurboRushWebAds.showMidgame()

func show_rewarded(callback: Callable) -> void:
    if not is_available():
        callback.call(false)
        return
    _reward_callback = callback
    var window = JavaScriptBridge.get_interface("window")
    if window.TurboRushWebAds:
        window.TurboRushWebAds.showRewarded()
    else:
        callback.call(false)

func _on_reward_callback(args:Array) -> void:
    if _reward_callback.is_valid():
        var ok := not args.is_empty() and bool(args[0])
        var cb:=_reward_callback
        _reward_callback=Callable()
        cb.call(ok)
