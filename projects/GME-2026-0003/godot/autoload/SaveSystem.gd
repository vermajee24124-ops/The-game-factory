extends Node
const SAVE_DIR := "user://save"
const SAVE_PATH := SAVE_DIR + "/turbo_rush_save.json"
const BACKUP_PATH := SAVE_DIR + "/turbo_rush_save.backup.json"
const TEMP_PATH := SAVE_DIR + "/turbo_rush_save.tmp"
var data:Dictionary = {}

func _ready()->void:
    load_or_create()

func _defaults()->Dictionary:
    return {
        "meta":{"schema_version":1,"game_version":GameConfig.GAME_VERSION,"save_id":str(Time.get_ticks_usec()),"created_at_unix":Time.get_unix_time_from_system(),"updated_at_unix":Time.get_unix_time_from_system(),"last_launch_unix":Time.get_unix_time_from_system()},
        "profile":{"player_level":0,"highest_completed_level":0,"highest_unlocked_level":1,"selected_level":1,"selected_car_id":"rookie_gt","onboarding_completed":false,"total_races_completed":0,"total_races_failed":0},
        "currencies":{"coins":0,"diamonds":0},
        "campaign":{"total_stars":0,"star_milestones_claimed":[],"levels":{}},
        "progression":{"upgrades":{"top_speed":0,"acceleration":0,"handling":0,"braking":0,"boost_power":0,"boost_duration":0,"stability":0},"cars":{"owned":["rookie_gt"],"selected":"rookie_gt"},"abilities":{"slipstream_boost":false,"clean_run_bonus":false,"perfect_landing_boost":false},"cards":{"owned":["card_01"],"equipped":["card_01"]}},
        "cosmetics":{"owned":["wheel_stock","paint_red","material_basic","skin_01"],"equipped":{"wheel":"wheel_stock","paint":"paint_red","material":"material_basic","decal":"none","underglow":"none","skin":"skin_01"}},
        "settings":{"audio":{"master_volume":1.0,"music_volume":1.0,"sfx_volume":1.0,"engine_volume":1.0},"controls":{"steering_sensitivity":0.5,"auto_acceleration":true,"manual_brake_enabled":false,"boost_tap_mode":false,"large_controls":false},"graphics":{"quality":"medium","target_fps":60,"reduce_motion":false},"haptics_enabled":true,"language":"en"},
        "monetization":{"remove_ads":false,"ads":{"daily":{"date":"1970-01-01","revive_count":0,"double_coins_count":0,"bonus_coins_count":0},"interstitial":{"first_launch_unix":0,"last_shown_unix":0}},"iap":{"owned_products":[],"pending_purchase_grants":[],"transactions":[],"last_restore_unix":0}},
        "privacy":{"consent_version":1,"consent_status":"unknown","personalized_ads":false,"analytics_allowed":false,"att_status":"not_required","consent_timestamp_unix":0},
        "stats":{"races_started":0,"races_completed":0,"races_won":0,"races_top3":0,"races_wrecked":0,"revives_used":0,"diamond_pickups_collected":0,"chests_opened":0,"coins_earned_lifetime":0,"diamonds_earned_lifetime":0,"coins_spent_lifetime":0,"diamonds_spent_lifetime":0,"ads_revive_used":0,"ads_double_coins_used":0,"ads_bonus_coins_used":0},
        "integrity":{"checksum":"","checksum_version":1,"debug_save":true}
    }

func _payload_without_checksum(source:Dictionary)->String:
    var copy:Dictionary = source.duplicate(true)
    copy["integrity"]["checksum"] = ""
    return JSON.stringify(copy)

func _checksum_for(source:Dictionary)->String:
    var h:=HashingContext.new()
    h.start(HashingContext.HASH_SHA256)
    h.update(_payload_without_checksum(source).to_utf8_buffer())
    return h.finish().hex_encode()

func _read_json(path:String)->Dictionary:
    if not FileAccess.file_exists(path): return {}
    var parsed=JSON.parse_string(FileAccess.get_file_as_string(path))
    return parsed if parsed is Dictionary else {}

func _validate_loaded(candidate:Dictionary)->bool:
    return str(candidate.get("integrity",{}).get("checksum","")) == _checksum_for(candidate)

