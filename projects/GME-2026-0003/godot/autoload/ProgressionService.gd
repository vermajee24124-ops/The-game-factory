extends Node

const STAT_KEYS := ["top_speed","acceleration","handling","braking","boost_power","boost_duration","stability"]

func player_level() -> int:
    return int(SaveSystem.data["profile"].get("player_level", 0))

func owns_car(id: String) -> bool:
    return SaveSystem.data["progression"]["cars"]["owned"].has(id)

func select_car(id: String) -> bool:
    if not owns_car(id):
        return false
    SaveSystem.data["progression"]["cars"]["selected"] = id
    SaveSystem.data["profile"]["selected_car_id"] = id
    SaveSystem.save_now()
    return true

func can_buy_car(id: String) -> bool:
    var c: Dictionary = GameConfig.car(id)
    return not owns_car(id) and player_level() >= int(c.get("level", 1)) and EconomyService.can_afford_combo(int(c.get("cost_coins", c.get("cost", 0))), int(c.get("cost_diamonds", 0)))

func buy_car(id: String) -> bool:
    if not can_buy_car(id):
        return false
    var c: Dictionary = GameConfig.car(id)
    if not EconomyService.spend_combo(int(c.get("cost_coins", c.get("cost", 0))), int(c.get("cost_diamonds", 0)), "car_purchase"):
        return false
    SaveSystem.data["progression"]["cars"]["owned"].append(id)
    SaveSystem.save_now()
    return true

func upgrade_level(stat: String) -> int:
    return int(SaveSystem.data["progression"]["upgrades"].get(stat, 0))

func can_upgrade(stat: String) -> bool:
    if not STAT_KEYS.has(stat):
        return false
    var current := upgrade_level(stat)
    if current >= GameConfig.MAX_UPGRADE_LEVEL:
        return false
    var next_level := current + 1
    return player_level() >= GameConfig.UPGRADE_LEVEL_REQ[next_level] and EconomyService.coins() >= GameConfig.UPGRADE_COSTS[next_level]

func upgrade(stat: String) -> bool:
    if not can_upgrade(stat):
        return false
    var next_level := upgrade_level(stat) + 1
    if not EconomyService.spend_coins(GameConfig.UPGRADE_COSTS[next_level], "upgrade"):
        return false
    SaveSystem.data["progression"]["upgrades"][stat] = next_level
    SaveSystem.save_now()
    return true

func _grant_star_milestones() -> void:
    var total := 0
    for key in SaveSystem.data["campaign"]["levels"].keys():
        total += int(SaveSystem.data["campaign"]["levels"][key].get("best_stars", 0))
    SaveSystem.data["campaign"]["total_stars"] = total
    var thresholds: Array = [[30,1],[100,2],[250,3],[500,5],[1000,8]]
    for entry in thresholds:
        var threshold := int(entry[0])
        if total >= threshold and not SaveSystem.data["campaign"]["star_milestones_claimed"].has(threshold):
            EconomyService.grant_diamonds(int(entry[1]), "star_milestone")
            SaveSystem.data["campaign"]["star_milestones_claimed"].append(threshold)

