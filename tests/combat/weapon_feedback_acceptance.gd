extends SceneTree

## Automated engine assertions. Perceptual checks are in the owner checklist.
const Arena = preload("res://scenes/combat/combat_test_arena.tscn")
const Player = preload("res://scenes/combat/combat_test_player.gd")
const Action = preload("res://scenes/combat/player_action_fsm.gd")
const Weapon = preload("res://scenes/combat/weapon_attack.gd")
const EnemyAttack = preload("res://scenes/combat/enemy_attack.gd")
const Enemy = preload("res://scenes/combat/enemy_health.gd")
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)


func _step(player: Player, delta: float, pressed := false, held := false, aim := Vector2.RIGHT, travel := Vector2.ZERO) -> void:
	var fsm := player.action_fsm
	fsm.step(delta, pressed, held, aim)
	var start := player.global_position
	player.global_position += travel
	player.motion_trace.record(player, start, 0.0, delta, delta)
	player._resolve_swings(start, delta)


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
	_moving_miss(player, Action.DAGGER, 0.035)
	_moving_miss(player, Action.SWORD, 0.055)
	_moving_miss(player, Action.GREATSWORD, 0.075)
	_recovery_hitstop(player)
	_interruptions(player)
	player._reset_encounter()
	for enemy in player.enemies:
		_recoil_transitions(enemy)
	arena.queue_free()
	print("Weapon feedback acceptance: %d failures" % failures)
	quit(1 if failures else 0)


func _moving_miss(player: Player, weapon: Weapon, fade: float) -> void:
	player._reset_encounter()
	var fx := player.weapon_effects
	player.action_fsm.select_weapon(weapon)
	var aim := Vector2.LEFT
	_step(player, weapon.wind_up + weapon.active * 0.5, true, false, aim, Vector2(0, 5))
	_check(fx._trail_id == 1 and not fx._angles.is_empty() and fx._fade_left == 0.0, "Moving miss has an active trail")
	if fx._angles.is_empty():
		return
	_check(fx.to_global(fx._trail_tip(-1)).is_equal_approx(player.global_position + aim * weapon.reach), "Active tip follows player")
	var second_half := weapon.active * 0.5
	_step(player, second_half + 0.010, false, false, aim.rotated(PI * 0.5), Vector2(0, 10))
	_check(not fx._angles.is_empty() and is_equal_approx(fx._fade_left, fade - 0.010), "Only 10 ms of this tick belongs to fade")
	if fx._angles.is_empty():
		return
	var correction := deg_to_rad(weapon.correction_speed) * second_half if weapon == Action.DAGGER else 0.0
	var tip := aim.rotated(deg_to_rad(weapon.sweep_angle * 0.5) + correction) * weapon.reach
	_check(fx.to_global(fx._trail_tip(-1)).is_equal_approx(player.global_position + tip), "Final blade edge stays attached at recovery entry")
	var angles := fx._angles.duplicate()
	_step(player, 0.012, false, false, aim, Vector2(6, 0))
	_check(fx._angles == angles and is_equal_approx(fx._fade_left, fade - 0.022), "Recovery changes opacity only")
	if not fx._angles.is_empty():
		_check(fx.to_global(fx._trail_tip(-1)).is_equal_approx(player.global_position + tip), "Fading edge follows further player movement")
	_step(player, fade - 0.022 + 0.001, false, false, aim)
	_check(fx._angles.is_empty() and fx._bursts.is_empty() and player.combat_audio._last_impact == 0, "Miss expires without impact")


func _recovery_hitstop(player: Player) -> void:
	player._reset_encounter()
	var fsm := player.action_fsm
	var fx := player.weapon_effects
	_step(player, fsm.weapon.wind_up + fsm.weapon.active + 0.005, true)
	_check(fsm.state == Action.State.RECOVERY and fsm.hitstop_remaining > 0.010, "Confirmed hit schedules recovery hitstop")
	var before := fsm._phase_elapsed
	var angles := fx._angles.duplicate()
	_step(player, 0.010)
	_check(fsm._phase_elapsed == before and fx._angles == angles, "Hitstop holds the attack clock and blade")
	_check(is_equal_approx(fx._fade_left, 0.020), "Completed trail continues fading in recovery hitstop")


