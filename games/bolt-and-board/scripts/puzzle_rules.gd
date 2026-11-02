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
