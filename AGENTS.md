Project Guide

Overview
- Godot 4 tower defense/resource prototype.
- Main entry: scenes/Main.tscn with scripts/Main.gd.
- Tests: tests/run_tests.gd (run locally; Codex sandbox cannot execute Godot headless).

Key Folders
- scenes/: PackedScene assets for units, buildings, projectiles, bases, etc.
- scripts/: Gameplay logic (Main, Economy, Placement, ResourceSpawner, units, buildings).
- tests/: Lightweight GDScript test runner and cases.

Important Notes
- UI is built in scripts/UiBuilder.gd.
- Resource spawn logic lives in scripts/ResourceSpawner.gd.
- Build/placement logic lives in scripts/Placement.gd.
- Economy, caps, and button enabling lives in scripts/Economy.gd.
