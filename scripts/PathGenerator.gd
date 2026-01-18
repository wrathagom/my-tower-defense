class_name PathGenerator
extends Node

var _main: Node

var grid_width: int
var grid_height: int
var path_margin: int
var path_straightness: float
var path_max_vertical_step: int
var path_length_multiplier: float
var random_seed: int
var restrict_path_to_base_band: bool
var path_generation_attempts: int

func setup(main_node: Node) -> void:
	_main = main_node
	_sync_config()

func _sync_config() -> void:
	if _main == null:
		return
	grid_width = _main.grid_width
	grid_height = _main.grid_height
	path_margin = _main.path_margin
	path_straightness = _main.path_straightness
	path_max_vertical_step = _main.path_max_vertical_step
	path_length_multiplier = _main.path_length_multiplier
	random_seed = _main.random_seed
	restrict_path_to_base_band = _main.restrict_path_to_base_band
	path_generation_attempts = _main.path_generation_attempts

func generate_random_path() -> Dictionary:
	_sync_config()
	var path_cells: Array[Vector2i] = []
	var base_start_cell := Vector2i(-1, -1)
	var base_end_cell := Vector2i(-1, -1)

	var start_x: int = path_margin
	var end_x: int = grid_width - 1 - path_margin
	if end_x <= start_x or grid_height <= 0:
		return {"path": path_cells, "start": base_start_cell, "end": base_end_cell}

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	if random_seed == 0:
		rng.randomize()
	else:
		rng.seed = random_seed

	var attempt: int = 0
	while attempt < path_generation_attempts:
		var bases := _pick_base_cells(rng, start_x, end_x)
		base_start_cell = bases.start
		base_end_cell = bases.end
		if base_start_cell == Vector2i(-1, -1) or base_end_cell == Vector2i(-1, -1):
			attempt += 1
			continue

		var start: Vector2i = base_start_cell
		var current: Vector2i = start
		var last_dir: Vector2i = Vector2i(1, 0)
		var vertical_streak: int = 0

		var path: Array[Vector2i] = []
		var visited: Dictionary[Vector2i, bool] = {}
		path.append(current)
		visited[current] = true

		var max_steps: int = grid_width * grid_height * 10
		var steps: int = 0

		while steps < max_steps:
			if current == base_end_cell:
				path_cells = path
				return {"path": path_cells, "start": base_start_cell, "end": base_end_cell}

			var candidates: Array[Vector2i] = _get_walk_candidates(current, start_x, end_x, visited, vertical_streak)
			if candidates.is_empty():
				if path.size() <= 1:
					break
				visited.erase(current)
				path.pop_back()
				current = path[path.size() - 1]
				vertical_streak = 0
				steps += 1
				continue

			var next: Vector2i = _choose_weighted_candidate(candidates, current, last_dir, rng)
			var dir: Vector2i = next - current
			if dir.y != 0:
				vertical_streak += 1
			else:
				vertical_streak = 0
			last_dir = dir
			current = next
			path.append(current)
			visited[current] = true
			steps += 1

		attempt += 1

	path_cells = _fallback_straight_path(base_start_cell, base_end_cell)
	return {"path": path_cells, "start": base_start_cell, "end": base_end_cell}

func _get_walk_candidates(
	current: Vector2i,
	start_x: int,
	end_x: int,
	visited: Dictionary[Vector2i, bool],
	vertical_streak: int
) -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0)]
	var band := _base_band_bounds()
	for dir in dirs:
		if dir == Vector2i(-1, 0) and path_length_multiplier <= 1.0:
			continue
		if dir.y != 0 and vertical_streak >= path_max_vertical_step:
			continue
		var next: Vector2i = current + dir
		if next.x < start_x or next.x > end_x:
			continue
		if restrict_path_to_base_band:
			if next.y < band.x or next.y > band.y:
				continue
		if next.y < 0 or next.y >= grid_height:
			continue
		if visited.has(next):
			continue
		candidates.append(next)
	return candidates

func _choose_weighted_candidate(
	candidates: Array[Vector2i],
	current: Vector2i,
	last_dir: Vector2i,
	rng: RandomNumberGenerator
) -> Vector2i:
	var weights: Array[float] = []
	var total: float = 0.0
	for candidate in candidates:
		var dir: Vector2i = candidate - current
		var weight: float = _direction_weight(dir, last_dir)
		weights.append(weight)
		total += weight
	var pick: float = rng.randf() * total
	var acc: float = 0.0
	for i in range(candidates.size()):
		acc += weights[i]
		if pick <= acc:
			return candidates[i]
	return candidates[0]

func _direction_weight(dir: Vector2i, last_dir: Vector2i) -> float:
	var right_weight: float = lerp(2.0, 5.0, path_straightness)
	var vert_weight: float = lerp(2.5, 0.6, path_straightness) * maxf(1.0, path_length_multiplier)
	var left_weight: float = 0.0
	if path_length_multiplier > 1.0:
		left_weight = lerp(0.8, 0.1, path_straightness)

	var base: float = 0.01
	if dir == Vector2i(1, 0):
		base = right_weight
	elif dir == Vector2i(-1, 0):
		base = left_weight
	else:
		base = vert_weight

	var straight_bonus: float = 1.0
	if dir == last_dir:
		straight_bonus += path_straightness
	return maxf(0.01, base * straight_bonus)

func _fallback_straight_path(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var current := start
	path.append(current)
	while current.y != goal.y:
		current = Vector2i(current.x, current.y + signi(goal.y - current.y))
		path.append(current)
	while current.x != goal.x:
		current = Vector2i(current.x + signi(goal.x - current.x), current.y)
		path.append(current)
	return path

func _pick_base_cells(rng: RandomNumberGenerator, start_x: int, end_x: int) -> Dictionary:
	var band := _base_band_bounds()
	var start_y := rng.randi_range(band.x, band.y)
	var end_y := rng.randi_range(band.x, band.y)
	return {
		"start": Vector2i(start_x, start_y),
		"end": Vector2i(end_x, end_y)
	}

func _base_band_bounds() -> Vector2i:
	var min_y: int = int(floor(grid_height / 3.0))
	var max_y: int = int(floor(2.0 * grid_height / 3.0)) - 1
	if max_y < min_y:
		min_y = 0
		max_y = grid_height - 1
	return Vector2i(min_y, max_y)
