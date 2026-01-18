extends Node
class_name ResourceCatalog

const GameConfig = preload("res://scripts/GameConfig.gd")

const ORDER := ["tree", "stone", "iron"]

func get_order() -> Array[String]:
	var order: Array[String] = []
	for resource_id in ORDER:
		order.append(resource_id)
	return order

func build_defs(config: GameConfig) -> Dictionary:
	return {
		"tree": {
			"label": "Tree",
			"scene": "res://scenes/Tree.tscn",
			"count": config.tree_count,
			"map_key": "trees",
			"size": 2,
			"ensure_zone": "player_zone",
			"validation_rightmost": config.player_zone_width,
		},
		"stone": {
			"label": "Stone",
			"scene": "res://scenes/Stone.tscn",
			"count": config.stone_count,
			"map_key": "stones",
			"size": 2,
			"ensure_zone": "stone_band",
			"validation_rightmost": 10,
		},
		"iron": {
			"label": "Iron",
			"scene": "res://scenes/Iron.tscn",
			"count": config.iron_count,
			"map_key": "irons",
			"size": 2,
			"ensure_zone": "",
			"validation_rightmost": 13,
		},
	}
