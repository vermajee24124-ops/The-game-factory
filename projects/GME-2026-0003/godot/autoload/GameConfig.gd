extends Node

const GAME_VERSION := "2.0.0"
const MAX_UPGRADE_LEVEL := 10
const REVIVE_DIAMOND_COST := 5
const PLAYER_CAR_COUNT := 1
const AI_CAR_COUNT := 5
const TOTAL_RACERS := 6
const COUNTDOWN_SECONDS := 3.0
const UNLOCK_POSITION_REQUIREMENT := 5
const EXPECTED_SPEED_FACTOR := 0.66
const MAX_TRACK_COINS := 260
const MAX_TRAFFIC := 45
const MAX_OBSTACLES := 40
const UPGRADE_COSTS := [0,120,220,380,650,1050,1700,2700,4300,6800,10500]
const UPGRADE_LEVEL_REQ := [0,1,4,8,13,20,28,38,50,65,85]

var CARS: Dictionary = {
 "rookie_gt":{"name":"Rookie GT","level":1,"cost":0,"cost_coins":0,"cost_diamonds":0,"top_speed":140.0,"accel":8.0,"grip":1.00,"brake":12.0,"boost_power":25.0,"boost_duration":2.0,"stability":1.00,"ability":"Balanced","ability_type":"none","ability_value":0.0},
 "street_king":{"name":"Street King","level":5,"cost":2000,"cost_coins":2000,"cost_diamonds":15,"top_speed":148.0,"accel":8.6,"grip":1.03,"brake":12.5,"boost_power":27.0,"boost_duration":2.1,"stability":1.00,"ability":"Launch Burst","ability_type":"launch_boost","ability_value":0.08},
 "turbo_viper":{"name":"Turbo Viper","level":12,"cost":0,"cost_coins":5000,"cost_diamonds":30,"top_speed":155.0,"accel":9.1,"grip":1.01,"brake":12.2,"boost_power":32.0,"boost_duration":2.2,"stability":0.98,"ability":"Nitro Saver","ability_type":"boost_efficiency","ability_value":0.10},
 "canyon_falcon":{"name":"Canyon Falcon","level":20,"cost":0,"cost_coins":10000,"cost_diamonds":45,"top_speed":149.0,"accel":8.8,"grip":1.05,"brake":13.2,"boost_power":28.0,"boost_duration":2.2,"stability":1.08,"ability":"Impact Guard","ability_type":"damage_reduction","ability_value":0.08},
 "circuit_phantom":{"name":"Circuit Phantom","level":35,"cost":0,"cost_coins":20000,"cost_diamonds":70,"top_speed":162.0,"accel":9.6,"grip":1.06,"brake":13.0,"boost_power":34.0,"boost_duration":2.3,"stability":1.02,"ability":"Apex Grip","ability_type":"handling","ability_value":0.06},
 "hyper_nova":{"name":"Hyper Nova","level":55,"cost":0,"cost_coins":45000,"cost_diamonds":110,"top_speed":170.0,"accel":10.2,"grip":1.04,"brake":13.5,"boost_power":38.0,"boost_duration":2.4,"stability":1.00,"ability":"Turbo Core","ability_type":"boost_power","ability_value":0.08}
}

var WHEELS: Dictionary = {
 "wheel_stock":{"name":"Stock","level":1,"cost":0,"cost_coins":0,"cost_diamonds":0,"premium":false,"ability":"Balanced Wheels","ability_type":"none","ability_value":0.0},
 "street_steel":{"name":"Street Steel","level":3,"cost":0,"cost_coins":500,"cost_diamonds":5,"premium":false,"ability":"Launch Grip","ability_type":"launch_boost","ability_value":0.03},
 "alloy_sport":{"name":"Alloy Sport","level":8,"cost":0,"cost_coins":1200,"cost_diamonds":8,"premium":false,"ability":"Apex Grip","ability_type":"handling","ability_value":0.03},
 "turbo_fan":{"name":"Turbo Fan","level":15,"cost":0,"cost_coins":2000,"cost_diamonds":12,"premium":false,"ability":"Nitro Saver","ability_type":"boost_efficiency","ability_value":0.05},
 "carbon_track":{"name":"Carbon Track","level":30,"cost":0,"cost_coins":4500,"cost_diamonds":20,"premium":false,"ability":"Impact Guard","ability_type":"damage_reduction","ability_value":0.04},
 "chrome_racer":{"name":"Chrome Racer","level":50,"cost":0,"cost_coins":7500,"cost_diamonds":28,"premium":false,"ability":"Coin Rush","ability_type":"coin_multiplier","ability_value":0.03},
 "neon_glow":{"name":"Neon Glow","level":65,"cost":0,"cost_coins":12000,"cost_diamonds":40,"premium":true,"ability":"Turbo Core","ability_type":"boost_power","ability_value":0.04},
 "golden_crown":{"name":"Golden Crown","level":80,"cost":0,"cost_coins":18000,"cost_diamonds":55,"premium":true,"ability":"Velocity Core","ability_type":"speed","ability_value":0.025},
 "nova_edge":{"name":"Nova Edge","level":100,"cost":0,"cost_coins":26000,"cost_diamonds":75,"premium":true,"ability":"Stability Pro","ability_type":"stability","ability_value":0.04}
}

