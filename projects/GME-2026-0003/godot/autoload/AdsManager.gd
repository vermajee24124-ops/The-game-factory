extends Node

const UNITY_ANDROID_GAME_ID := ReleaseConfig.UNITY_ANDROID_GAME_ID
const UNITY_IOS_GAME_ID := ReleaseConfig.UNITY_IOS_GAME_ID
const UNITY_ANDROID_BANNER_AD_UNIT_ID := ReleaseConfig.UNITY_ANDROID_BANNER_AD_UNIT_ID
const UNITY_ANDROID_REWARDED_AD_UNIT_ID := ReleaseConfig.UNITY_ANDROID_REWARDED_AD_UNIT_ID
const UNITY_ANDROID_INTERSTITIAL_AD_UNIT_ID := ReleaseConfig.UNITY_ANDROID_INTERSTITIAL_AD_UNIT_ID

const INTERSTITIAL_MIN_GAP_SEC := 180
const INTERSTITIAL_MIN_RESULTS := 3

var online := false
var initialized := false
var loading_ads_visible := false
var _loading_ads_requested := false
var _native_initialized := false
var _reward_callback: Callable
var _reward_slot := ""
var _reward_granted := false
var _signals_connected := false

func _unity_bridge():
    # Godot Android plugins expose the singleton name returned by getPluginName().
    if Engine.has_singleton("TurboUnityAds"):
        return Engine.get_singleton("TurboUnityAds")
    if Engine.has_singleton("UnityAdsBridge"):
        return Engine.get_singleton("UnityAdsBridge")
    if Engine.has_singleton("UnityAdsGodotAndroid"):
        return Engine.get_singleton("UnityAdsGodotAndroid")
    return null

func _consent_allows_ads() -> bool:
    var status := str(SaveSystem.data.get("privacy", {}).get("consent_status", "unknown"))
    return status == "non_personalized"

func init() -> void:
    initialized = true
    online = false
    if OS.has_feature("web"):
        online = WebAdsManager.is_available()
        return
    if not _consent_allows_ads():
        return
    var bridge = _unity_bridge()
    if bridge == null:
        return
    if not _signals_connected:
        if bridge.has_signal("unity_ads_initialized"):
            bridge.unity_ads_initialized.connect(_on_native_initialized)
        if bridge.has_signal("unity_ads_rewarded"):
            bridge.unity_ads_rewarded.connect(_on_native_rewarded)
        if bridge.has_signal("unity_ads_closed"):
            bridge.unity_ads_closed.connect(_on_native_ad_closed)
        _signals_connected = true
    if bridge.has_method("initialize"):
        bridge.initialize(UNITY_ANDROID_GAME_ID, false)
    elif bridge.has_method("initialise"):
        bridge.initialise(UNITY_ANDROID_GAME_ID, false)

func _on_native_initialized(ok: bool) -> void:
    _native_initialized = bool(ok)
    online = _native_initialized and _consent_allows_ads()
    if not online:
        return
    var bridge = _unity_bridge()
    if bridge == null:
        return
    if bridge.has_method("loadInterstitialAd") and not UNITY_ANDROID_INTERSTITIAL_AD_UNIT_ID.is_empty():
        bridge.loadInterstitialAd(UNITY_ANDROID_INTERSTITIAL_AD_UNIT_ID)
    if bridge.has_method("loadRewardedAd") and not UNITY_ANDROID_REWARDED_AD_UNIT_ID.is_empty():
        bridge.loadRewardedAd(UNITY_ANDROID_REWARDED_AD_UNIT_ID)
    if _loading_ads_requested:
        _show_native_startup_banners()

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
    _loading_ads_requested = true
    if loading_ads_visible or not online:
        return
    if OS.has_feature("web"):
        WebAdsManager.show_startup_banners()
        loading_ads_visible = true
        return
    _show_native_startup_banners()

func _show_native_startup_banners() -> void:
    var bridge = _unity_bridge()
    if bridge == null or not online or not _native_initialized:
        return
    if UNITY_ANDROID_BANNER_AD_UNIT_ID.is_empty():
        return
    if bridge.has_method("showLoadingBanners"):
        if not bool(bridge.showLoadingBanners(UNITY_ANDROID_BANNER_AD_UNIT_ID, UNITY_ANDROID_BANNER_AD_UNIT_ID)):
            return
    elif bridge.has_method("show_loading_banners"):
        if not bool(bridge.show_loading_banners(UNITY_ANDROID_BANNER_AD_UNIT_ID, UNITY_ANDROID_BANNER_AD_UNIT_ID)):
            return
    elif bridge.has_method("showBanner"):
        bridge.showBanner(UNITY_ANDROID_BANNER_AD_UNIT_ID, true)
        bridge.showBanner(UNITY_ANDROID_BANNER_AD_UNIT_ID, false)
    else:
        return
    loading_ads_visible = true

