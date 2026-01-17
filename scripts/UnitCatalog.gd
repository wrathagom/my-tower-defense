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
			"min_base_level": 1,
			"requires_archery_range": false,
			"requires_archery_range_upgrade": false,
		},
		"stone_thrower": {
			"label": "Stone Thrower",
			"scene": "res://scenes/StoneThrower.tscn",
			"food_cost": main.stone_thrower_food_cost,
			"wood_cost": 0,
			"stone_cost": main.stone_thrower_stone_cost,
			"min_base_level": 2,
			"requires_archery_range": true,
			"requires_archery_range_upgrade": false,
		},
		"archer": {
			"label": "Archer",
			"scene": "res://scenes/Archer.tscn",
			"food_cost": main.archer_food_cost,
			"wood_cost": main.archer_wood_cost,
			"stone_cost": 0,
			"min_base_level": 1,
			"requires_archery_range": false,
			"requires_archery_range_upgrade": true,
		},
	}
