extends SceneTree

## Automated engine assertions. Perceptual checks are in the owner checklist.
const ArenaController = preload("res://scenes/combat/combat_test_arena.gd")
const Arena = preload("res://scenes/combat/combat_test_arena.tscn")
const Player = preload("res://scenes/combat/combat_test_player.gd")
const Action = preload("res://scenes/combat/player_action_fsm.gd")
const Weapon = preload("res://scenes/combat/weapon_attack.gd")
const EnemyAttack = preload("res://scenes/combat/enemy_attack.gd")
const Enemy = preload("res://scenes/combat/enemy_health.gd")
var arena: ArenaController
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


func _primary(pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _run() -> void:
	arena = Arena.instantiate()
	var player: Player = arena.get_node("ArenaObjects/Player")
	_check(player.aim_direction == Vector2.RIGHT, "Initial shared aim faces right")
	player.position = Vector2(-180, 144)
	arena.get_node("ArenaObjects/Pursuer").position = player.position + Vector2(34, -18)
	arena.get_node("ArenaObjects/Heavy").position = player.position + Vector2(47, 21)
	root.add_child(arena)
	player.set_physics_process(false)
	for enemy in arena.enemies:
		enemy.movement.set_physics_process(false)
	await physics_frame
	await physics_frame
	await _style_selection(player)
	await _style_boundaries(player)
	await _style_dodge(player)
	arena.reset_encounter(true)
	await _encounter_selector(player)
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
	_check(arena.enemies[0].health == 65 and arena.enemies[1].health == 140, "Exactly one hit on each disk")
	_check(fx._bursts.size() == 2 and fx._fade_left > 0.0, "Two bursts and a decaying trail")
	_check(audio._primary.playing and audio._secondary.playing, "Separate primary and secondary voices")
	var stale := fsm.active_intervals[0]
	arena.reset_encounter()
	arena.reset_encounter()
	_check(fx._bursts.is_empty() and not fx._weapon and audio._last_swing == 0, "Repeated reset clears feedback")
	_check(not audio._primary.playing and not audio._secondary.playing and not audio._swing.playing, "Reset stops voices")
	_step(player, fsm.weapon.wind_up, true)
	player._apply_contact(arena.enemies[0], stale, Vector2.ZERO, Vector2.RIGHT)
	_check(fx._bursts.is_empty() and arena.enemies[0].health == 75, "Old interval rejected after ID reuse")

	arena.reset_encounter()
	_step(player, 0.47, true, true)
	_check(fsm.active_intervals.size() == 2 and fsm.attack_count == 2, "Two active intervals in one tick")
	_check(audio._last_swing == 2 and audio._last_impact == 2, "Both attacks reached swing and contact")
	_check(fx._bursts.size() == 4 and fx._trail_id == 2, "Per-execution effects across recovery and repeat")
	_check(arena.enemies[0].health == 55 and arena.enemies[1].health == 130, "Two hits per target")
	_moving_miss(player, Action.DAGGER, 0.035)
	_moving_miss(player, Action.SWORD, 0.055)
	_moving_miss(player, Action.GREATSWORD, 0.075)
	_recovery_hitstop(player)
	_interruptions(player)
	arena.reset_encounter()
	for enemy in arena.enemies:
		_recoil_transitions(enemy)
		arena.reset_encounter()
		var coarse := _release_into_active(enemy, PackedFloat64Array([0.033]))
		arena.reset_encounter()
		var split := _release_into_active(enemy, PackedFloat64Array([0.011, 0.011, 0.011]))
		_check(coarse.is_equal_approx(split), "%s release pose at 33 ms is independent of frame splits" % enemy.name)
	arena.queue_free()
	await arena.tree_exited
	# Let the mixer release stopped WAV playbacks before shutting down the audio server.
	await create_timer(0.1).timeout
	print("Weapon feedback acceptance: %d failures" % failures)
	quit(1 if failures else 0)


func _send_key(key: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


# Sample the normal player input path once so the fixture can inspect the reset before combat resumes.
func _key_tick(player: Player, key: Key) -> void:
	_send_key(key, true)
	await physics_frame
	player._physics_process(1.0 / Engine.physics_ticks_per_second)
	_send_key(key, false)


func _toggle_debug() -> void:
	# F3 uses viewport event propagation. Exercise it even with a headless display.
	var event := InputEventKey.new()
	event.keycode = KEY_F3
	event.pressed = true
	root.push_input(event)
	event.pressed = false
	root.push_input(event)


func _style_selection(player: Player) -> void:
	await _key_tick(player, KEY_4)
	_check(player.active_style == Player.Style.PISTOL and arena.style_label.text == "Style: Pistol", "4 selects Pistol with F3 closed")
	player._sample_aim_direction(Vector2(3, 4))
	var diagonal := Vector2(0.6, 0.8)
	player._sample_aim_direction(Vector2.ZERO)
	player._sample_aim_direction(Vector2(NAN, INF))
	player.global_position = player.get_global_mouse_position() - Vector2(4, 0)
	player._update_facing()
	_check(player.aim_direction.is_equal_approx(diagonal), "Pistol retains normalized aim on invalid, neutral and dead-zone samples")
	_primary(true)
	await physics_frame
	player._physics_process(0.5)
	_check(player.pistol.shots_fired == 2 and player.action_fsm.attack_count == 0 and player.combat_audio._last_swing == 0, "Held Pistol fires twice without a melee swing")
	await _select(player, KEY_F5)
	await _key_tick(player, KEY_2)
	_check(player.action_fsm.weapon == Action.SWORD and player.action_fsm.attack_count == 0, "Held primary cannot transfer from Pistol to Sword")
	_primary(false)
	await physics_frame
	_primary(true)
	await physics_frame
	player._physics_process(0.01)
	_check(player.action_fsm.attack_count == 1, "Fresh press starts the selected sword")
	await _key_tick(player, KEY_4)
	_check(arena.style_label.text.contains("Pending: Pistol"), "Committed sword queues Pistol")
	_toggle_debug()
	_check(arena.style_label.is_visible_in_tree() and arena.style_label.text.contains("Pending: Pistol"), "Pending visible with F3 open")
	await _select(player, KEY_F5)
	_check(arena.state_diagnostics.visible and arena.style_label.text == "Style: Sword", "F5 preserves active sword and F3, discards pending Pistol")
	await physics_frame
	player._physics_process(0.5)
	_check(player.action_fsm.attack_count == 0, "Held primary stays idle after F5")
	_primary(false)
	_toggle_debug()


func _style_boundaries(player: Player) -> void:
	arena.reset_encounter(true)
	var fsm := player.action_fsm
	# Two distinct samples in one physics tick: the later lower slot wins.
	_send_key(KEY_4, true)
	await _key_tick(player, KEY_3)
	_send_key(KEY_4, false)
	_check(player.active_style == Player.Style.GREATSWORD, "Later slot 3 supersedes slot 4 before polling")
	player._step_actions(0.0, true, true)
	player._record_style_request(Player.Style.PISTOL, 10)
	player._record_style_request(Player.Style.SWORD, 10)
	player._physics_process(0.01)
	_check(player.pending_style == Player.Style.PISTOL and player.active_style == Player.Style.GREATSWORD, "Highest slot wins a tied sample during commitment")
	await _key_tick(player, KEY_2)
	_check(player.pending_style == Player.Style.SWORD, "Later request replaces pending style")
	await _key_tick(player, KEY_3)
	await _key_tick(player, KEY_3)
	_check(player.pending_style == Player.Style.NONE and not arena.style_label.text.contains("Pending"), "Active slot cancels pending and repeat selection stays clear")
	player._step_actions(0.01, false, true)
	await _key_tick(player, KEY_4)
	# Cross wind-up, active and recovery in one step. Outgoing samples survive.
	player._step_actions(1.2, false, true)
	_check(player.active_style == Player.Style.PISTOL and fsm.state == Action.State.READY and fsm.attack_count == 1, "Recovery yields to Pistol before held repeat inside a long tick")
	_check(fsm.active_intervals.size() == 1 and fsm.active_intervals[0].weapon == Action.GREATSWORD, "Completed interval retains its outgoing weapon")
	player._step_actions(0.01, true, true)
	_check(fsm.active_intervals.is_empty() and fsm.attack_count == 1, "Pistol cannot replay an old interval")
	player._step_actions(0.12, false, false) # Finish the new shot's switching commitment.

	await _key_tick(player, KEY_1)
	player._step_actions(Action.DAGGER.wind_up, true, false)
	fsm.request_hitstop(fsm.active_intervals[0])
	await _key_tick(player, KEY_2)
	_check(fsm.hitstop_remaining > 0.0 and player.pending_style == Player.Style.SWORD, "Hitstop keeps the committed style")
	player._step_actions(fsm.hitstop_remaining + Action.DAGGER.active + 0.12, false, false)
	var to_ready := Action.DAGGER.recovery - fsm._phase_elapsed
	player._step_actions(to_ready, true, false)
	_check(player.active_style == Player.Style.SWORD and fsm.state == Action.State.READY and fsm.attack_count == 2, "Exact tick-end switch wins over live late click")
	_check(arena.style_label.text == "Style: Sword", "Activation immediately clears pending HUD")
	player._step_actions(1.0, false, false)
	_check(fsm.attack_count == 2, "Outgoing click cannot start Sword")
	player._step_actions(0.75, true, true)
	_check(fsm.attack_count == 4, "Fresh sword press repeats within a long tick when no switch is pending")


func _style_dodge(player: Player) -> void:
	arena.reset_encounter(true)
	player._step_actions(0.01, true, true)
	await _key_tick(player, KEY_3)
	player._request_dodge(Vector2.UP, Vector2.RIGHT)
	player._physics_process(0.01)
	_check(player.pending_style == Player.Style.GREATSWORD and player.action_fsm.state == Action.State.READY, "Successful dodge clears swing and preserves selection")
	await _key_tick(player, KEY_4)
	_check(player.pending_style == Player.Style.PISTOL and player.active_style == Player.Style.DAGGER, "Dodge accepts replacement without changing active style")
	_check(player.movement_fsm.is_dodging() and player.velocity.normalized().is_equal_approx(Vector2.UP), "Style request preserves dodge direction and movement")
	player._physics_process(player.movement_fsm.dodge_duration)
	_check(player.active_style == Player.Style.PISTOL and not player.movement_fsm.can_dodge(), "Switch activates on final dodge tick while recovery is running")


func _select(player: Player, key: Key, solo: Enemy = null) -> void:
	var generation := player.encounter_generation
	var expected_style := player.active_style if key == KEY_F5 else Player.Style.DAGGER
	await _key_tick(player, key)
	_check(player.encounter_generation == generation + 1, "Exactly one fresh encounter per reset key")
	var title := "%s only" % solo.name if solo else "Pursuer + Heavy"
	_check(arena.encounter_label.text == "Encounter: " + title and arena.encounter_label.is_visible_in_tree(), "Persistent label for " + title)
	_check(player.position == player.start_position and player.velocity == Vector2.ZERO, "Player spawn and velocity")
	_check(player.player_health.health == player.player_health.max_health and player.player_health.history.is_empty(), "Fresh player HP")
	_check(player.active_style == expected_style and player.pending_style == Player.Style.NONE, "Reset selects the expected style and clears pending")
	if Player.MELEE_WEAPONS.has(expected_style):
		_check(player.action_fsm.weapon == Player.MELEE_WEAPONS[expected_style], "Reset restores the active melee resource")
	_check(player.action_fsm.state == Action.State.READY, "Ready after reset")
	_check(player.action_fsm.hitstop_remaining == 0.0 and player.action_fsm.active_intervals.is_empty(), "No hitstop or attack samples")
	_check(player.pistol.shots_fired == 0 and player.projectiles.bullets.is_empty() and player.projectiles.sparks.is_empty(), "Reset clears pistol and projectiles")
	_check(player.movement_fsm.can_dodge() and not player.is_invulnerable(), "Fresh dodge availability")
	_check(not arena.death_message.visible and not arena.completion.visible and player.facing_marker.visible, "Fresh HUD")
	_check(player.weapon_effects._bursts.is_empty() and player.weapon_effects._angles.is_empty(), "No previous impact or trail")
	var audio := player.combat_audio
	_check(not audio._primary.playing and not audio._secondary.playing and not audio._swing.playing, "No previous voices")
	for enemy in arena.enemies:
		var active := solo == null or solo == enemy
		_check(enemy.visible == active and enemy.is_encounter_active() == active, "%s participation in %s" % [enemy.name, title])
		_check(enemy.health == enemy.max_health and enemy.position == enemy._start_position, "%s HP and spawn" % enemy.name)
		_check(enemy.velocity == Vector2.ZERO and enemy.movement.target_position == enemy.global_position, "Parked movement")
		_check(enemy.collision_layer == (3 if active else 0) and enemy.collision_mask == (1 if active else 0), "Solid and melee layers")
		_check(enemy.movement._avoidance.avoidance_enabled == active, "Avoidance participation")
		_check(enemy.attack.phase == EnemyAttack.Phase.READY and enemy.attack.execution == 0 and not enemy.attack.contacted, "Fresh attack")
		_check(enemy._body.transform.is_equal_approx(Transform2D.IDENTITY) and enemy._body.color == enemy._body_color, "Neutral enemy artwork")


func _complete_with_swings(player: Player, solo: Enemy = null) -> void:
	await physics_frame # Let physics synchronize the reset poses before querying the disks.
	var pursuer := arena.enemies[0]
	var heavy := arena.enemies[1]
	var other := heavy if solo == pursuer else pursuer
	await _key_tick(player, KEY_3)
	# Both disks are in this blade's path. Pursuer falls on the second swing and Heavy on the fourth.
	var last_swing := 2 if solo == pursuer else 4
	for swing in range(1, last_swing + 1):
		_step(player, Action.GREATSWORD.wind_up + Action.GREATSWORD.active + 0.01, true)
		if solo:
			_check(other.health == other.max_health and not player.melee_sweep.contacts.has(other.get_instance_id()), "Inactive disk excluded from sweep")
		if solo != heavy:
			_check((pursuer.health == 0) == (swing >= 2), "Pursuer defeat on second swing")
		if solo != pursuer:
			_check((heavy.health == 0) == (swing == 4), "Heavy defeat on fourth swing")
		_check(arena.completion.visible == (swing == last_swing), "Completion requires every selected enemy")
		_step(player, Action.GREATSWORD.recovery + Action.GREATSWORD.hitstop + 0.1)
	var title := "%s only" % solo.name if solo else "Pursuer + Heavy"
	_check(arena.encounter_label.is_visible_in_tree() and arena.encounter_label.text == "Encounter: " + title, "Label survives completion")


func _pursue_with_inactive_peer(player: Player, active: Enemy, inactive: Enemy) -> void:
	await physics_frame # Resume automatic processing after the manually sampled reset tick.
	# Put the hidden peer directly in the passing lane, within detection and avoidance range.
	active.position = player.position + Vector2(160, 0)
	inactive.position = active.position + Vector2.LEFT * 70.0
	var parked := inactive.position
	_check(active.movement._passing_direction(Vector2.LEFT) == Vector2.LEFT, "Inactive peer contributes no steering bias")
	_check(inactive.receive_hit(Action.DAGGER) == 0, "Inactive body rejects direct damage")
	for enemy in arena.enemies:
		enemy.movement.set_physics_process(true)
	player.set_physics_process(true)
	for tick in range(Engine.physics_ticks_per_second * 4):
		await physics_frame
		if active.attack.phase == EnemyAttack.Phase.WIND_UP:
			break
	player.set_physics_process(false)
	for enemy in arena.enemies:
		enemy.movement.set_physics_process(false)
	_check(active.position.distance_to(player.position) <= active.attack.initiation_radius and active.attack.execution > 0, "Active enemy navigates through peer and starts attack")
	_check(inactive.position == parked and inactive.attack.execution == 0 and not inactive.attack.contacted, "Inactive peer stays parked and produces no strike")
	_check(player.player_health.health == player.player_health.max_health, "No damage before active enemy strikes")


func _encounter_selector(player: Player) -> void:
	var pursuer := arena.enemies[0]
	var heavy := arena.enemies[1]
	_check(pursuer.is_visible_in_tree() and heavy.is_visible_in_tree() and pursuer.is_encounter_active() and heavy.is_encounter_active(), "Both original enemies start active")
	_check(arena.encounter_label.text == "Encounter: Pursuer + Heavy" and arena.encounter_label.is_visible_in_tree(), "Default combined label")
	_toggle_debug()
	_check(arena.state_diagnostics.visible and arena.encounter_label.is_visible_in_tree(), "F3 opens independently")

	var injury := EnemyAttack.Contact.new()
	injury.damage = 15
	player.player_health.resolve(injury)
	_step(player, Action.DAGGER.wind_up + 0.02, true)
	var stale := player.action_fsm.active_intervals[0]
	var old_generation := player.encounter_generation
	_check(player.action_fsm.hitstop_remaining > 0.0 and player.weapon_effects._bursts.size() > 0, "Switch during a damaging Active interval")
	heavy.attack.begin()
	heavy.attack.advance_phase(heavy.attack.wind_up, 0.0, player.global_position)
	heavy.attack.refresh()
	player.position += Vector2.DOWN * 10.0
	pursuer.position += Vector2.UP * 10.0
	# Press F5 and F7 before the same physics tick. _select checks Pursuer only and one full reset.
	_send_key(KEY_F5, true)
	await _select(player, KEY_F7, pursuer)
	_check(Input.is_action_just_pressed("reset_combat_test"), "F5 was sampled on the F7 selection tick")
	_send_key(KEY_F5, false)
	player._apply_contact(pursuer, stale, Vector2.ZERO, Vector2.RIGHT)
	_check(pursuer.health == pursuer.max_health and player.weapon_effects._bursts.is_empty(), "Old swing cannot produce damage or effects")
	arena._update_state_diagnostics()
	_check(arena.state_diagnostics.visible and arena.state_diagnostics.text.contains("Heavy: Inactive"), "F3 identifies the excluded enemy")
	await physics_frame
	player._physics_process(1.0 / Engine.physics_ticks_per_second)
	injury.frame = Engine.get_physics_frames()
	injury.generation = old_generation
	player._collect_contact(player, injury)
	player._resolve_contacts(injury.frame, player.encounter_generation)
	_check(player.player_health.history.is_empty(), "Old enemy contact rejected with a current frame in the new attempt")
	await _complete_with_swings(player, pursuer)
	await _select(player, KEY_F5, pursuer)
	await _pursue_with_inactive_peer(player, pursuer, heavy)
	await _key_tick(player, KEY_3)
	_step(player, Action.GREATSWORD.wind_up * 0.95, true)
	_check(player.action_fsm.state == Action.State.WIND_UP and player.action_fsm.get_aim_state() == Action.AimState.LOCKED, "Switch during committed greatsword wind-up")
	await _select(player, KEY_F10, heavy)
	await _complete_with_swings(player, heavy)
	await _select(player, KEY_F10, heavy)
	await _pursue_with_inactive_peer(player, heavy, pursuer)
	await _select(player, KEY_F9)
	await _complete_with_swings(player)

	await _key_tick(player, KEY_2)
	_check(player.action_fsm.weapon == Action.SWORD, "2 selects sword")
	await _key_tick(player, KEY_1)
	_check(player.action_fsm.weapon == Action.DAGGER, "1 selects dagger")
	var before_move := player.position
	await _key_tick(player, KEY_A)
	_check(player.position.x < before_move.x, "A moves left")
	_primary(true)
	await physics_frame
	player._physics_process(1.0 / Engine.physics_ticks_per_second)
	_check(player.action_fsm.state == Action.State.WIND_UP, "Basic attack starts a swing")
	await _select(player, KEY_F7, pursuer)
	await _key_tick(player, KEY_3)
	_primary(false)
	_check(player.action_fsm.state == Action.State.READY, "Held attack requires a fresh press after selection")
	_step(player, Action.GREATSWORD.wind_up * 0.95, true)
	await _key_tick(player, KEY_SPACE)
	_check(player.action_fsm.state == Action.State.READY and player.movement_fsm.is_dodging(), "Space interrupts late greatsword wind-up")
	await _select(player, KEY_F10, heavy)
	await _key_tick(player, KEY_SPACE)
	player.movement_fsm.step(Vector2.ZERO, player.movement_speed, player.movement_fsm.dodge_duration)
	_check(not player.movement_fsm.is_dodging() and not player.movement_fsm.can_dodge(), "Switch during dodge recovery")
	await _select(player, KEY_F9)
	await _select(player, KEY_F10, heavy)
	injury.damage = player.player_health.max_health
	player.player_health.resolve(injury)
	_check(arena.death_message.visible and arena.encounter_label.is_visible_in_tree() and arena.encounter_label.text == "Encounter: Heavy only", "Label survives death")
	_check(not pursuer.is_encounter_active(), "Player death leaves excluded peer inactive")
	_toggle_debug()
	_check(not arena.state_diagnostics.visible and arena.encounter_label.is_visible_in_tree(), "F3 closes independently during death")
	await _select(player, KEY_F9)


func _moving_miss(player: Player, weapon: Weapon, fade: float) -> void:
	arena.reset_encounter()
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
	arena.reset_encounter()
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
		arena.reset_encounter()
		_step(player, elapsed, true)
		_check((fx._trail_id != 0) == (elapsed >= fsm.weapon.wind_up), "Wind-up cancellation has no onset")
		player._request_dodge(Vector2.UP, Vector2.RIGHT)
		_check(player.movement_fsm.is_dodging() and fsm.state == Action.State.READY, "Dodge interrupts execution")
		_check(fsm.active_intervals.is_empty() and fx._angles.is_empty() and not player.combat_audio._swing.playing, "Dodge invalidates samples, trail and swing")
		player._resolve_swings(player.global_position, 0.016)
		_check(fx._trail_id == 0, "Interrupted samples cannot recreate a trail")

	arena.reset_encounter()
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
	_check(enemy._body.position.x < 0 and absf(enemy._body.position.x) < enemy.recoil_distance * 0.35, "Existing release eases toward Active limit")
	enemy._process(0.010)
	_check(enemy._body.position.x < 0 and absf(enemy._body.position.x) <= enemy.recoil_distance * 0.12, "Release reaches Active bound with a remaining tail")
	enemy._react(Vector2.RIGHT, Action.GREATSWORD)
	enemy._process(0.020)
	_check(is_equal_approx(enemy._body.position.x, enemy.recoil_distance * 0.12), "Active hit has minimal peak")
	attack.phase = EnemyAttack.Phase.RECOVERY
	attack.remaining = attack.recovery
	attack.refresh()
	_check(is_equal_approx(enemy._body.position.x, enemy.recoil_distance * 0.12), "Recovery does not amplify a previous hit")
	enemy._process(enemy.recoil_duration)
	_check(is_zero_approx(enemy._body.position.x) and is_zero_approx(enemy._body.rotation), "Reaction returns to the attack pose")


func _release_into_active(enemy: Enemy, frame_steps: PackedFloat64Array) -> Vector2:
	var attack := enemy.attack
	var target := enemy.global_position + Vector2.UP * 50.0
	attack.face_motion(Vector2.UP)
	attack.begin()
	attack.advance_phase(attack.remaining - 0.030, 0.0, target)
	attack.refresh()
	enemy.receive_hit(Action.GREATSWORD, Vector2.RIGHT)
	# Read the rendered horizontal offset and tilt. Vertical attack poses
	# contribute neither. The first 30 ms take this hit past its wind-up peak.
	enemy._process(0.030)
	var before := Vector2(enemy._body.position.x, enemy._body.rotation)
	attack.advance_phase(attack.remaining, 0.0, target)
	attack.refresh()
	var at_entry := Vector2(enemy._body.position.x, enemy._body.rotation)
	_check(attack.phase == EnemyAttack.Phase.ACTIVE and at_entry.is_equal_approx(before), "Phase entry preserves release offset and tilt")
	var previous := at_entry
	for step in frame_steps:
		enemy._process(step)
		var pose := Vector2(enemy._body.position.x, enemy._body.rotation)
		_check(pose.x > 0.0 and pose.x < previous.x and pose.y > 0.0 and pose.y < previous.y, "Releasing offset and tilt move toward neutral without snapping or reversing")
		previous = pose
	_check(previous.x <= enemy.recoil_distance * 0.12 and previous.y <= deg_to_rad(enemy.recoil_degrees) * 0.12, "Release is inside Active bounds after 33 ms")
	# Both partitions leave 63 ms elapsed since the hit. Check either side
	# of its original endpoint, allowing for rounding of the step durations.
	enemy._process(enemy.recoil_duration - 0.063 - 0.005)
	_check(enemy._body.position.x > 0.0 and enemy._body.position.x < previous.x, "Release persists until its natural end")
	enemy._process(0.005001)
	_check(is_zero_approx(enemy._body.position.x) and is_zero_approx(enemy._body.rotation) and not enemy.is_processing(), "Expired release settles at neutral and stops processing")
	return previous
