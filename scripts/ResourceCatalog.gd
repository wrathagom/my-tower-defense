extends Node
class_name ResourceCatalog

const ORDER := ["tree", "stone", "iron"]

func get_order() -> Array[String]:
	var order: Array[String] = []
	for resource_id in ORDER:
		order.append(resource_id)
	return order

func build_defs(main: Node) -> Dictionary:
	return {
		"tree": {
			"label": "Tree",
			"scene": "res://scenes/Tree.tscn",
			"count": main.tree_count,
			"map_key": "trees",
			"size": 2,
			"ensure_zone": "player_zone",
			"validation_rightmost": main.player_zone_width,
		},
		"stone": {
			"label": "Stone",
			"scene": "res://scenes/Stone.tscn",
			"count": main.stone_count,
			"map_key": "stones",
			"size": 2,
			"ensure_zone": "stone_band",
			"validation_rightmost": 10,
		},
		"iron": {
			"label": "Iron",
			"scene": "res://scenes/Iron.tscn",
			"count": main.iron_count,
			"map_key": "irons",
			"size": 2,
			"ensure_zone": "",
			"validation_rightmost": 13,
		},
	}