var TIRES: Dictionary = {}

const TIRE_NAMES := ["Street Comfort","Touring Allrounder","Urban Sport","Performance Street","Sport Grip","Sport Plus","Semi Slick A","Semi Slick B","Track Slick A","Track Slick B","Track Endurance","Track Qualifier","Rain Touring","Rain Sport","Wet Grip Pro","Aqua Channel","Gravel Runner","Gravel Rally","Loose Surface","Dirt Sprint","Rally Mixed","Rally Soft","Rally Medium","Rally Hard","Snow Touring","Ice Studded","Winter Sport","Frost Control","Sand Runner","Desert Rally","All Terrain A","All Terrain B","Highway Touring","Highway Sport","Carbon Performance","Endurance Max","Eco Rolling","Low Drag Sport","Drift Street","Drift Pro","Precision Corner","Heavy Brake","Launch Traction","Nitro Stability","Wet Track Elite","Mountain Grip","Champion Compound","Legend Compound"]
const TIRE_SURFACES := ["asphalt","asphalt","urban","asphalt","circuit","circuit","circuit","circuit","circuit","circuit","circuit","circuit","wet","wet","wet","wet","gravel","gravel","dirt","dirt","mixed","dirt","mixed","mixed","snow","ice","snow","ice","sand","sand","mixed","mixed","asphalt","asphalt","circuit","circuit","asphalt","asphalt","asphalt","circuit","mixed","asphalt","asphalt","mixed","wet","gravel","circuit","circuit"]
const TIRE_COMPOUNDS := ["touring","street","sport","semi_slick","slick","rain","rally","winter"]

const PAINTS := {
 "paint_red":{"name":"Turbo Red","level":1,"cost":0,"currency":"coins","type":"basic","color":"#FF3B30"},
 "paint_blue":{"name":"Electric Blue","level":1,"cost":250,"currency":"coins","type":"basic","color":"#23C4FF"},
 "paint_green":{"name":"Rush Green","level":5,"cost":500,"currency":"coins","type":"basic","color":"#3BD47A"},
 "paint_violet":{"name":"Violet Pulse","level":25,"cost":2000,"currency":"coins","type":"metallic","color":"#B77BFF"},
 "paint_matte":{"name":"Matte Shadow","level":40,"cost":3500,"currency":"coins","type":"matte","color":"#2E3442"},
 "paint_chrome":{"name":"Chrome Finish","level":70,"cost":50,"currency":"diamonds","type":"chrome","color":"#DDE3F0"},
 "paint_animated":{"name":"Animated Gradient","level":120,"cost":120,"currency":"diamonds","type":"animated","color":"#6BE1FF"},
 "paint_legendary":{"name":"Legendary Rush","level":150,"cost":300,"currency":"diamonds","type":"legendary","color":"#FFC93C"}
}

const ENVIRONMENTS := [
 ["sunrise_city","Sunrise City"],["coastal_highway","Coastal Highway"],["desert_canyon","Desert Canyon"],["mountain_pass","Mountain Pass"],["industrial_night","Industrial Night"],["snowline","Snowline"],["neon_metro","Neon Metro"],["volcanic_rim","Volcanic Rim"]
]
const CONDITIONS := ["Clear","Sunset","Night","Rain","Fog","Snow","Sandstorm","Ash Haze"]
const MODIFIERS := ["Traffic Rush","Slippery Zones","Boost Famine","Narrow Works","Night Run","Mirror Layout"]

func _init() -> void:
    _extend_cars()
    _extend_wheels()
    _extend_tires()

