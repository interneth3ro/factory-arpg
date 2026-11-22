extends SceneTree

const Arena = preload("res://scenes/combat/combat_test_arena.tscn")
const Player = preload("res://scenes/combat/combat_test_player.gd")
const Enemy = preload("res://scenes/combat/enemy_health.gd")
const Attack = preload("res://scenes/combat/enemy_attack.gd")
const ORIGIN := Vector2(-400, -170)
const SHOT_INTERVAL := 1.0 / 3.0
var player: Player
var pursuer: Enemy
var heavy: Enemy
var barrier := CollisionShape2D.new()
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)


func _run() -> void:
	var arena := Arena.instantiate()
	var thin := RectangleShape2D.new()
	thin.size = Vector2(1, 16)
	barrier.shape = thin
	arena.get_node("Boundaries").add_child(barrier)
	root.add_child(arena)
	player = arena.get_node("ArenaObjects/Player")
	pursuer = player.enemies[0]
	heavy = player.enemies[1]
	player.set_physics_process(false)
	for enemy in player.enemies:
		enemy.movement.set_physics_process(false)
	await physics_frame
	_geometry()
	_press_at_readiness()
	_rapid_taps()
	_timing()
	_launch_poses()
	await _strafe()
	await _lifecycle()
	arena.queue_free()
	await arena.tree_exited
	print("Pistol acceptance: %d failures" % failures)
	quit(1 if failures else 0)


func _trial(wall_x := -300.0, wall_gap := 0.0) -> void:
	player._solo_enemy = null
	player._reset_encounter(true)
	player.global_position = ORIGIN
	pursuer.global_position = ORIGIN + Vector2(200, 90)
	heavy.global_position = ORIGIN + Vector2(350, 90)
	# The argument locates the nearest corner relative to the shot line.
	barrier.global_position = ORIGIN + Vector2(wall_x + 0.5, wall_gap + 8.0)
	player.projectiles.configure(player.enemies, player._apply_pistol_contact)


func _fire() -> void:
	player.projectiles.launch(ORIGIN, Vector2.RIGHT, player.encounter_generation)


func _geometry() -> void:
	var sim := player.projectiles
	_trial()
	_fire()
	sim.advance(0.1)
	check(sim.bullets.size() == 1 and sim.bullets[0].center() == ORIGIN + Vector2(120, 0), "20 px muzzle plus 100 px in 100 ms")
	sim.advance(1.0)
	check(sim.bullets.is_empty(), "Open flight expires in a long tick")
	for wall_x in [0, 10, 84]:
		for gap in [0, 3, 5]:
			_trial(wall_x, gap)
			pursuer.global_position = ORIGIN + Vector2(140, 0)
			_fire()
			if wall_x <= 10:
				check(sim.bullets.is_empty() == (gap <= 4), "Initial overlap/muzzle sweep at %d, gap %d" % [wall_x, gap])
			sim.advance(0.2)
			check(pursuer.health == (60 if gap > 4 else 75), "Thin cover at %d, gap %d" % [wall_x, gap])
	_trial()
	heavy.global_position = ORIGIN + Vector2(100, 0)
	pursuer.global_position = ORIGIN + Vector2(170, 0)
	_fire()
	sim.advance(0.30)
	sim.advance(1.0)
	check(heavy.health == 135 and pursuer.health == 75 and sim.sparks.size() == 1, "Only nearer Heavy takes one hit")
	check(sim.sparks.size() == 1 and sim.sparks[0].point == ORIGIN + Vector2(75, 0), "Contact spark on Heavy surface")
	check(heavy._flash_strength > 0.0 and heavy._recoil_target == Vector3.ZERO, "Flash without recoil")
	_trial()
	pursuer.global_position = ORIGIN
	_fire()
	check(pursuer.health == 60 and sim.bullets.is_empty(), "Enemy overlaps combat origin")
	for offset in [-0.125, 0.0, 0.125]:
		_trial(100, -8)
		pursuer.global_position = ORIGIN + Vector2(114 + offset, 0)
		_fire()
		sim.advance(0.55)
		check(pursuer.health == (60 if offset < 0.0 else 75), "Enemy versus solid entry offset %.3f" % offset)
	for distance in [599, 600, 601]:
		_trial()
		# 20 px muzzle + contact distance + 4 px bullet + 14 px enemy.
		pursuer.global_position = ORIGIN + Vector2(38 + distance, 0)
		_fire()
		sim.advance(1.5)
		check(pursuer.health == (60 if distance <= 600 else 75) and sim.bullets.is_empty(), "Inclusive clipped range %d" % distance)


