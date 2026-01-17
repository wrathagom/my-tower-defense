extends Node

var wood: int = 0
var food: int = 0
var stone: int = 0
var max_wood: int = 0
var max_food: int = 0
var max_stone: int = 0
var max_units: int = 0
var current_units: int = 0

var unit_food_cost: int = 0
var stone_thrower_food_cost: int = 0
var stone_thrower_stone_cost: int = 0
var archer_food_cost: int = 0
var archer_wood_cost: int = 0
var tower_cost: int = 0
var woodcutter_cost: int = 0
var stonecutter_cost: int = 0
var archery_range_cost: int = 0
var house_cost: int = 0
var farm_cost: int = 0
var wood_storage_cost: int = 0
var food_storage_cost: int = 0
var stone_storage_cost: int = 0
var base_upgrade_cost: int = 0
var base_upgrade_stone_cost: int = 0

var wood_label: Label
var food_label: Label
var stone_label: Label
var unit_label: Label
var spawn_buttons: Dictionary = {}
var unit_defs: Dictionary = {}
var build_buttons: Dictionary = {}
var build_defs: Dictionary = {}
var has_archery_range: bool = false
var has_archery_range_upgrade: bool = false
var upgrade_button: Button
var base_level: int = 1
var base_upgrade_in_progress: bool = false

func configure_resources(
	starting_wood: int,
	starting_food: int,
	starting_stone: int,
	base_cap: int,
	unit_food_cost_value: int
) -> void:
	max_wood = base_cap
	max_food = base_cap
	max_stone = base_cap
	wood = min(starting_wood, max_wood)
	food = min(starting_food, max_food)
	stone = min(starting_stone, max_stone)
	unit_food_cost = unit_food_cost_value
	_update_all()

func set_costs(values: Dictionary) -> void:
	tower_cost = values.get("tower_cost", 0)
	woodcutter_cost = values.get("woodcutter_cost", 0)
	stonecutter_cost = values.get("stonecutter_cost", 0)
	archery_range_cost = values.get("archery_range_cost", 0)
	house_cost = values.get("house_cost", 0)
	farm_cost = values.get("farm_cost", 0)
	wood_storage_cost = values.get("wood_storage_cost", 0)
	food_storage_cost = values.get("food_storage_cost", 0)
	stone_storage_cost = values.get("stone_storage_cost", 0)
	base_upgrade_cost = values.get("base_upgrade_cost", 0)
	base_upgrade_stone_cost = values.get("base_upgrade_stone_cost", 0)
	stone_thrower_food_cost = values.get("stone_thrower_food_cost", 0)
	stone_thrower_stone_cost = values.get("stone_thrower_stone_cost", 0)
	archer_food_cost = values.get("archer_food_cost", 0)
	archer_wood_cost = values.get("archer_wood_cost", 0)

func set_labels(
	wood_label_value: Label,
	food_label_value: Label,
	stone_label_value: Label,
	unit_label_value: Label
) -> void:
	wood_label = wood_label_value
	food_label = food_label_value
	stone_label = stone_label_value
	unit_label = unit_label_value
	_update_labels()

func set_build_buttons(buttons: Dictionary, upgrade_button_value: Button) -> void:
	build_buttons = buttons
	upgrade_button = upgrade_button_value
	_update_buttons(1)

func set_build_defs(defs: Dictionary) -> void:
	build_defs = defs
	_update_buttons(base_level)

func set_spawn_buttons(buttons: Dictionary) -> void:
	spawn_buttons = buttons
	_update_buttons(base_level)

func set_unit_defs(defs: Dictionary) -> void:
	unit_defs = defs
	_update_buttons(base_level)

func add_wood(amount: int) -> void:
	wood = clampi(wood + amount, 0, max_wood)
	_update_all()

func add_food(amount: int) -> void:
	food = clampi(food + amount, 0, max_food)
	_update_all()

func add_stone(amount: int) -> void:
	stone = clampi(stone + amount, 0, max_stone)
	_update_all()

func spend_wood(amount: int) -> bool:
	if wood < amount:
		return false
	wood -= amount
	_update_all()
	return true

func spend_stone(amount: int) -> bool:
	if stone < amount:
		return false
	stone -= amount
	_update_all()
	return true

func can_afford_wood(amount: int) -> bool:
	return wood >= amount

func can_afford_cost(def: Dictionary) -> bool:
	var costs: Dictionary = def.get("costs", {})
	var food_cost: int = costs.get("food", 0)
	var wood_cost: int = costs.get("wood", 0)
	var stone_cost: int = costs.get("stone", 0)
	return food >= food_cost and wood >= wood_cost and stone >= stone_cost

func spend_cost(def: Dictionary) -> bool:
	if not can_afford_cost(def):
		return false
	var costs: Dictionary = def.get("costs", {})
	var food_cost: int = costs.get("food", 0)
	var wood_cost: int = costs.get("wood", 0)
	var stone_cost: int = costs.get("stone", 0)
	food = clampi(food - food_cost, 0, max_food)
	wood = clampi(wood - wood_cost, 0, max_wood)
	stone = clampi(stone - stone_cost, 0, max_stone)
	_update_all()
	return true