func _extend_cars() -> void:
    # 94 unlockable entries plus six starter/early vehicles = 100 choices.
    # Retain existing IDs to protect saves; body_style selects a lightweight silhouette.
    var ids:Array = ["volt_striker","apex_runner","nitro_falcon","road_phantom","blaze_gt","iron_comet","storm_racer","neon_sprint","desert_x","coastal_gt","midnight_rs","thunder_bolt","silver_arrow","crimson_apex","blue_orbit","green_fury","violet_xr","solar_gt","arctic_rs","carbon_v","shadow_racer","rally_nova","drift_king","pulse_gt","meteor_rs","night_falcon","ocean_fury","firestorm_gt","glacier_x","vertex_pro","quantum_gt","aurora_racer","titan_rs","velocity_xr","phantom_x","zenith_gt","inferno_rs","cyclone_pro","eclipse_gt","prism_racer","hyperion_rs","galaxy_gt","nova_striker","legend_rs","apex_ultra","zenith_x","titan_ultra","rush_xr","finale_xr","titan_racer","quantum_rush","world_gt","arc_lightning","vortex_gt","phantom_surge","monsoon_rs","solar_wind","eclipse_pro","granite_rally","apex_sentinel","nova_pulse","glacier_torque","ember_gt","midnight_vector","drift_spectre","titan_velocity","ion_storm","cobalt_rush","crimson_tide","zenith_blade","orbital_gt","tempest_rs","wildfire_x","aurora_prime","lunar_velocity","copperhead_gt","shadow_matrix","blue_thunder","jade_phantom","quartz_racer","silver_comet","vector_one","overdrive_x","rally_tempest","circuit_nova","nebula_king","horizon_rs","meteor_blitz","thunder_crest","apex_horizon","velocity_prime","hyper_drive","ion_runner","vortex_legend"]
    var car_names:Array = ["Volt Striker","Apex Runner","Nitro Falcon","Road Phantom","Blaze GT","Iron Comet","Storm Racer","Neon Sprint","Desert X","Coastal GT","Midnight RS","Thunder Bolt","Silver Arrow","Crimson Apex","Blue Orbit","Green Fury","Violet XR","Solar GT","Arctic RS","Carbon V","Shadow Racer","Rally Nova","Drift King","Pulse GT","Meteor RS","Night Falcon","Ocean Fury","Firestorm GT","Glacier X","Vertex Pro","Quantum GT","Aurora Racer","Titan RS","Velocity XR","Phantom X","Zenith GT","Inferno RS","Cyclone Pro","Eclipse GT","Prism Racer","Hyperion RS","Galaxy GT","Nova Striker","Legend RS","Apex Ultra","Zenith X","Titan Ultra","Rush XR","Finale XR","Titan Racer","Quantum Rush","World GT","Arc Lightning","Vortex GT","Phantom Surge","Monsoon RS","Solar Wind","Eclipse Pro","Granite Rally","Apex Sentinel","Nova Pulse","Glacier Torque","Ember GT","Midnight Vector","Drift Spectre","Titan Velocity","Ion Storm","Cobalt Rush","Crimson Tide","Zenith Blade","Orbital GT","Tempest RS","Wildfire X","Aurora Prime","Lunar Velocity","Copperhead GT","Shadow Matrix","Blue Thunder","Jade Phantom","Quartz Racer","Silver Comet","Vector One","Overdrive X","Rally Tempest","Circuit Nova","Nebula King","Horizon RS","Meteor Blitz","Thunder Crest","Apex Horizon","Velocity Prime","Hyper Drive","Ion Runner","Vortex Legend"]
    for i in range(ids.size()):
        var base := i
        var level := 8 + base * 4
        var tier := mini(18, floori(float(base) / 5.0))
        var top := minf(222.0, 149.0 + float(base) * 0.78)
        var accel := 8.4 + float(base) * 0.035
        var grip := 1.01 + float(base % 7) * 0.01
        var brake := 12.2 + float(base % 6) * 0.18
        var boost := 27.0 + float(base) * 0.22
        var duration := 2.05 + float(base % 6) * 0.08
        var stability := 0.98 + float(base % 7) * 0.012
        var coins := 3000 + base * 2200
        var diamonds := 12 + base
        var ability_type:String = ["launch_boost","boost_efficiency","damage_reduction","coin_multiplier","handling","boost_power","stability","speed"][base % 8]
        var ability_value:float = float([0.05,0.07,0.06,0.05,0.04,0.06,0.05,0.025][base % 8])
        var ability_name:String = ["Launch Burst","Nitro Saver","Impact Guard","Coin Rush","Apex Grip","Turbo Core","Stability Pro","Velocity Core"][base % 8]
        CARS[str(ids[i])] = {
            "name": str(car_names[i]),
            "level": level,
            "cost": coins,
            "cost_coins": coins,
            "cost_diamonds": diamonds,
            "top_speed": top,
            "accel": accel,
            "grip": grip,
            "brake": brake,
            "boost_power": boost,
            "boost_duration": duration,
            "stability": stability,
            "ability": ability_name,
            "ability_type": ability_type,
            "ability_value": ability_value + float(tier % 3) * 0.01,
            "body_style": base % 8
        }

