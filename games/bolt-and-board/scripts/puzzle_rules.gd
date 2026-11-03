extends RefCounted

# Returns true only when no still-present board above the screw covers its X/Z point.
static func is_screw_accessible(screw_position: Vector3, own_board_id: int, board_states: Array) -> bool:
	for board in board_states:
		if bool(board.get("removed", false)):
			continue
		if int(board.get("id", -1)) == own_board_id:
			continue
		if float(board.get("y", -100.0)) <= screw_position.y - 0.18:
			continue
		var center: Vector2 = board.get("center", Vector2.ZERO)
		var half_width: float = float(board.get("width", 0.0)) * 0.5 - 0.04
		var half_depth: float = float(board.get("depth", 0.0)) * 0.5 - 0.04
		if absf(screw_position.x - center.x) < half_width and absf(screw_position.z - center.y) < half_depth:
			return false
	return true


static func get_layer_count(level: int) -> int:
	return clampi(2 + int((maxi(level, 1) - 1) / 2), 2, 5)


static func is_board_cleared(board_screw_ids: Array, screw_states: Dictionary) -> bool:
	for screw_id in board_screw_ids:
		if screw_states.has(screw_id) and not bool(screw_states[screw_id].get("removed", false)):
			return false
	return true


static func is_level_unlocked(level: int, highest_unlocked: int) -> bool:
	return level >= 1 and level <= highest_unlocked and level <= 30


static func get_pattern_index(level: int, layer: int) -> int:
	return posmod(level + layer * 2, 6)

# Build deterministic color-toolbox batches. Each target box accepts up to three
# screws of one color; the final batch for a color may contain one or two.
static func build_toolbox_targets(color_counts: Array, first_color: int, color_total: int = 4) -> Array[Dictionary]:
	var targets: Array[Dictionary] = []
	if color_total <= 0:
		return targets
	for offset in range(color_total):
		var color_id: int = posmod(first_color + offset, color_total)
		var remaining: int = int(color_counts[color_id]) if color_id < color_counts.size() else 0
		while remaining > 0:
			var goal: int = mini(3, remaining)
			targets.append({"color": color_id, "goal": goal})
			remaining -= goal
	return targets

