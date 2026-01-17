extends Node
class_name BuildingCatalog

const ORDER := [
	"tower",
	"woodcutter",
	"stonecutter",
	"archery_range",
	"house",
	"farm",
	"wood_storage",
	"food_storage",
	"stone_storage",
]

func get_order() -> Array[String]:
	var order: Array[String] = []
	for building_id in ORDER:
		order.append(building_id)
	return order

func build_defs(main: Node) -> Dictionary:
	return {
		"tower": {
			"label": "Tower",
			"spawn_type": "script",
			"path": "res://scripts/Tower.gd",
			"size": 1,
			"placement": "grid",
			"costs": {"wood": main.tower_cost},
			"build_time": main.build_time_tower,
			"min_base_level": 1,
			"uses_occupied": true,
		},
		"woodcutter": {
			"label": "Woodcutter",
			"spawn_type": "scene",
			"path": "res://scenes/Woodcutter.tscn",
			"size": 2,
			"placement": "tree",
			"costs": {"wood": main.woodcutter_cost},
			"build_time": main.build_time_woodcutter,
			"min_base_level": 1,
			"resource_kind": "wood",
		},
		"stonecutter": {
			"label": "Stonecutter",
			"spawn_type": "scene",
			"path": "res://scenes/Stonecutter.tscn",
			"size": 2,
			"placement": "stone",
			"costs": {"wood": main.stonecutter_cost},
			"build_time": main.build_time_stonecutter,
			"min_base_level": 2,
			"resource_kind": "stone",
		},
		"archery_range": {
			"label": "Archery Range",
			"spawn_type": "scene",
			"path": "res://scenes/ArcheryRange.tscn",
			"size": 3,
			"placement": "grid",
			"costs": {"wood": main.archery_range_cost},
			"build_time": main.build_time_archery_range,
			"min_base_level": 2,
			"effect": "archery_range",
		},
		"house": {
			"label": "House",
			"spawn_type": "scene",
			"path": "res://scenes/House.tscn",
			"size": 2,
			"placement": "grid",
			"costs": {"wood": main.house_cost},
			"build_time": main.build_time_house,
			"min_base_level": 1,
			"effect": "house",
		},
		"farm": {
			"label": "Farm",
			"spawn_type": "scene",
			"path": "res://scenes/Farm.tscn",
			"size": 2,
			"placement": "grid",
			"costs": {"wood": main.farm_cost},
			"build_time": main.build_time_farm,
			"min_base_level": 1,
			"effect": "farm",
		},
		"wood_storage": {
			"label": "Wood Storage",
			"spawn_type": "scene",
			"path": "res://scenes/WoodStorage.tscn",
			"size": 2,
			"placement": "grid",
			"costs": {"wood": main.wood_storage_cost},
			"build_time": main.build_time_wood_storage,
			"min_base_level": 1,
			"effect": "wood_storage",
		},
		"food_storage": {
			"label": "Food Storage",
			"spawn_type": "scene",
			"path": "res://scenes/FoodStorage.tscn",
			"size": 2,
			"placement": "grid",
			"costs": {"wood": main.food_storage_cost},
			"build_time": main.build_time_food_storage,
			"min_base_level": 1,
			"effect": "food_storage",
		},
		"stone_storage": {
			"label": "Stone Storage",
			"spawn_type": "scene",
			"path": "res://scenes/StoneStorage.tscn",
			"size": 2,
			"placement": "grid",
			"costs": {"wood": main.stone_storage_cost},
			"build_time": main.build_time_stone_storage,
			"min_base_level": 2,
			"effect": "stone_storage",
		},
	}
