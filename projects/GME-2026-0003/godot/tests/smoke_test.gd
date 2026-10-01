extends SceneTree

func _initialize() -> void:
    var failures: Array[String] = []
    var game_config:Node=get_root().get_node("GameConfig")
    var level_generator:Node=get_root().get_node("LevelGenerator")
    var reward_service:Node=get_root().get_node("RewardService")
    var catalog:Node=get_root().get_node("ContentCatalog")

    if game_config.CARS.size() != 54:
        failures.append("expected 54 cars, got %d" % game_config.CARS.size())
    if game_config.WHEELS.size() != 60:
        failures.append("expected 60 wheels, got %d" % game_config.WHEELS.size())
    if game_config.PAINTS.size() < 8:
        failures.append("paint catalog")
    if catalog.SKINS.size() != 54:
        failures.append("expected 54 skins")
    if catalog.CARDS.size() != 48:
        failures.append("expected 48 cards")
    if catalog.BUNDLES.size() != 10:
        failures.append("expected 10 products")

    var checkpoints: Array[int] = [1, 5, 10, 15, 20, 27, 30, 50, 100, 250, 500, 1000, 5000, 10000]
    for level in checkpoints:
        var definition: Dictionary = level_generator.generate(level)
        if int(definition.get("level_number", 0)) != level:
            failures.append("level number %d" % level)
        if int(definition.get("seed", 0)) == 0:
            failures.append("seed %d" % level)
        if definition.get("race_type", "") == "Elite" and not bool(definition.get("has_diamond_pickup", false)):
            failures.append("elite diamond %d" % level)
        if int(definition.get("traffic_count", 0)) > game_config.MAX_TRAFFIC:
            failures.append("traffic cap %d" % level)
        if int(definition.get("obstacle_count", 0)) > game_config.MAX_OBSTACLES:
            failures.append("obstacle cap %d" % level)
        if int(definition.get("coin_count", 0)) > game_config.MAX_TRACK_COINS:
            failures.append("coin cap %d" % level)
        if float(definition.get("track_length_m", 0.0)) <= 0.0:
            failures.append("track length %d" % level)
        if definition.get("track_modules", []).size() < 3:
            failures.append("too few modules %d" % level)

    for level in range(1, 10001):
        var first: Dictionary = level_generator.generate(level)
        var second: Dictionary = level_generator.generate(level)
        if first.get("seed") != second.get("seed") or first.get("track_modules") != second.get("track_modules"):
            failures.append("non-deterministic level %d" % level)
            break
        var typ := str(first.get("race_type", ""))
        var t := float(first.get("target_time_sec", 0.0))
        if typ == "Standard" and (t < 120.0 or t > 170.0):
            failures.append("standard target time")
            break
        if typ == "Sprint" and (t < 85.0 or t > 115.0):
            failures.append("sprint target time")
            break
        if typ == "Endurance" and (t < 175.0 or t > 215.0):
            failures.append("endurance target time")
            break
        if typ == "Elite" and (t < 130.0 or t > 180.0):
            failures.append("elite target time")
            break

    var stars: int = reward_service.stars_for(1, 100.0)
    if stars != 3:
        failures.append("star formula")
    if reward_service.rank_reward(1, 1, false) <= reward_service.rank_reward(1, 6, false):
        failures.append("rank reward ordering")

    if failures.is_empty():
        print("Turbo Rush smoke tests passed")
        print("Turbo Rush smoke tests passed")
        quit(0)
        return
    print("Turbo Rush smoke tests FAILED: ", failures)
    quit(1)
    return
