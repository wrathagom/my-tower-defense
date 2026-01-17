Notes for Codex

- The Codex sandbox cannot run Godot headless test scripts here. Attempts to run
  `godot --headless --script res://tests/run_tests.gd` crash with Signal(6).
  Please avoid asking Codex to run tests; the user should run them locally.
