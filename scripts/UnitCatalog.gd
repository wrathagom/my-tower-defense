extends Node
class_name UnitCatalog

const ORDER := ["grunt", "stone_thrower", "archer"]

func get_order() -> Array[String]:
	var order: Array[String] = []
	for unit_id in ORDER:
		order.append(unit_id)
	return order

func build_defs(main: Node) -> Dictionary:
	return {
		"grunt": {
			"label": "Grunt",
			"scene": "res://scenes/Grunt.tscn",
			"food_cost": main.unit_food_cost,
			"wood_cost": 0,
			"stone_cost": 0,
			"requirements": [{"type": "base_level", "value": 1}],
		},
		"stone_thrower": {
			"label": "Stone Thrower",
			"scene": "res://scenes/StoneThrower.tscn",
			"food_cost": main.stone_thrower_food_cost,
			"wood_cost": 0,
			"stone_cost": main.stone_thrower_stone_cost,
			"requirements": [
				{"type": "base_level", "value": 2},
				{"type": "archery_level", "value": 1},
			],
		},
		"archer": {
			"label": "Archer",
			"scene": "res://scenes/Archer.tscn",
			"food_cost": main.archer_food_cost,
			"wood_cost": main.archer_wood_cost,
			"stone_cost": 0,
			"requirements": [
				{"type": "base_level", "value": 1},
				{"type": "archery_level", "value": 2},
			],
		},
	}