func _equip_pistol() -> void:
	player.pending_style = Player.Style.PISTOL
	player._step_actions(0.01, true, true)
	player._step_actions(0.5, false, true)
	check(player.active_style == Player.Style.PISTOL and player.pistol.shots_fired == 0, "Switch under held primary needs a fresh press")


func _press_at_readiness() -> void:
	var pistol := player.pistol
	for delta: float in [0.005, 0.015]:
		_trial()
		_equip_pistol()
		player._step_actions(SHOT_INTERVAL - 0.010, true, false)
		check(is_equal_approx(pistol.cooldown, 0.010), "10 ms remain before the tap")
		player._step_actions(delta, true, false)
		check(pistol.shots.is_empty(), "Early tap discarded in a %.0f ms step" % (delta * 1000.0))
		player._step_actions(0.020, false, false)
		check(pistol.shots_fired == 1 and pistol.cooldown == 0.0, "Discarded tap stays silent through readiness")
		player._step_actions(0.005, true, false)
		check(pistol.shots == PackedFloat64Array([0.0]), "Fresh tap at zero cooldown fires at offset zero")

	_trial()
	_equip_pistol()
	player._step_actions(SHOT_INTERVAL - 0.010, true, false)
	player._step_actions(0.005, true, true)
	player._step_actions(0.010, false, false)
	check(pistol.shots_fired == 1, "Releasing an ordinary hold before readiness cancels the repeat")
	player._step_actions(SHOT_INTERVAL - 0.000001, true, false)
	player._step_actions(0.010, true, false)
	check(pistol.shots_fired == 2 and pistol.shots.is_empty(), "Tap one microsecond before readiness expires without firing")


func _rapid_taps() -> void:
	for hz: int in [30, 60, 120, 144]:
		_trial()
		_equip_pistol()
		# Each input sample sees a press already released. All four rates
		# sample the exact one-third-second boundaries at whole ticks.
		for tick in hz:
			player._step_actions(1.0 / hz, true, false)
			var expected := PackedFloat64Array()
			if (tick * 3) % hz == 0:
				expected.append(0.0)
			check(player.pistol.shots == expected, "Tap offsets at %d Hz, tick %d" % [hz, tick])
		check(player.pistol.shots_fired == 3, "Three tap shots before one second at %d Hz" % hz)


