extends Node

const WORLDS := {
    "new_york_city_rush": {"unlock_coins": 0, "unlock_level": 1},
    "dubai_desert_drift": {"unlock_coins": 500, "unlock_level": 10},
    "singapore_garden_run": {"unlock_coins": 1000, "unlock_level": 20},
    "london_fog_ramp": {"unlock_coins": 2000, "unlock_level": 35},
    "tokyo_neon_nights": {"unlock_coins": 5000, "unlock_level": 50},
    "space_station": {"unlock_stars": 24},
}

const VEHICLES := {
    "Blocky Buggy": {"tier": 1, "cost": 0},
    "Mini Truck": {"tier": 1, "cost": 250},
    "Scooter Bike": {"tier": 1, "cost": 400},
    "Wooden Cart": {"tier": 1, "cost": 650},
    "Monster Truck": {"tier": 2, "cost": 1500},
    "Desert Rover": {"tier": 2, "cost": 2000},
    "Neon Bike": {"tier": 2, "cost": 2500},
    "Ice Slider": {"tier": 2, "cost": 3000},
    "Dragon Rider": {"tier": 3, "cost": 50},
    "UFO Hover": {"tier": 3, "cost": 75},
    "Shark Mobile": {"tier": 3, "cost": 90},
    "Robot Walker": {"tier": 3, "cost": 110},
    "Golden Tank": {"tier": 4, "cost": 20},
    "Phoenix Rider": {"tier": 4, "cost": 25},
    "Diamond Car": {"tier": 4, "cost": 30},
    "Galaxy Racer": {"tier": 4, "cost": 35},
}

const POWERUPS := ["magnet", "shield", "boost", "multiplier", "diamond_rush", "float"]
const UPGRADE_STATS := ["speed", "handling", "jump", "armor", "magnet", "boost"]
