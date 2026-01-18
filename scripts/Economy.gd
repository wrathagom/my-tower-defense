extends Node

const GameConfig = preload("res://scripts/GameConfig.gd")

var wood: int = 0
var food: int = 0
var stone: int = 0
var iron: int = 0
var max_wood: int = 0
var max_food: int = 0
var max_stone: int = 0
var max_iron: int = 0
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
var iron_label: Label
var unit_label: Label
var spawn_buttons: Dictionary = {}
var unit_defs: Dictionary = {}
var build_buttons: Dictionary = {}
var build_defs: Dictionary = {}
var build_category_filter := ""
var archery_level: int = 0
var barracks_level: int = 0
var upgrade_button: Button
var base_level: int = 1
var base_upgrade_in_progress: bool = false

func configure_resources(
	starting_wood: int,
	starting_food: int,
	starting_stone: int,
	starting_iron: int,
	base_cap: int,
	unit_food_cost_value: int
) -> void:
	max_wood = base_cap
	max_food = base_cap
	max_stone = base_cap
	max_iron = base_cap
	wood = min(starting_wood, max_wood)
	food = min(starting_food, max_food)
	stone = min(starting_stone, max_stone)
	iron = min(starting_iron, max_iron)
	unit_food_cost = unit_food_cost_value
	_update_all()

func set_costs(config: GameConfig) -> void:
	tower_cost = config.tower_cost
	woodcutter_cost = config.woodcutter_cost
	stonecutter_cost = config.stonecutter_cost
	archery_range_cost = config.archery_range_cost
	house_cost = config.house_cost
	farm_cost = config.farm_cost
	wood_storage_cost = config.wood_storage_cost
	food_storage_cost = config.food_storage_cost
	stone_storage_cost = config.stone_storage_cost
	base_upgrade_cost = config.base_upgrade_cost
	base_upgrade_stone_cost = config.base_upgrade_stone_cost
	stone_thrower_food_cost = config.stone_thrower_food_cost
	stone_thrower_stone_cost = config.stone_thrower_stone_cost
	archer_food_cost = config.archer_food_cost
	archer_wood_cost = config.archer_wood_cost

func set_labels(
	wood_label_value: Label,
	food_label_value: Label,
	stone_label_value: Label,
	iron_label_value: Label,
	unit_label_value: Label
) -> void:
	wood_label = wood_label_value
	food_label = food_label_value
	stone_label = stone_label_value
	iron_label = iron_label_value
	unit_label = unit_label_value
	_update_labels()

func set_build_buttons(buttons: Dictionary, upgrade_button_value: Button) -> void:
	build_buttons = buttons
	upgrade_button = upgrade_button_value
	_update_buttons(1)

func set_build_defs(defs: Dictionary) -> void:
	build_defs = defs
	_update_buttons(base_level)

func set_build_category_filter(category: String) -> void:
	build_category_filter = category
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

func add_iron(amount: int) -> void:
	iron = clampi(iron + amount, 0, max_iron)
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

func spend_iron(amount: int) -> bool:
	if iron < amount:
		return false
	iron -= amount
	_update_all()
	return true

func can_afford_wood(amount: int) -> bool:
	return wood >= amount

func can_afford_cost(def: Dictionary) -> bool:
	var costs: Dictionary = def.get("costs", {})
	var food_cost: int = costs.get("food", 0)
	var wood_cost: int = costs.get("wood", 0)
	var stone_cost: int = costs.get("stone", 0)
	var iron_cost: int = costs.get("iron", 0)
	return food >= food_cost and wood >= wood_cost and stone >= stone_cost and iron >= iron_cost

func spend_cost(def: Dictionary) -> bool:
	if not can_afford_cost(def):
		return false
	var costs: Dictionary = def.get("costs", {})
	var food_cost: int = costs.get("food", 0)
	var wood_cost: int = costs.get("wood", 0)
	var stone_cost: int = costs.get("stone", 0)
	var iron_cost: int = costs.get("iron", 0)
	food = clampi(food - food_cost, 0, max_food)
	wood = clampi(wood - wood_cost, 0, max_wood)
	stone = clampi(stone - stone_cost, 0, max_stone)
	iron = clampi(iron - iron_cost, 0, max_iron)
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
	var iron_cost: int = def.get("iron_cost", 0)
	return food >= food_cost and wood >= wood_cost and stone >= stone_cost and iron >= iron_cost and current_units < max_units

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
	var iron_cost: int = def.get("iron_cost", 0)
	food = clampi(food - food_cost, 0, max_food)
	wood = clampi(wood - wood_cost, 0, max_wood)
	stone = clampi(stone - stone_cost, 0, max_stone)
	iron = clampi(iron - iron_cost, 0, max_iron)
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

func add_iron_cap(amount: int) -> void:
	max_iron += amount
	iron = clampi(iron, 0, max_iron)
	_update_all()

func update_buttons_for_base_level(base_level_value: int, archery_level_value: int, barracks_level_value: int) -> void:
	base_level = base_level_value
	archery_level = archery_level_value
	barracks_level = barracks_level_value
	_update_buttons(base_level)

func set_archery_level(value: int) -> void:
	archery_level = value
	_update_buttons(base_level)

func set_barracks_level(value: int) -> void:
	barracks_level = value
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
	if iron_label != null:
		iron_label.text = "Iron: %d / %d" % [iron, max_iron]
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
		var unlocked := _requirements_met(def, base_level_value, archery_level)
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
		var unlocked := _requirements_met(def, base_level_value, archery_level)
		var matches := build_category_filter == "" or str(def.get("category", "")) == build_category_filter
		var can_build := unlocked and can_afford_cost(def)
		button.disabled = not can_build
		button.visible = unlocked and matches

func _requirements_met(def: Dictionary, base_level_value: int, archery_level_value: int) -> bool:
	var requirements: Array = def.get("requirements", [])
	if requirements.is_empty():
		var min_level: int = def.get("min_base_level", 1)
		if base_level_value < min_level:
			return false
		var requires_range: bool = def.get("requires_archery_range", false)
		var requires_upgrade: bool = def.get("requires_archery_range_upgrade", false)
		if requires_range and archery_level_value < 1:
			return false
		if requires_upgrade and archery_level_value < 2:
			return false
		return true
	for req in requirements:
		if req is Dictionary:
			var req_type: String = str(req.get("type", ""))
			if req_type == "base_level":
				if base_level_value < int(req.get("value", 1)):
					return false
			elif req_type == "archery_level":
				if archery_level_value < int(req.get("value", 0)):
					return false
			elif req_type == "barracks_level":
				if barracks_level < int(req.get("value", 0)):
					return false
	return true
