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
var spawn_unit_button: Button
var spawn_stone_thrower_button: Button
var has_archery_range: bool = false
var tower_button: Button
var woodcutter_button: Button
var stonecutter_button: Button
var archery_range_button: Button
var house_button: Button
var farm_button: Button
var wood_storage_button: Button
var food_storage_button: Button
var stone_storage_button: Button
var upgrade_button: Button
var base_level: int = 1

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

func set_buttons(
	spawn_unit_button_value: Button,
	spawn_stone_thrower_button_value: Button,
	tower_button_value: Button,
	woodcutter_button_value: Button,
	stonecutter_button_value: Button,
	archery_range_button_value: Button,
	house_button_value: Button,
	farm_button_value: Button,
	wood_storage_button_value: Button,
	food_storage_button_value: Button,
	stone_storage_button_value: Button,
	upgrade_button_value: Button
) -> void:
	spawn_unit_button = spawn_unit_button_value
	spawn_stone_thrower_button = spawn_stone_thrower_button_value
	tower_button = tower_button_value
	woodcutter_button = woodcutter_button_value
	stonecutter_button = stonecutter_button_value
	archery_range_button = archery_range_button_value
	house_button = house_button_value
	farm_button = farm_button_value
	wood_storage_button = wood_storage_button_value
	food_storage_button = food_storage_button_value
	stone_storage_button = stone_storage_button_value
	upgrade_button = upgrade_button_value
	_update_buttons(1)

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

func can_spawn_unit() -> bool:
	return food >= unit_food_cost and current_units < max_units

func can_spawn_stone_thrower() -> bool:
	return food >= stone_thrower_food_cost and stone >= stone_thrower_stone_cost and current_units < max_units

func on_unit_spawned() -> void:
	food = clampi(food - unit_food_cost, 0, max_food)
	current_units += 1
	_update_all()

func on_stone_thrower_spawned() -> void:
	food = clampi(food - stone_thrower_food_cost, 0, max_food)
	stone = clampi(stone - stone_thrower_stone_cost, 0, max_stone)
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

func update_buttons_for_base_level(base_level_value: int, has_archery_range_value: bool) -> void:
	base_level = base_level_value
	has_archery_range = has_archery_range_value
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
	if spawn_unit_button != null:
		spawn_unit_button.disabled = not can_spawn_unit()
	if spawn_stone_thrower_button != null:
		spawn_stone_thrower_button.disabled = base_level_value < 2 or not has_archery_range or not can_spawn_stone_thrower()
	if tower_button != null:
		tower_button.disabled = wood < tower_cost
	if woodcutter_button != null:
		woodcutter_button.disabled = wood < woodcutter_cost
	if stonecutter_button != null:
		stonecutter_button.disabled = wood < stonecutter_cost or base_level_value < 2
	if archery_range_button != null:
		archery_range_button.disabled = wood < archery_range_cost
	if house_button != null:
		house_button.disabled = wood < house_cost
	if farm_button != null:
		farm_button.disabled = wood < farm_cost
	if wood_storage_button != null:
		wood_storage_button.disabled = wood < wood_storage_cost
	if food_storage_button != null:
		food_storage_button.disabled = wood < food_storage_cost
	if stone_storage_button != null:
		stone_storage_button.disabled = wood < stone_storage_cost
	if upgrade_button != null:
		upgrade_button.disabled = wood < base_upgrade_cost or (base_level_value >= 2 and stone < base_upgrade_stone_cost)