func _timing() -> void:
	for tick_rate in [30, 60, 120, 144]:
		_trial()
		_equip_pistol()
		var movement := 0.0
		for i in tick_rate:
			movement += player._step_actions(1.0 / tick_rate, i == 0, true) / tick_rate
		check(player.pistol.shots_fired == 4 and is_equal_approx(movement, 1.0 - 3.0 * 0.12 * 0.2), "Inclusive one-second cadence and travel at %d Hz" % tick_rate)
	_trial()
	_equip_pistol()
	var pistol := player.pistol
	var scale_factor := player._step_actions(0.75, true, true)
	check(pistol.shots.size() == 3 and pistol.shots[0] == 0.0 and is_equal_approx(pistol.shots[1], 1.0 / 3.0) and is_equal_approx(pistol.shots[2], 2.0 / 3.0), "Three cadence boundaries in one tick")
	var committed := 0.24 + (0.75 - 2.0 / 3.0)
	check(is_equal_approx(scale_factor * 0.75, 0.75 - 0.2 * committed), "Three movement windows integrated across a long step")
	player._step_actions(0.05, false, false)
	player._step_actions(0.01, true, false)
	check(pistol.shots_fired == 3, "Rapid tap cannot bypass cadence")
	player._step_actions(1.0, false, false)
	check(pistol.shots_fired == 3, "Release stops repeat")
	var first := player._step_actions(0.06, true, false)
	check(pistol.shots_fired == 4 and is_equal_approx(first * player.movement_speed, 176.0), "Ready fresh press and committed full-input speed")
	player.pending_style = Player.Style.SWORD
	player._step_actions(0.05, false, true)
	check(player.active_style == Player.Style.PISTOL and player.pending_style == Player.Style.SWORD, "Switch still pending at 110 ms")
	var tail := player._step_actions(0.02, false, true)
	check(is_equal_approx(tail, 0.9) and player.active_style == Player.Style.SWORD and pistol.cooldown > 0.2, "120 ms boundary splits movement and activates Sword")
	player._step_actions(0.4, false, true)
	check(player.action_fsm.attack_count == 0, "Held pistol input cannot transfer to melee")
	_trial()
	_equip_pistol()
	player._step_actions(0.15, true, true)
	player.pending_style = Player.Style.SWORD
	player._step_actions(0.2, false, true)
	player.pending_style = Player.Style.PISTOL
	player._step_actions(0.5, false, true)
	check(pistol.shots_fired == 1 and not pistol.repeating, "Immediate switch away and back clears outgoing held repeat")
	_trial()
	_equip_pistol()
	player._step_actions(0.08, true, false)
	player._step_actions(0.10, false, false)
	player._step_actions(0.20, true, true)
	check(pistol.shots_fired == 2 and is_equal_approx(pistol.shots[0], 1.0 / 3.0 - 0.18), "New hold during ordinary cooldown waits until readiness")
	_trial()
	_equip_pistol()
	player._step_actions(0.06, true, true)
	player._request_dodge(Vector2.UP, Vector2.RIGHT)
	check(player.movement_fsm.is_invulnerable() and pistol.commitment == 0.0 and not pistol.repeating, "Successful dodge interrupts immediately")
	player._physics_process(player.movement_fsm.dodge_duration)
	player._step_actions(0.005, false, true)
	player._step_actions(0.005, false, false)
	player._step_actions(0.01, true, false)
	check(pistol.shots_fired == 1, "Dodge keeps original cadence")
	player._step_actions(0.020, true, true)
	check(pistol.cooldown == 0.0 and pistol.shots.is_empty(), "Early post-dodge press stays ineligible across readiness, even if held")
	player._step_actions(0.5, false, true)
	check(pistol.shots_fired == 1, "Held input after dodge stays silent")
	player._step_actions(0.01, false, false)
	player._step_actions(0.01, true, true)
	check(pistol.shots_fired == 2, "Fresh ready press after dodge fires")
	player.movement_fsm.step(Vector2.ZERO, 220.0, 0.2)
	player.pending_style = Player.Style.GREATSWORD
	player._request_dodge(Vector2.DOWN, Vector2.RIGHT)
	check(player.pending_style == Player.Style.GREATSWORD, "Queued style survives pistol interruption")
	player._record_style_request(Player.Style.SWORD, 1)
	player._physics_process(player.movement_fsm.dodge_duration)
	check(player.active_style == Player.Style.SWORD, "Latest request activates on final dodge tick")


func _launch_poses() -> void:
	_trial()
	_equip_pistol()
	var delta := 0.36
	var speed := player._step_actions(delta, true, true) * player.movement_speed
	# Supply an unobstructed resolved slide path with the integrated distance.
	var trace := player.motion_trace
	trace.positions = PackedVector2Array([ORIGIN, ORIGIN + Vector2.RIGHT * speed * delta])
	trace.times = PackedFloat64Array([0.0, delta])
	trace.retime(player.pistol.times, player.pistol.movement_times)
	var cursor := ORIGIN + Vector2(600, 10)
	player._step_projectiles(delta, cursor)
	var shots := player.projectiles.bullets
	check(shots.size() == 2, "Both shots remain in the open lane")
	if shots.size() == 2:
		var second_origin := ORIGIN + Vector2.RIGHT * (176.0 * 0.12 + 220.0 * (1.0 / 3.0 - 0.12))
		var second_heading := second_origin.direction_to(cursor)
		check(shots[0].direction.is_equal_approx(ORIGIN.direction_to(cursor)) and is_equal_approx(shots[0].traveled, 360.0), "First shot keeps its original heading and age")
		check(shots[1].direction.is_equal_approx(second_heading) and shots[1].muzzle.is_equal_approx(second_origin + second_heading * 20.0), "Repeat uses firing-time position and aim")
		check(is_equal_approx(shots[1].traveled, (delta - 1.0 / 3.0) * 1000.0), "Second shot travels only after launch")


