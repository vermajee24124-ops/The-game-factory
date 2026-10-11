extends SceneTree

# Project-specific end-to-end playthrough for Turbo Rush (GME-2026-0003).
# Uses the real main scene and its UI handlers, then drives the game's own
# touch-control state during a real level-1 race. It exits nonzero unless the
# finish/results flow confirms a completed race.
const STARTUP_TIMEOUT_SEC := 25.0
const RACE_TIMEOUT_SEC := 195.0
const STEP_SEC := 0.10

var game: Node = null
var privacy_clicked := false
var onboarding_clicked := false
var play_clicked := false
var race_button_clicked := false


func _initialize() -> void:
    call_deferred("_run")


func _find_visible_button(node: Node, wanted_text: String) -> Button:
    if node is Button:
        var button := node as Button
        if button.is_visible_in_tree() and button.text.strip_edges().to_upper() == wanted_text.to_upper():
            return button
    for child in node.get_children():
        var found := _find_visible_button(child, wanted_text)
        if found != null:
            return found
    return null


func _fail(message: String) -> void:
    push_error("TURBO_RUSH_QA_FAIL: " + message)
    quit(1)


func _run() -> void:
    var packed := load("res://main.tscn") as PackedScene
    if packed == null:
        _fail("Could not load res://main.tscn.")
        return

    # Use an isolated runner save state. This is a CI test fixture, not a
    # release default; "CONTINUE WITHOUT ADS" is chosen through the actual UI.
    var save_system := root.get_node_or_null("SaveSystem")
    if save_system == null:
        _fail("SaveSystem autoload was not found.")
        return
    if save_system.data is Dictionary:
        var privacy: Dictionary = save_system.data.get("privacy", {})
        privacy["consent_status"] = "unknown"
        privacy["personalized_ads"] = false
        save_system.data["privacy"] = privacy
        var profile: Dictionary = save_system.data.get("profile", {})
        profile["onboarding_completed"] = false
        profile["highest_unlocked_level"] = 1
        save_system.data["profile"] = profile
        if save_system.has_method("save_now"):
            save_system.save_now()

    game = packed.instantiate()
    game.name = "TurboRushQAUnderTest"
    root.add_child(game)
    await process_frame

    print("TURBO_RUSH_QA: Main scene loaded; navigating privacy/onboarding using actual UI handlers.")
    var startup_elapsed := 0.0
    while startup_elapsed < STARTUP_TIMEOUT_SEC:
        await create_timer(STEP_SEC).timeout
        startup_elapsed += STEP_SEC

        if not privacy_clicked:
            var privacy_button := _find_visible_button(game, "CONTINUE WITHOUT ADS")
            if privacy_button != null:
                privacy_clicked = true
                privacy_button.pressed.emit()
                print("TURBO_RUSH_QA: Chose CONTINUE WITHOUT ADS through the privacy screen.")
                continue

        if not onboarding_clicked:
            var onboarding_button := _find_visible_button(game, "START ROOKIE RACE")
            if onboarding_button != null:
                onboarding_clicked = true
                onboarding_button.pressed.emit()
                print("TURBO_RUSH_QA: Started the rookie race through the onboarding button.")
                break

        # If onboarding is already complete or has been skipped in this build,
        # use the regular PLAY -> RACE UI path.
        if not play_clicked:
            var play_button := _find_visible_button(game, "PLAY")
            if play_button != null:
                play_clicked = true
                play_button.pressed.emit()
                print("TURBO_RUSH_QA: Opened the race flow through PLAY.")
                continue

        if not race_button_clicked:
            var race_button := _find_visible_button(game, "RACE")
            if race_button != null:
                race_button_clicked = true
                race_button.pressed.emit()
                print("TURBO_RUSH_QA: Confirmed RACE through the pre-race screen.")
                break

        if str(game.get("state")) in ["COUNTDOWN", "RACING"]:
            break

    # On a slow or changed UI flow, fail rather than silently force gameplay.
    if str(game.get("state")) not in ["COUNTDOWN", "RACING"]:
        _fail("Could not enter a real race through the visible UI within the startup timeout. current_screen=%s state=%s" % [str(game.get("current_screen")), str(game.get("state"))])
        return

    print("TURBO_RUSH_QA: Race started. Recording should capture countdown, steering, boost and finish/results.")
    var race_elapsed := 0.0
    var next_report := 10.0
    while race_elapsed < RACE_TIMEOUT_SEC:
        var steer_phase := fposmod(race_elapsed, 4.0)
        # Controlled left/right pulses approximate mobile touch holds. Release
        # the controls between pulses so the car can return toward a stable lane.
        game.set("left_held", steer_phase >= 0.25 and steer_phase < 0.55)
        game.set("right_held", steer_phase >= 2.15 and steer_phase < 2.45)

        var energy := float(game.get("boost_energy"))
        game.set("boosting", energy > 18.0 and fposmod(race_elapsed, 8.0) < 1.2)

        await create_timer(STEP_SEC).timeout
        race_elapsed += STEP_SEC

        var current_state := str(game.get("state"))
        var screen := str(game.get("current_screen"))
        if current_state == "WRECKED" or screen == "wreck":
            _fail("Player wrecked before finishing; review race controls/collisions. elapsed=%.1f damage=%s" % [race_elapsed, str(game.get("damage"))])
            return

        var last_result: Dictionary = game.get("last_result")
        if screen == "results" and bool(last_result.get("completed", false)):
            game.set("left_held", false)
            game.set("right_held", false)
            game.set("boosting", false)
            print("TURBO_RUSH_QA_PASS: Race completed. elapsed=%.1f position=%s stars=%s" % [
                race_elapsed,
                str(last_result.get("finish_position", "unknown")),
                str(last_result.get("stars_earned", "unknown"))
            ])
            quit(0)
            return

        if race_elapsed >= next_report:
            print("TURBO_RUSH_QA_PROGRESS: elapsed=%.0f state=%s progress=%s damage=%s screen=%s" % [
                race_elapsed,
                current_state,
                str(game.get("player_progress")),
                str(game.get("damage")),
                screen
            ])
            next_report += 10.0

    _fail("Race did not reach a completed results screen within %.0f seconds. state=%s screen=%s progress=%s" % [
        RACE_TIMEOUT_SEC,
        str(game.get("state")),
        str(game.get("current_screen")),
        str(game.get("player_progress"))
    ])
