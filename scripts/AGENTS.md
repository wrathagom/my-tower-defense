Scripts Folder

Main Flow
- Main.gd: top-level game loop, path generation, base placement, camera, wiring.
- UiBuilder.gd: constructs all runtime UI nodes and hooks signals.
- Placement.gd: build placement, hover, construction timing.
- Economy.gd: resource counts, caps, button gating, unit limits.
- ResourceCatalog.gd: resource registry (count, size, scene, guarantees).
- ResourceSpawner.gd: generic resource placement/spawn logic driven by catalog defs.
- Construction.gd: build-progress overlay and timer.
- UnitCatalog.gd: unit registry with costs, scenes, and unlock rules.
- UnitSpawner.gd: shared spawn logic for all units.
- BuildingCatalog.gd: building registry with costs, sizes, build times, placement rules.

Units
- Grunt.gd: melee ally with jitter and health bar.
- StoneThrower.gd: ranged ally that stops to throw.
- Enemy.gd: enemy pathing, melee, jitter, health bar.

Buildings/Objects
- Base.gd, Tower.gd, Tree.gd, Stone.gd, Iron.gd, storage and producer scripts.

Notes
- Many scripts rely on Main.gd helper methods (bounds, path cells, base cells).

How To Add A New Unit
- Create a new scene and script (e.g., `scenes/Slinger.tscn`, `scripts/Slinger.gd`) based on `Archer.gd` or `StoneThrower.gd`.
- Register the unit in `scripts/UnitCatalog.gd` with a unique ID, label, scene path, costs, and unlock rules.
- The Spawn Units UI auto-populates from the catalog, and `UnitSpawner.gd` handles instantiation.
- Ensure the unit script emits `reached_goal` and `died` signals (or at least `reached_goal`) to integrate with Main’s cleanup.

How To Add A New Building
- Create a new scene/script in `scenes/` + `scripts/` as needed.
- Register it in `scripts/BuildingCatalog.gd` with a unique ID, label, path, size, placement type, costs, and build time.
- Placement/hover and build buttons are generated from the catalog; no manual UI wiring required.
- If the building has a special effect, add an `effect` string in the catalog and handle it in `Placement._apply_building_effect`.