func can_spawn_unit() -> bool:
	return food >= unit_food_cost and current_units < max_units

func can_spawn_stone_thrower() -> bool:
	return food >= stone_thrower_food_cost and stone >= stone_thrower_stone_cost and current_units < max_units

func can_spawn_archer() -> bool:
	return food >= archer_food_cost and wood >= archer_wood_cost and current_units < max_units

func can_spawn_unit_def(def: Dictionary) -> bool:
	var food_cost: int = def.get("food_cost", 0)
	var wood_cost: int = def.get("wood_cost", 0)
	var stone_cost: int = def.get("stone_cost", 0)
	return food >= food_cost and wood >= wood_cost and stone >= stone_cost and current_units < max_units

func on_unit_spawned() -> void:
	food = clampi(food - unit_food_cost, 0, max_food)
	current_units += 1
	_update_all()

func on_stone_thrower_spawned() -> void:
	food = clampi(food - stone_thrower_food_cost, 0, max_food)
	stone = clampi(stone - stone_thrower_stone_cost, 0, max_stone)
	current_units += 1
	_update_all()

func on_archer_spawned() -> void:
	food = clampi(food - archer_food_cost, 0, max_food)
	wood = clampi(wood - archer_wood_cost, 0, max_wood)
	current_units += 1
	_update_all()

func on_unit_spawned_def(def: Dictionary) -> void:
	var food_cost: int = def.get("food_cost", 0)
	var wood_cost: int = def.get("wood_cost", 0)
	var stone_cost: int = def.get("stone_cost", 0)
	food = clampi(food - food_cost, 0, max_food)
	wood = clampi(wood - wood_cost, 0, max_wood)
	stone = clampi(stone - stone_cost, 0, max_stone)
	current_units += 1
	_update_all()

func on_unit_removed() -> void:
	current_units = max(0, current_units - 1)
	_update_all()

func reset_units() -> void:
	current_units = 0
	_update_all()

func add_unit_capacity(amount: int) -> void:
	max_units += amount
	_update_all()

func add_wood_cap(amount: int) -> void:
	max_wood += amount
	wood = clampi(wood, 0, max_wood)
	_update_all()

func add_food_cap(amount: int) -> void:
	max_food += amount
	food = clampi(food, 0, max_food)
	_update_all()

func add_stone_cap(amount: int) -> void:
	max_stone += amount
	stone = clampi(stone, 0, max_stone)
	_update_all()

func update_buttons_for_base_level(base_level_value: int, has_archery_range_value: bool, has_archery_range_upgrade_value: bool) -> void:
	base_level = base_level_value
	has_archery_range = has_archery_range_value
	has_archery_range_upgrade = has_archery_range_upgrade_value
	_update_buttons(base_level)

func set_archery_range_upgrade(value: bool) -> void:
	has_archery_range_upgrade = value
	_update_buttons(base_level)

func set_base_upgrade_in_progress(value: bool) -> void:
	base_upgrade_in_progress = value
	_update_buttons(base_level)

func _update_all() -> void:
	_update_labels()
	_update_buttons(base_level)

func _update_labels() -> void:
	if wood_label != null:
		wood_label.text = "Wood: %d / %d" % [wood, max_wood]
	if food_label != null:
		food_label.text = "Food: %d / %d" % [food, max_food]
	if stone_label != null:
		stone_label.text = "Stone: %d / %d" % [stone, max_stone]
	if unit_label != null:
		unit_label.text = "Units: %d / %d" % [current_units, max_units]

func _update_buttons(base_level_value: int) -> void:
	_update_spawn_buttons(base_level_value)
	_update_build_buttons(base_level_value)
	if upgrade_button != null:
		upgrade_button.disabled = base_upgrade_in_progress or wood < base_upgrade_cost or (base_level_value >= 2 and stone < base_upgrade_stone_cost)

func _update_spawn_buttons(base_level_value: int) -> void:
	for unit_id in spawn_buttons.keys():
		var button := spawn_buttons[unit_id] as Button
		if button == null:
			continue
		var def: Dictionary = unit_defs.get(unit_id, {})
		if def.is_empty():
			button.disabled = true
			button.visible = false
			continue
		var min_level: int = def.get("min_base_level", 1)
		var requires_range: bool = def.get("requires_archery_range", false)
		var requires_upgrade: bool = def.get("requires_archery_range_upgrade", false)
		var unlocked := base_level_value >= min_level
		if requires_range:
			unlocked = unlocked and has_archery_range
		if requires_upgrade:
			unlocked = unlocked and has_archery_range_upgrade
		var can_spawn := unlocked and can_spawn_unit_def(def)
		button.disabled = not can_spawn
		button.visible = unlocked

func _update_build_buttons(base_level_value: int) -> void:
	for building_id in build_buttons.keys():
		var button := build_buttons[building_id] as Button
		if button == null:
			continue
		var def: Dictionary = build_defs.get(building_id, {})
		if def.is_empty():
			button.disabled = true
			button.visible = false
			continue
		var min_level: int = def.get("min_base_level", 1)
		var unlocked := base_level_value >= min_level
		var can_build := unlocked and can_afford_cost(def)
		button.disabled = not can_build
		button.visible = unlocked
