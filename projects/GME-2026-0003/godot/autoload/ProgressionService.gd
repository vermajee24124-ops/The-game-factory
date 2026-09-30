extends Node
const STAT_KEYS:=["top_speed","acceleration","handling","braking","boost_power","boost_duration","stability"]

func player_level()->int:return int(SaveSystem.data["profile"]["player_level"])
func owns_car(id:String)->bool:return SaveSystem.data["progression"]["cars"]["owned"].has(id)

func select_car(id:String)->bool:
    if not owns_car(id):return false
    SaveSystem.data["progression"]["cars"]["selected"]=id
    SaveSystem.data["profile"]["selected_car_id"]=id
    SaveSystem.save_now()
    return true

func can_upgrade(stat:String)->bool:
    if not STAT_KEYS.has(stat):return false
    var cur:=int(SaveSystem.data["progression"]["upgrades"].get(stat,0))
    if cur>=10:return false
    var nxt:=cur+1
    return player_level()>=GameConfig.UPGRADE_LEVEL_REQ[nxt] and EconomyService.coins()>=GameConfig.UPGRADE_COSTS[nxt]

func upgrade(stat:String)->bool:
    if not can_upgrade(stat):return false
    var nxt:=int(SaveSystem.data["progression"]["upgrades"][stat])+1
    if not EconomyService.spend_coins(GameConfig.UPGRADE_COSTS[nxt],"upgrade"):return false
    SaveSystem.data["progression"]["upgrades"][stat]=nxt
    SaveSystem.save_now()
    return true

func buy_car(id:String)->bool:
    var c:=GameConfig.car(id)
    if owns_car(id) or player_level()<int(c.level) or EconomyService.coins()<int(c.cost):return false
    if not EconomyService.spend_coins(int(c.cost),"car_purchase"):return false
    SaveSystem.data["progression"]["cars"]["owned"].append(id)
    SaveSystem.save_now()
    return true

func handle_race_result(result:Dictionary)->void:
    var level:=int(result.level_number)
    var rec:=SaveSystem.level_record(level)
    if bool(result.completed) and int(result.finish_position)<=5:
        SaveSystem.data["profile"]["player_level"]=maxi(player_level(),level)
        SaveSystem.data["profile"]["highest_completed_level"]=maxi(int(SaveSystem.data["profile"]["highest_completed_level"]),level)
        SaveSystem.data["profile"]["highest_unlocked_level"]=maxi(int(SaveSystem.data["profile"]["highest_unlocked_level"]),level+1)
        SaveSystem.data["profile"]["total_races_completed"]+=1
        rec["failure_count"]=0
    else:
        SaveSystem.data["profile"]["total_races_failed"]+=1
        rec["failure_count"]=int(rec.failure_count)+1
    var p:=int(result.finish_position)
    if p>0: rec["best_position"]=p if int(rec.best_position)==0 else mini(int(rec.best_position),p)
    rec["best_stars"]=maxi(int(rec.best_stars),int(result.stars_earned))
    var tm:=float(result.race_time_sec)
    if tm>0 and (float(rec.best_time_sec)<=0 or tm<float(rec.best_time_sec)):rec["best_time_sec"]=tm
    if bool(result.completed) and not bool(rec.first_clear_completed):rec["first_clear_completed"]=true
    var total:=0
    for k in SaveSystem.data["campaign"]["levels"].keys():total+=int(SaveSystem.data["campaign"]["levels"][k].best_stars)
    SaveSystem.data["campaign"]["total_stars"]=total
    var lvl:=player_level()
    if lvl>=35:SaveSystem.data["progression"]["abilities"]["slipstream_boost"]=true
    if lvl>=38:SaveSystem.data["progression"]["abilities"]["clean_run_bonus"]=true
    if lvl>=68:SaveSystem.data["progression"]["abilities"]["perfect_landing_boost"]=true
    SaveSystem.save_now()