func _extend_wheels() -> void:
    var ids := ["velocity_mesh","apex_split","rally_grip","circuit_blade","drift_halo","road_forge","storm_alloy","pulse_rim","quantum_ring","titan_mesh","inferno_rim","glacier_edge","aurora_wheel","phantom_disk","vortex_wheel","solar_ring","lunar_alloy","cyber_mesh","blaze_rim","ocean_edge","hyper_ring","carbon_halo","meteor_mesh","nova_forge","royal_spin","crimson_edge","volt_ring","arctic_mesh","shadow_alloy","prism_rim","fusion_wheel","legend_mesh","turbo_crown","racing_orbit","apex_halo","night_ring","chrome_pulse","titan_crown","velocity_edge","storm_ring","galaxy_mesh","inferno_crown","quantum_edge","aurora_ring","phantom_crown","solar_mesh","eclipse_rim","zenith_wheel","nova_crown","legend_edge","ultra_carbon"]
    for i in range(ids.size()):
        var n := i + 10
        var level := 4 + i * 3
        var coins := 650 + i * 520
        var diamonds := 6 + floori(float(i) * 1.1)
        var at:String = ["launch_boost","boost_efficiency","damage_reduction","coin_multiplier","handling","boost_power","stability","speed"][i % 8]
        var av:float = float([0.025,0.035,0.025,0.025,0.025,0.03,0.025,0.015][i % 8]) + float((i / 8) % 3) * 0.005
        var an:String = ["Launch Grip","Nitro Saver","Impact Guard","Coin Rush","Apex Grip","Turbo Core","Stability Pro","Velocity Core"][i % 8]
        WHEELS[ids[i]] = {
            "name": str(["Street Steel","Alloy Sport","Turbo Fan","Carbon Track","Chrome Racer","Neon Glow","Golden Crown","Nova Edge","Velocity Mesh","Apex Split","Rally Grip","Circuit Blade","Drift Halo","Road Forge","Storm Alloy","Pulse Rim","Quantum Ring","Titan Mesh","Inferno Rim","Glacier Edge","Aurora Wheel","Phantom Disk","Vortex Wheel","Solar Ring","Lunar Alloy","Cyber Mesh","Blaze Rim","Ocean Edge","Hyper Ring","Carbon Halo","Meteor Mesh","Nova Forge","Royal Spin","Crimson Edge","Volt Ring","Arctic Mesh","Shadow Alloy","Prism Rim","Fusion Wheel","Legend Mesh","Turbo Crown","Racing Orbit","Apex Halo","Night Ring","Chrome Pulse","Titan Crown","Velocity Edge","Storm Ring","Galaxy Mesh","Inferno Crown","Quantum Edge","Aurora Ring","Phantom Crown","Solar Mesh","Eclipse Rim","Zenith Wheel","Nova Crown","Legend Edge","Ultra Carbon","Rush Supreme"][n-1]),
            "level": level,
            "cost": coins,
            "cost_coins": coins,
            "cost_diamonds": diamonds,
            "premium": n >= 36,
            "ability": an,
            "ability_type": at,
            "ability_value": av
        }

func _extend_tires() -> void:
    for i in range(TIRE_NAMES.size()):
        var n := i + 1
        var id := "tire_%02d" % n
        var surface := str(TIRE_SURFACES[i])
        var compound := str(TIRE_COMPOUNDS[i % TIRE_COMPOUNDS.size()])
        var tier := floori(float(i) / 6.0)
        var grip := 0.94 + float((i * 3) % 7) * 0.018
        var accel_mult := 0.97 + float((i * 5) % 6) * 0.012
        var brake_mult := 0.95 + float((i * 2) % 8) * 0.016
        var durability := 0.82 + float((i * 3) % 7) * 0.04
        if surface == "wet" and compound == "rain":
            grip += 0.025
            brake_mult += 0.025
        elif surface in ["snow","ice"] and compound == "winter":
            grip += 0.025
            brake_mult += 0.015
        elif surface in ["gravel","dirt","sand"] and compound == "rally":
            grip += 0.02
            accel_mult += 0.01
        var coins := 0 if i == 0 else 250 + i * 350
        var diamonds := 0 if n < 25 else mini(12, 1 + floori(float(n - 25) / 4.0))
        TIRES[id] = {
            "id": id,
            "name": str(TIRE_NAMES[i]),
            "level": 1 if i == 0 else 1 + i * 2,
            "cost_coins": coins,
            "cost_diamonds": diamonds,
            "compound": compound,
            "surface": surface,
            "grip_multiplier": clampf(grip, 0.92, 1.12),
            "acceleration_multiplier": clampf(accel_mult, 0.95, 1.05),
            "braking_multiplier": clampf(brake_mult, 0.93, 1.10),
            "durability": clampf(durability, 0.8, 1.1),
            "tier": tier
        }

func car(id:String)->Dictionary:
    return CARS.get(id,CARS["rookie_gt"])

func wheel(id:String)->Dictionary:
    return WHEELS.get(id,WHEELS["wheel_stock"])

func tire(id:String) -> Dictionary:
    return TIRES.get(id, {})

func paint(id:String)->Dictionary:
    return PAINTS.get(id,PAINTS["paint_red"])