func _strafe() -> void:
	_trial()
	_equip_pistol()
	var delta := 1.0 / Engine.physics_ticks_per_second
	var ticks := ceili(0.15 / delta)
	Input.action_press("move_right")
	Input.action_press("basic_attack")
	for i in ticks:
		await physics_frame
		player._physics_process(delta)
	Input.action_release("move_right")
	Input.action_release("basic_attack")
	var distance := 176.0 * 0.12 + 220.0 * (ticks * delta - 0.12)
	check(player.pistol.shots_fired == 1 and absf(player.position.x - ORIGIN.x - distance) < 0.001, "Input path integrates committed and ordinary strafe distance")


func _lifecycle() -> void:
	_trial()
	_equip_pistol()
	pursuer.global_position = ORIGIN + Vector2(180, 0)
	player._step_actions(0.06, true, false)
	player.motion_trace.record(player, ORIGIN, 0.0, 0.06, 0.06)
	player._step_projectiles(0.06, ORIGIN + Vector2.RIGHT * 500.0)
	player.pending_style = Player.Style.DAGGER
	player._step_actions(0.06, false, false)
	player.projectiles.advance(0.06)
	check(player.active_style == Player.Style.DAGGER and player.projectiles.bullets.size() == 1, "Bullet survives style switch")
	var fsm := player.action_fsm
	fsm.step(fsm.weapon.wind_up, true, false, Vector2.DOWN)
	fsm.request_hitstop(fsm.active_intervals[0])
	player._step_actions(0.01, false, false)
	player.projectiles.advance(0.01)
	check(fsm.hitstop_remaining > 0.0 and player.projectiles.bullets.size() == 1 and player.projectiles.bullets[0].center() == ORIGIN + Vector2(150, 0), "Bullet moves at full speed during melee hitstop")
	player.projectiles.advance(0.02)
	check(pursuer.health == 60 and player.projectiles.bullets.is_empty(), "In-flight shot damages after switching")
	await physics_frame
	pursuer.attack.start_tick(0.02)
	heavy.attack.start_tick(0.02)
	check(is_equal_approx(pursuer.attack.paused_this_tick, 0.016) and heavy.attack.paused_this_tick == 0.0, "Ranged hitstop applies only to struck enemy")
	_trial()
	player._solo_enemy = heavy
	player._reset_encounter(true)
	pursuer.global_position = ORIGIN + Vector2(60, 0)
	heavy.global_position = ORIGIN + Vector2(100, 0)
	heavy.health = 15
	_fire()
	player.projectiles.advance(0.15)
	check(pursuer.health == 75 and heavy.health == 0 and player.completion.visible, "Excluded target is transparent and pistol completes solo encounter")
	_fire()
	player.projectiles.advance(0.15)
	check(player.projectiles.bullets.size() == 1 and heavy.receive_pistol_hit() == 0 and pursuer.receive_pistol_hit() == 0, "Defeated and excluded enemies ignore damage")
	_trial()
	_equip_pistol()
	_fire()
	var generation := player.encounter_generation
	player.pending_style = Player.Style.SWORD
	player._reset_encounter()
	player.projectiles.launch(ORIGIN, Vector2.RIGHT, generation)
	check(player.projectiles.bullets.is_empty() and not player._apply_pistol_contact(pursuer, 1, generation), "F5 rejects old shot and damage")
	player._step_actions(0.5, false, true)
	check(player.active_style == Player.Style.PISTOL and player.pending_style == Player.Style.NONE and player.pistol.shots_fired == 0, "F5 retains Pistol and requires fresh press")
	_fire()
	var lethal := Attack.Contact.new()
	lethal.damage = player.player_health.health
	player.player_health.resolve(lethal)
	player.projectiles.advance(1.0)
	player.projectiles.launch(ORIGIN, Vector2.RIGHT, player.encounter_generation)
	check(player.player_health.health == 0 and player.projectiles.bullets.is_empty() and player.projectiles.sparks.is_empty(), "Death removes bullets and blocks later launches")
	check(not player._apply_pistol_contact(pursuer, 1, player.encounter_generation) and pursuer.health == 75, "Terminal encounter rejects pending damage")
	player._reset_encounter(true)
	check(player.active_style == Player.Style.DAGGER and player.pistol.shots_fired == 0, "Configuration reset restores Dagger")
