extends RefCounted

# Returns true only when no still-present board above the screw covers its X/Z point.
static func is_screw_accessible(screw_position: Vector3, own_board_id: int, board_states: Array) -> bool:
	for board in board_states:
		if bool(board.get("removed", false)):
			continue
		if int(board.get("id", -1)) == own_board_id:
			continue
		# A screw head protrudes above its own beam; only a meaningfully higher beam can cover it.
		if float(board.get("y", -100.0)) + 0.17 <= screw_position.y + 0.06:
			continue
		var center: Vector2 = board.get("center", Vector2.ZERO)
		var half_width: float = float(board.get("width", 0.0)) * 0.5 - 0.04
		var half_depth: float = float(board.get("depth", 0.0)) * 0.5 - 0.04
		var angle: float = float(board.get("rotation_y", 0.0))
		var dx: float = screw_position.x - center.x
		var dz: float = screw_position.z - center.y
		var local_x: float = cos(angle) * dx - sin(angle) * dz
		var local_z: float = sin(angle) * dx + cos(angle) * dz
		if absf(local_x) < half_width and absf(local_z) < half_depth:
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
