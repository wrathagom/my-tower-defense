extends SceneTree

func _init() -> void:
	var failed := 0
	if not _test_path_valid():
		failed += 1
	if not _test_path_invalid():
		failed += 1
	if not _test_economy_caps():
		failed += 1
	if not _test_unit_limits():
		failed += 1
	if not _test_unit_catalog():
		failed += 1
	if not _test_building_catalog():
		failed += 1

	if failed > 0:
		print("Tests failed: %d" % failed)
		quit(1)
		return

	print("All tests passed.")
	quit(0)

func _test_path_valid() -> bool:
	var MainScript: Script = preload("res://scripts/Main.gd")
	var main: Node = MainScript.new()
	main.grid_width = 5
	main.grid_height = 3
	main.path_margin = 0
	var cells: Array[Vector2i] = []
	cells.append(Vector2i(0, 1))
	cells.append(Vector2i(1, 1))
	cells.append(Vector2i(2, 1))
	cells.append(Vector2i(3, 1))
	cells.append(Vector2i(4, 1))
	main.set_path_cells(cells)
	var ok: bool = true
	if not main._path_valid:
		ok = false
	if main._ordered_path_cells.size() != 5:
		ok = false
	if main._ordered_path_cells[0] != Vector2i(0, 1):
		ok = false
	if main._ordered_path_cells[4] != Vector2i(4, 1):
		ok = false
	main.free()
	return ok

func _test_path_invalid() -> bool:
	var MainScript: Script = preload("res://scripts/Main.gd")
	var main: Node = MainScript.new()
	main.grid_width = 5
	main.grid_height = 3
	main.path_margin = 0
	var cells: Array[Vector2i] = []
	cells.append(Vector2i(0, 1))
	cells.append(Vector2i(2, 1))
	cells.append(Vector2i(4, 1))
	main.set_path_cells(cells)
	var ok: bool = not main._path_valid
	main.free()
	return ok

func _test_economy_caps() -> bool:
	var EconomyScript: Script = preload("res://scripts/Economy.gd")
	var economy: Node = EconomyScript.new()
	economy.configure_resources(0, 0, 0, 50, 2)
	economy.add_wood(999)
	economy.add_food(999)
	economy.add_stone(999)
	if economy.wood != 50:
		economy.free()
		return false
	if economy.food != 50:
		economy.free()
		return false
	if economy.stone != 50:
		economy.free()
		return false
	economy.add_wood_cap(50)
	economy.add_wood(30)
	var ok: bool = economy.wood == 80 and economy.max_wood == 100
	economy.free()
	return ok

func _test_unit_limits() -> bool:
	var EconomyScript: Script = preload("res://scripts/Economy.gd")
	var economy: Node = EconomyScript.new()
	economy.configure_resources(0, 0, 0, 50, 2)
	if economy.can_spawn_unit():
		economy.free()
		return false
	economy.add_food(4)
	economy.add_unit_capacity(1)
	if not economy.can_spawn_unit():
		economy.free()
		return false
	economy.on_unit_spawned()
	if economy.current_units != 1:
		economy.free()
		return false
	if economy.food != 2:
		economy.free()
		return false
	if economy.can_spawn_unit():
		economy.free()
		return false
	economy.on_unit_removed()
	var ok: bool = economy.current_units == 0
	economy.free()
	return ok

func _test_unit_catalog() -> bool:
	var UnitCatalogScript: Script = preload("res://scripts/UnitCatalog.gd")
	var MainScript: Script = preload("res://scripts/Main.gd")
	var main: Node = MainScript.new()
	var catalog: Node = UnitCatalogScript.new()
	var defs: Dictionary = catalog.build_defs(main)
	var order: Array[String] = catalog.get_order()
	if order.is_empty():
		main.free()
		catalog.free()
		return false
	for unit_id in order:
		if not defs.has(unit_id):
			main.free()
			catalog.free()
			return false
		var def: Dictionary = defs[unit_id]
		if str(def.get("scene", "")) == "":
			main.free()
			catalog.free()
			return false
	main.free()
	catalog.free()
	return true

func _test_building_catalog() -> bool:
	var BuildingCatalogScript: Script = preload("res://scripts/BuildingCatalog.gd")
	var MainScript: Script = preload("res://scripts/Main.gd")
	var main: Node = MainScript.new()
	var catalog: Node = BuildingCatalogScript.new()
	var defs: Dictionary = catalog.build_defs(main)
	var order: Array[String] = catalog.get_order()
	if order.is_empty():
		main.free()
		catalog.free()
		return false
	for building_id in order:
		if not defs.has(building_id):
			main.free()
			catalog.free()
			return false
		var def: Dictionary = defs[building_id]
		if str(def.get("path", "")) == "":
			main.free()
			catalog.free()
			return false
	main.free()
	catalog.free()
	return true