func handle_race_result(result: Dictionary) -> void:
    var level := int(result.get("level_number", 1))
    var record := SaveSystem.level_record(level)
    var completed := bool(result.get("completed", false))
    var position := int(result.get("finish_position", 6))

    if completed and position <= GameConfig.UNLOCK_POSITION_REQUIREMENT:
        SaveSystem.data["profile"]["player_level"] = maxi(player_level(), level)
        SaveSystem.data["profile"]["highest_completed_level"] = maxi(int(SaveSystem.data["profile"].get("highest_completed_level", 0)), level)
        SaveSystem.data["profile"]["highest_unlocked_level"] = maxi(int(SaveSystem.data["profile"].get("highest_unlocked_level", 1)), level + 1)
        SaveSystem.data["profile"]["total_races_completed"] += 1
        record["failure_count"] = 0
    else:
        SaveSystem.data["profile"]["total_races_failed"] += 1
        record["failure_count"] = int(record.get("failure_count", 0)) + 1

    if position > 0:
        var old_pos := int(record.get("best_position", 0))
        record["best_position"] = position if old_pos == 0 else mini(old_pos, position)

    record["best_stars"] = maxi(int(record.get("best_stars", 0)), int(result.get("stars_earned", 0)))
    var race_time := float(result.get("race_time_sec", 0.0))
    var best_time := float(record.get("best_time_sec", 0.0))
    if race_time > 0.0 and (best_time <= 0.0 or race_time < best_time):
        record["best_time_sec"] = race_time

    if completed and not bool(record.get("first_clear_completed", false)):
        record["first_clear_completed"] = true

    _grant_star_milestones()

    var lvl := player_level()
    if lvl >= 35:
        SaveSystem.data["progression"]["abilities"]["slipstream_boost"] = true
    if lvl >= 38:
        SaveSystem.data["progression"]["abilities"]["clean_run_bonus"] = true
    if lvl >= 68:
        SaveSystem.data["progression"]["abilities"]["perfect_landing_boost"] = true

    SaveSystem.save_now()

func _buy_currency_item(item: Dictionary, reason: String) -> bool:
    var coins_cost:=int(item.get("cost_coins",0))
    var diamonds_cost:=int(item.get("cost_diamonds",0))
    if coins_cost>0 or diamonds_cost>0:
        return EconomyService.spend_combo(coins_cost,diamonds_cost,reason)
    var amount := int(item.get("cost", 0))
    if amount <= 0:
        return true
    var currency := str(item.get("currency", "coins"))
    if currency == "diamonds":
        return EconomyService.spend_diamonds(amount, reason)
    return EconomyService.spend_coins(amount, reason)

func buy_wheel(id: String) -> bool:
    var item: Dictionary = GameConfig.wheel(id)
    if player_level() < int(item.get("level", 1)):
        return false
    var owned: Array = SaveSystem.data["cosmetics"]["owned"]
    if not owned.has(id):
        var coins_cost:=int(item.get("cost_coins",item.get("cost",0)))
        var diamonds_cost:=int(item.get("cost_diamonds",0))
        if not EconomyService.spend_combo(coins_cost,diamonds_cost,"wheel_purchase"):
            return false
        owned.append(id)
    SaveSystem.data["cosmetics"]["equipped"]["wheel"] = id
    SaveSystem.save_now()
    return true

func buy_paint(id: String) -> bool:
    var item: Dictionary = GameConfig.paint(id)
    if player_level() < int(item.get("level", 1)):
        return false
    var owned: Array = SaveSystem.data["cosmetics"]["owned"]
    if not owned.has(id):
        if not _buy_currency_item(item, "paint_purchase"):
            return false
        owned.append(id)
    SaveSystem.data["cosmetics"]["equipped"]["paint"] = id
    SaveSystem.save_now()
    return true

func has_cosmetic(id: String) -> bool:
    return SaveSystem.data["cosmetics"]["owned"].has(id)


func owns_skin(id: String) -> bool:
    return SaveSystem.data["cosmetics"]["owned"].has(id)

func equip_skin(id: String) -> bool:
    if not owns_skin(id) or ContentCatalog.skin(id).is_empty():
        return false
    SaveSystem.data["cosmetics"]["equipped"]["skin"] = id
    SaveSystem.save_now()
    return true

func grant_skin(id: String) -> bool:
    if ContentCatalog.skin(id).is_empty():
        return false
    var owned:Array=SaveSystem.data["cosmetics"]["owned"]
    if owned.has(id):
        EconomyService.grant_coins(250, "duplicate_skin_conversion")
        return false
    owned.append(id)
    SaveSystem.save_now()
    return true

func owns_card(id: String) -> bool:
    return SaveSystem.data["progression"]["cards"]["owned"].has(id)

