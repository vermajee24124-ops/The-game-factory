@tool
extends EditorPlugin

var export_plugin: AndroidExportPlugin

func _enter_tree() -> void:
    export_plugin = AndroidExportPlugin.new()
    add_export_plugin(export_plugin)

func _exit_tree() -> void:
    if export_plugin:
        remove_export_plugin(export_plugin)
    export_plugin = null

class AndroidExportPlugin extends EditorExportPlugin:
    const PLUGIN_NAME := "TurboUnityAds"

    func _supports_platform(platform) -> bool:
        return platform is EditorExportPlatformAndroid

    func _get_android_libraries(platform, debug) -> PackedStringArray:
        var suffix := "-debug.aar" if debug else "-release.aar"
        return PackedStringArray(["turbo_unity_ads/bin/" + ("debug/" if debug else "release/") + PLUGIN_NAME + suffix])

    func _get_android_dependencies(platform, debug) -> PackedStringArray:
        return PackedStringArray(["com.unity3d.ads:unity-ads:4.21.0"])

    func _get_name() -> String:
        return PLUGIN_NAME
