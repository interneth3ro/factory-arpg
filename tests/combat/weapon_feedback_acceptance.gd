extends SceneTree

## Owner-run fixture for phase boundaries, repeated queries and generation reuse.
const Arena = preload("res://scenes/combat/combat_test_arena.tscn")
const Player = preload("res://scenes/combat/combat_test_player.gd")
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)


func _step(player: Player, delta: float, pressed := false, held := false) -> void:
	var fsm := player.action_fsm
	var paused := minf(delta, fsm.hitstop_remaining)
	fsm.step(delta, pressed, held, Vector2.RIGHT)
	player.motion_trace.record(player, player.global_position, 0.0, 0.0, delta)
	player._resolve_swings(player.global_position, delta, paused)


func _run() -> void:
	var arena := Arena.instantiate()
	var player: Player = arena.get_node("ArenaObjects/Player")
	player.position = Vector2(-180, 144)
	arena.get_node("ArenaObjects/Pursuer").position = player.position + Vector2(34, -18)
	arena.get_node("ArenaObjects/Heavy").position = player.position + Vector2(47, 21)
	root.add_child(arena)
	player.set_physics_process(false)
	for enemy in player.enemies:
		enemy.movement.set_physics_process(false)
	await physics_frame
	await physics_frame

	var fsm := player.action_fsm
	var fx := player.weapon_effects
	var audio := player.combat_audio
	_step(player, fsm.weapon.wind_up, true)
	_check(fsm.active_intervals.size() == 1 and fsm.active_intervals[0].duration == 0.0, "Exact-boundary entry")
	_check(audio._last_swing == 1 and fx._trail_id == 1 and fx._bursts.is_empty(), "Entry cues without damage")
	_step(player, 0.020)
	_check(fsm.hitstop_remaining > 0.0, "First target must confirm and request hitstop")
	var angles := fx._angles.duplicate()
	var burst_count := fx._bursts.size()
	_step(player, fsm.hitstop_remaining)
	_check(fx._angles == angles and fx._bursts.size() == burst_count, "Paused blade held without replay")
	_step(player, fsm.weapon.active - 0.020 + 0.001)
	_check(player.enemies[0].health == 65 and player.enemies[1].health == 140, "Exactly one hit on each disk")
	_check(fx._bursts.size() == 2 and fx._fade_left > 0.0, "Two bursts and a decaying trail")
	_check(audio._primary.playing and audio._secondary.playing, "Separate primary and secondary voices")
	var stale := fsm.active_intervals[0]
	player._reset_encounter()
	player._reset_encounter()
	_check(fx._bursts.is_empty() and not fx._weapon and audio._last_swing == 0, "Repeated reset clears feedback")
	_check(not audio._primary.playing and not audio._secondary.playing and not audio._swing.playing, "Reset stops voices")
	_step(player, fsm.weapon.wind_up, true)
	player._apply_contact(player.enemies[0], stale, Vector2.ZERO, Vector2.RIGHT)
	_check(fx._bursts.is_empty() and player.enemies[0].health == 75, "Old interval rejected after ID reuse")

	player._reset_encounter()
	_step(player, 0.47, true, true)
	_check(fsm.active_intervals.size() == 2 and fsm.attack_count == 2, "Two active intervals in one tick")
	_check(audio._last_swing == 2 and audio._last_impact == 2, "Both attacks reached swing and contact")
	_check(fx._bursts.size() == 4 and fx._trail_id == 2, "Per-execution effects across recovery and repeat")
	_check(player.enemies[0].health == 55 and player.enemies[1].health == 130, "Two hits per target")
	arena.queue_free()
	print("Weapon feedback acceptance: %d failures" % failures)
	quit(1 if failures else 0)
