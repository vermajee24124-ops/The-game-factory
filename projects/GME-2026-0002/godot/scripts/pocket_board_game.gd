extends "res://scripts/main.gd"

## Production wrapper around the reusable board controller.
## The base controller stays available for future factory-generated variants.

func _spawn_rack() -> void:
    # Standard 19-piece layout: 1 queen + 6 inner + 12 outer pieces.
    _spawn_piece(Vector3.ZERO + Vector3(0, 0.18, 0), "queen")

    for i in range(6):
        var angle := float(i) * TAU / 6.0
        var pos := Vector3(cos(angle) * 0.70, 0.18, sin(angle) * 0.70)
        _spawn_piece(pos, "black" if i % 2 == 0 else "white")

    for i in range(12):
        var angle := float(i) * TAU / 12.0 + PI / 12.0
        var pos := Vector3(cos(angle) * 1.36, 0.18, sin(angle) * 1.36)
        _spawn_piece(pos, "black" if i % 2 == 0 else "white")

func _build_ui() -> void:
    super._build_ui()
    if is_instance_valid(mode_label):
        mode_label.text = "OFFLINE • LOCAL PLAY"