func hide_loading_banners() -> void:
    _loading_ads_requested = false
    if not loading_ads_visible:
        return
    if OS.has_feature("web"):
        WebAdsManager.hide_startup_banners()
    else:
        var bridge = _unity_bridge()
        if bridge != null:
            if bridge.has_method("hideLoadingBanners"):
                bridge.hideLoadingBanners()
            elif bridge.has_method("hide_loading_banners"):
                bridge.hide_loading_banners()
            elif bridge.has_method("hideBanner"):
                bridge.hideBanner()
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
    if OS.has_feature("web"):
        WebAdsManager.show_rewarded(func(ok:bool):
            if ok:
                _record_rewarded_success(slot_id)
            callback.call(ok)
        )
        return
    var bridge = _unity_bridge()
    if bridge == null or UNITY_ANDROID_REWARDED_AD_UNIT_ID.is_empty() or not _native_initialized:
        callback.call(false)
        return
    _reward_callback = callback
    _reward_slot = slot_id
    _reward_granted = false
    if bridge.has_method("showRewardedAd"):
        var accepted:bool = bool(bridge.showRewardedAd(UNITY_ANDROID_REWARDED_AD_UNIT_ID))
        if not accepted:
            _clear_reward(false)
    elif bridge.has_method("show_rewarded"):
        bridge.show_rewarded(UNITY_ANDROID_REWARDED_AD_UNIT_ID, func(ok:bool):
            if ok:
                _record_rewarded_success(slot_id)
            callback.call(ok)
        )
    else:
        _clear_reward(false)

func maybe_show_midgame() -> void:
    if not online:
        return
    var daily:Dictionary = SaveSystem.data["monetization"]["ads"]["interstitial"]
    var now := Time.get_unix_time_from_system()
    var last_shown := int(daily.get("last_shown_unix", 0))
    var results_since := int(daily.get("results_since_last", 0)) + 1
    daily["results_since_last"] = results_since
    if results_since < INTERSTITIAL_MIN_RESULTS:
        SaveSystem.save_now()
        return
    if last_shown > 0 and now - last_shown < INTERSTITIAL_MIN_GAP_SEC:
        SaveSystem.save_now()
        return
    if OS.has_feature("web"):
        WebAdsManager.show_midgame()
        daily["last_shown_unix"] = now
        daily["results_since_last"] = 0
        SaveSystem.save_now()
        return
    var bridge = _unity_bridge()
    if bridge == null or UNITY_ANDROID_INTERSTITIAL_AD_UNIT_ID.is_empty() or not _native_initialized:
        SaveSystem.save_now()
        return
    var accepted := false
    if bridge.has_method("showInterstitialAd"):
        accepted = bool(bridge.showInterstitialAd(UNITY_ANDROID_INTERSTITIAL_AD_UNIT_ID))
    elif bridge.has_method("show_interstitial"):
        bridge.show_interstitial(UNITY_ANDROID_INTERSTITIAL_AD_UNIT_ID)
        accepted = true
    if accepted:
        daily["last_shown_unix"] = now
        daily["results_since_last"] = 0
    SaveSystem.save_now()

func _record_rewarded_success(slot_id:String) -> void:
    var daily:Dictionary=SaveSystem.data["monetization"]["ads"]["daily"]
    var key:=slot_id+"_count"
    daily[key]=int(daily.get(key,0))+1
    if slot_id=="revive": SaveSystem.data["stats"]["ads_revive_used"]+=1
    elif slot_id=="double_coins": SaveSystem.data["stats"]["ads_double_coins_used"]+=1
    elif slot_id=="bonus_coins": SaveSystem.data["stats"]["ads_bonus_coins_used"]+=1
    SaveSystem.save_now()

func _on_native_rewarded() -> void:
    if not _reward_callback.is_valid() or _reward_granted:
        return
    _reward_granted = true
    var slot := _reward_slot
    _record_rewarded_success(slot)
    var cb := _reward_callback
    _reward_callback = Callable()
    _reward_slot = ""
    cb.call(true)

func _on_native_ad_closed() -> void:
    if not _reward_callback.is_valid() or _reward_granted:
        return
    _clear_reward(false)

func _clear_reward(ok:bool) -> void:
    if not _reward_callback.is_valid():
        return
    var cb := _reward_callback
    _reward_callback = Callable()
    _reward_slot = ""
    _reward_granted = false
    cb.call(ok)

func daily_remaining(slot_id:String)->int:
    _sync_daily()
    var caps:Dictionary={"revive":5,"double_coins":10,"bonus_coins":3}
    if not caps.has(slot_id): return 0
    var daily:Dictionary=SaveSystem.data["monetization"]["ads"]["daily"]
    return maxi(0,int(caps[slot_id])-int(daily.get(key_for_slot(slot_id),0)))

func key_for_slot(slot_id:String)->String:
    return slot_id+"_count"
