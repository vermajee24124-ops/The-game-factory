extends Node

const UNITY_ANDROID_GAME_ID := ReleaseConfig.UNITY_ANDROID_GAME_ID
const UNITY_IOS_GAME_ID := ReleaseConfig.UNITY_IOS_GAME_ID

# One dedicated Android Banner ad unit can back two BannerAd instances,
# one anchored at the top and one at the bottom.
const UNITY_ANDROID_BANNER_AD_UNIT_ID := ReleaseConfig.UNITY_ANDROID_BANNER_AD_UNIT_ID
const UNITY_ANDROID_REWARDED_AD_UNIT_ID := ReleaseConfig.UNITY_ANDROID_REWARDED_AD_UNIT_ID
const UNITY_ANDROID_INTERSTITIAL_AD_UNIT_ID := ReleaseConfig.UNITY_ANDROID_INTERSTITIAL_AD_UNIT_ID

var online := false
var initialized := false
var loading_ads_visible := false

func init() -> void:
    initialized = true
    online = false
    if Engine.has_singleton("UnityAdsBridge"):
        var bridge = Engine.get_singleton("UnityAdsBridge")
        if bridge.has_method("initialize"):
            bridge.initialize(UNITY_ANDROID_GAME_ID, false)

func set_online(value: bool) -> void:
    online = value

func is_online() -> bool:
    return online

func _daily_key() -> String:
    return Time.get_date_string_from_system()

func _sync_daily() -> void:
    var daily: Dictionary = SaveSystem.data["monetization"]["ads"]["daily"]
    var today := _daily_key()
    if str(daily.get("date", "")) != today:
        daily["date"] = today
        daily["revive_count"] = 0
        daily["double_coins_count"] = 0
        daily["bonus_coins_count"] = 0
        SaveSystem.save_now()

func show_loading_banners() -> void:
    if loading_ads_visible or bool(SaveSystem.data["monetization"].get("remove_ads", false)):
        return
    if not online:
        return
    if not Engine.has_singleton("UnityAdsBridge"):
        return
    if UNITY_ANDROID_BANNER_AD_UNIT_ID.is_empty():
        return
    var bridge = Engine.get_singleton("UnityAdsBridge")
    if bridge.has_method("show_loading_banners"):
        bridge.show_loading_banners(
            UNITY_ANDROID_BANNER_AD_UNIT_ID,
            UNITY_ANDROID_BANNER_AD_UNIT_ID
        )
        loading_ads_visible = true

func hide_loading_banners() -> void:
    if not loading_ads_visible:
        return
    if Engine.has_singleton("UnityAdsBridge"):
        var bridge = Engine.get_singleton("UnityAdsBridge")
        if bridge.has_method("hide_loading_banners"):
            bridge.hide_loading_banners()
    loading_ads_visible = false

func can_show_rewarded(slot_id: String) -> bool:
    if not online:
        return false
    _sync_daily()
    var daily: Dictionary = SaveSystem.data["monetization"]["ads"]["daily"]
    var caps := {"revive":5, "double_coins":10, "bonus_coins":3}
    if not caps.has(slot_id):
        return false
    return int(daily.get(slot_id + "_count", 0)) < int(caps[slot_id])

func show_rewarded(slot_id: String, callback: Callable) -> void:
    if not can_show_rewarded(slot_id):
        callback.call(false)
        return
    if not Engine.has_singleton("UnityAdsBridge"):
        callback.call(false)
        return
    if UNITY_ANDROID_REWARDED_AD_UNIT_ID.is_empty():
        callback.call(false)
        return
    var bridge = Engine.get_singleton("UnityAdsBridge")
    if not bridge.has_method("show_rewarded"):
        callback.call(false)
        return
    bridge.show_rewarded(UNITY_ANDROID_REWARDED_AD_UNIT_ID, func(ok:bool):
        if ok:
            _record_rewarded_success(slot_id)
        callback.call(ok)
    )


func _record_rewarded_success(slot_id:String) -> void:
    var daily:Dictionary=SaveSystem.data["monetization"]["ads"]["daily"]
    var key:=slot_id+"_count"
    daily[key]=int(daily.get(key,0))+1
    if slot_id=="revive": SaveSystem.data["stats"]["ads_revive_used"]+=1
    elif slot_id=="double_coins": SaveSystem.data["stats"]["ads_double_coins_used"]+=1
    elif slot_id=="bonus_coins": SaveSystem.data["stats"]["ads_bonus_coins_used"]+=1
    SaveSystem.save_now()

func daily_remaining(slot_id:String)->int:
    _sync_daily()
    var caps:Dictionary={"revive":5,"double_coins":10,"bonus_coins":3}
    if not caps.has(slot_id): return 0
    var daily:Dictionary=SaveSystem.data["monetization"]["ads"]["daily"]
    return maxi(0,int(caps[slot_id])-int(daily.get(slot_id+"_count",0)))