func load_or_create()->void:
    DirAccess.make_dir_recursive_absolute(SAVE_DIR)
    var loaded:=_read_json(SAVE_PATH)
    if loaded.is_empty(): loaded=_read_json(BACKUP_PATH)
    data=loaded if (not loaded.is_empty() and _validate_loaded(loaded)) else _defaults()
    _repair_invariants()
    save_now()

func _repair_invariants()->void:
    var defaults:=_defaults()
    for key in defaults.keys():
        if not data.has(key): data[key]=defaults[key]
    data["currencies"]["coins"]=clampi(int(data["currencies"].get("coins",0)),0,99999999)
    data["currencies"]["diamonds"]=clampi(int(data["currencies"].get("diamonds",0)),0,9999999)
    data["profile"]["highest_unlocked_level"]=maxi(1,int(data["profile"].get("highest_unlocked_level",1)))
    data["profile"]["selected_level"]=clampi(int(data["profile"].get("selected_level",1)),1,int(data["profile"]["highest_unlocked_level"]))
    var owned:Array=data["progression"]["cars"].get("owned",["rookie_gt"])
    if not owned.has("rookie_gt"): owned.append("rookie_gt")
    data["progression"]["cars"]["owned"]=owned
    if not owned.has(data["progression"]["cars"].get("selected","rookie_gt")):
        data["progression"]["cars"]["selected"]="rookie_gt"
    data["profile"]["selected_car_id"]=data["progression"]["cars"]["selected"]

    if not data["progression"].has("cards"):
        data["progression"]["cards"]={"owned":["card_01"],"equipped":["card_01"]}
    var owned_cards:Array=data["progression"]["cards"].get("owned",["card_01"])
    if not owned_cards.has("card_01"): owned_cards.append("card_01")
    data["progression"]["cards"]["owned"]=owned_cards
    if not data["progression"]["cards"].has("equipped"): data["progression"]["cards"]["equipped"]=["card_01"]
    var equipped_cards:Array=data["progression"]["cards"]["equipped"]
    var repaired_equipped:Array=[]
    for card_id in equipped_cards:
        if owned_cards.has(card_id) and not repaired_equipped.has(card_id): repaired_equipped.append(card_id)
        if repaired_equipped.size()>=3: break
    if repaired_equipped.is_empty(): repaired_equipped=["card_01"]
    data["progression"]["cards"]["equipped"]=repaired_equipped

    if not data["cosmetics"].has("owned"): data["cosmetics"]["owned"]=[]
    if not data["cosmetics"]["owned"].has("skin_01"): data["cosmetics"]["owned"].append("skin_01")
    if not data["cosmetics"]["equipped"].has("skin"): data["cosmetics"]["equipped"]["skin"]="skin_01"


func save_now()->void:
    DirAccess.make_dir_recursive_absolute(SAVE_DIR)
    data["meta"]["updated_at_unix"]=Time.get_unix_time_from_system()
    data["integrity"]["checksum"]=""
    data["integrity"]["checksum"]=_checksum_for(data)
    if FileAccess.file_exists(SAVE_PATH):
        var b:=FileAccess.open(BACKUP_PATH,FileAccess.WRITE)
        if b:
            b.store_string(FileAccess.get_file_as_string(SAVE_PATH))
            b.close()
    var f:=FileAccess.open(TEMP_PATH,FileAccess.WRITE)
    if not f: return
    f.store_string(JSON.stringify(data,"  "))
    f.close()
    if FileAccess.file_exists(SAVE_PATH): DirAccess.remove_absolute(SAVE_PATH)
    DirAccess.rename_absolute(TEMP_PATH,SAVE_PATH)
    EventBus.save_changed.emit()

func mark_launch()->void:
    data["meta"]["last_launch_unix"]=Time.get_unix_time_from_system()
    save_now()

func level_record(level:int)->Dictionary:
    var k:=str(level)
    if not data["campaign"]["levels"].has(k):
        data["campaign"]["levels"][k]={"best_position":0,"best_stars":0,"best_time_sec":0.0,"first_clear_completed":false,"failure_count":0}
    return data["campaign"]["levels"][k]

func get_level_failures(level:int)->int:
    return int(data["campaign"]["levels"].get(str(level),{}).get("failure_count",0))