func grant_card(id: String) -> bool:
    if ContentCatalog.card(id).is_empty():
        return false
    var owned:Array=SaveSystem.data["progression"]["cards"]["owned"]
    if owned.has(id):
        EconomyService.grant_coins(120, "duplicate_card_conversion")
        return false
    owned.append(id)
    SaveSystem.save_now()
    return true

func toggle_card_equip(id: String) -> bool:
    if not owns_card(id):
        return false
    var equipped:Array=SaveSystem.data["progression"]["cards"]["equipped"]
    if equipped.has(id):
        if equipped.size()<=1:
            return false
        equipped.erase(id)
    elif equipped.size()<3:
        equipped.append(id)
    else:
        return false
    SaveSystem.save_now()
    return true

func equipped_cards()->Array:
    return SaveSystem.data["progression"]["cards"].get("equipped",["card_01"])

func card_bonus(stat:String)->float:
    var total:=0.0
    for id in equipped_cards():
        var c:Dictionary=ContentCatalog.card(str(id))
        if str(c.get("type",""))==stat:
            total+=float(c.get("value",0.0))
    return total

func coin_multiplier()->float:
    return 1.0 + card_bonus("coin_multiplier") + car_ability_bonus("coin_multiplier") + wheel_ability_bonus("coin_multiplier")

func damage_multiplier()->float:
    return maxf(0.65, 1.0 - card_bonus("damage_reduction") - car_ability_bonus("damage_reduction") - wheel_ability_bonus("damage_reduction"))

func top_speed_bonus()->float:
    return card_bonus("top_speed") + car_ability_bonus("speed") * 10.0 + wheel_ability_bonus("speed") * 8.0

func acceleration_bonus()->float:
    return card_bonus("acceleration")

func handling_bonus()->float:
    return card_bonus("handling") + car_ability_bonus("handling") + wheel_ability_bonus("handling")

func braking_bonus()->float:
    return card_bonus("braking")

func boost_power_bonus()->float:
    return card_bonus("boost_power") + car_ability_bonus("boost_power") * 10.0 + wheel_ability_bonus("boost_power") * 8.0

func boost_duration_bonus()->float:
    return card_bonus("boost_duration")

func stability_bonus()->float:
    return card_bonus("stability") + car_ability_bonus("stability") + wheel_ability_bonus("stability")

func boost_efficiency_bonus()->float:
    return minf(0.25,car_ability_bonus("boost_efficiency")+wheel_ability_bonus("boost_efficiency"))

func launch_bonus()->float:
    return car_ability_bonus("launch_boost")+wheel_ability_bonus("launch_boost")


func equipped_car_ability()->Dictionary:
    var id:=str(SaveSystem.data["progression"]["cars"]["selected"])
    return GameConfig.car(id)

func equipped_wheel_ability()->Dictionary:
    var id:=str(SaveSystem.data["cosmetics"]["equipped"].get("wheel","wheel_stock"))
    return GameConfig.wheel(id)

func car_ability_bonus(type:String)->float:
    var c:=equipped_car_ability()
    return float(c.get("ability_value",0.0)) if str(c.get("ability_type",""))==type else 0.0

func wheel_ability_bonus(type:String)->float:
    var w:=equipped_wheel_ability()
    return float(w.get("ability_value",0.0)) if str(w.get("ability_type",""))==type else 0.0


func grant_car(id:String) -> bool:
    var c:Dictionary=GameConfig.car(id)
    if c.is_empty(): return false
    var owned:Array=SaveSystem.data["progression"]["cars"]["owned"]
    if owned.has(id):
        EconomyService.grant_coins(500,"duplicate_iap_car_conversion")
        return false
    owned.append(id)
    SaveSystem.save_now()
    return true

func grant_wheel(id:String) -> bool:
    var item:Dictionary=GameConfig.wheel(id)
    if item.is_empty(): return false
    var owned:Array=SaveSystem.data["cosmetics"]["owned"]
    if owned.has(id):
        EconomyService.grant_coins(200,"duplicate_iap_wheel_conversion")
        return false
    owned.append(id)
    SaveSystem.save_now()
    return true