func _interruptions(player: Player) -> void:
	var fsm := player.action_fsm
	var fx := player.weapon_effects
	for elapsed: float in [0.040, 0.100, 0.154]:
		player._reset_encounter()
		_step(player, elapsed, true)
		_check((fx._trail_id != 0) == (elapsed >= fsm.weapon.wind_up), "Wind-up cancellation has no onset")
		player._request_dodge(Vector2.UP, Vector2.RIGHT)
		_check(player.movement_fsm.is_dodging() and fsm.state == Action.State.READY, "Dodge interrupts execution")
		_check(fsm.active_intervals.is_empty() and fx._angles.is_empty() and not player.combat_audio._swing.playing, "Dodge invalidates samples, trail and swing")
		player._resolve_swings(player.global_position, 0.016)
		_check(fx._trail_id == 0, "Interrupted samples cannot recreate a trail")

	player._reset_encounter()
	_step(player, 0.100, true)
	var burst_count := fx._bursts.size()
	var lethal := EnemyAttack.Contact.new()
	lethal.damage = player.player_health.health
	player.player_health.resolve(lethal)
	_check(player.player_health.health == 0 and fx._trail_id == 0 and fsm.active_intervals.is_empty(), "Lethal contact cancels active presentation")
	_check(burst_count > 0 and fx._bursts.size() == burst_count and not player.combat_audio._primary.playing, "Confirmed bursts may finish during collapse, audio stops")
	player._physics_process(0.016)
	_check(fx._trail_id == 0 and player.combat_audio._last_swing == 0, "Dead player cannot restart a swing")


func _recoil_transitions(enemy: Enemy) -> void:
	# Vertical tracking isolates horizontal recoil and leaves base tilt at zero.
	var attack := enemy.attack
	attack.tracking = Vector2.UP
	enemy.receive_hit(Action.GREATSWORD, Vector2.RIGHT)
	enemy._process(enemy.recoil_duration * 0.14)
	var x := enemy._body.position.x
	var tilt := enemy._body.rotation
	_check(x > enemy.recoil_distance * 0.35, "Ordinary recoil exceeds wind-up bound")
	attack.phase = EnemyAttack.Phase.WIND_UP
	attack.remaining = attack.wind_up
	attack.refresh()
	_check(is_equal_approx(enemy._body.position.x, x) and is_equal_approx(enemy._body.rotation, tilt), "Wind-up entry preserves displayed recoil")
	enemy._process(0.020)
	_check(enemy._body.position.x > 0 and enemy._body.position.x <= enemy.recoil_distance * 0.35 + 0.0001, "Prior recoil eases into wind-up bound")
	x = enemy._body.position.x
	enemy._react(Vector2.LEFT, Action.GREATSWORD)
	enemy._process(0.0)
	_check(is_equal_approx(enemy._body.position.x, x), "Redirect starts from the visible pose")
	enemy._process(0.020)
	_check(is_equal_approx(enemy._body.position.x, -enemy.recoil_distance * 0.35), "Redirect reaches the reduced peak")
	attack.phase = EnemyAttack.Phase.ACTIVE
	attack.remaining = attack.active
	attack.refresh()
	_check(is_equal_approx(enemy._body.position.x, -enemy.recoil_distance * 0.35), "Active entry preserves releasing pose")
	enemy._process(0.010)
	_check(enemy._body.position.x < 0 and absf(enemy._body.position.x) < enemy.recoil_distance * 0.12, "Existing release eases into Active")
	enemy._react(Vector2.RIGHT, Action.GREATSWORD)
	enemy._process(0.020)
	_check(is_equal_approx(enemy._body.position.x, enemy.recoil_distance * 0.12), "Active hit has minimal peak")
	attack.phase = EnemyAttack.Phase.RECOVERY
	attack.remaining = attack.recovery
	attack.refresh()
	_check(is_equal_approx(enemy._body.position.x, enemy.recoil_distance * 0.12), "Recovery does not amplify a previous hit")
	enemy._process(enemy.recoil_duration)
	_check(is_zero_approx(enemy._body.position.x) and is_zero_approx(enemy._body.rotation), "Reaction returns to the attack pose")
