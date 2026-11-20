extends SceneTree

## Owner-run fixtures for boundaries that are hard to reproduce by hand.
const Arena = preload("res://scenes/combat/combat_test_arena.tscn")
const Player = preload("res://scenes/combat/combat_test_player.gd")
const Attack = preload("res://scenes/combat/enemy_attack.gd")
const Sector = preload("res://scenes/combat/enemy_attack_sector.gd")
var failures := 0
var deaths := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)


func _run() -> void:
	var square: Array[PackedVector2Array] = [PackedVector2Array([
		Vector2(0, 0), Vector2(10, 0), Vector2(10, 10), Vector2(0, 10),
	])]
	_check(is_equal_approx(Sector.first_touch(square, Vector2(-4, 5), Vector2(4, 5), 2), 0.25), "Edge entry")
	_check(is_equal_approx(Sector.first_touch(square, Vector2(-4, -2), Vector2(4, -2), 2), 0.5), "Vertex tangent")
	_check(Sector.first_touch(square, Vector2(-4, -3), Vector2(4, -3), 2) == INF, "Near miss")
	await _two_strikes(100, 0.65, 0.30, "Heavy", 55)
	await _two_strikes(10, 0.30, 0.65, "Pursuer", 0)
	await _two_strikes(10, 0.45, 0.45, "Heavy", 0)
	await _expiry_and_reset()
	print("Player contact acceptance: %d failures" % failures)
	quit(1 if failures else 0)


## Drive both real avoidance agents. Fractional wind-ups put distinct first
## contacts within a single tick regardless of the project's physics rate.
func _two_strikes(hp: int, pursuer_delay: float, heavy_delay: float, first: String, expected_hp: int) -> void:
	var arena := Arena.instantiate()
	var player: Player = arena.get_node("ArenaObjects/Player")
	player.position = Vector2(-180, 144)
	player.get_node("Health").set("max_health", hp)
	var step := 1.0 / Engine.physics_ticks_per_second
	for enemy_name: String in ["Heavy", "Pursuer"]:
		var enemy: CharacterBody2D = arena.get_node("ArenaObjects/" + enemy_name)
		var heavy: bool = enemy_name == "Heavy"
		enemy.position = player.position - Vector2(95 if heavy else 48, 0)
		var attack: Attack = enemy.get_node("Attack")
		attack.engagement_delay = 0.0
		attack.wind_up = step * (heavy_delay if heavy else pursuer_delay)
	root.add_child(arena)
	deaths = 0
	player.player_health.died.connect(func() -> void: deaths += 1)
	# Allow agent registration to synchronize before enabling both producers.
	for enemy in player.enemies:
		enemy.movement.set_physics_process(false)
	for i in 3:
		await physics_frame
	for enemy in player.enemies:
		enemy.movement.set_physics_process(true)
	for i in 12:
		await physics_frame
		if player.player_health.history.size() >= 2:
			break
	var history := player.player_health.history
	_check(history.size() == 2, "Both avoidance callbacks must contribute once")
	if history.size() == 2:
		_check(history[0].contains(first + " #1"), "Incorrect first enemy: " + history[0])
		_check(history[0].get_slice("  ", 0) == history[1].get_slice("  ", 0), "Contacts occurred on different ticks")
		_check(history[0].contains("LETHAL") == (expected_hp == 0), "Incorrect lethal attribution")
		_check(history[1].contains("IGNORED (DEAD)") == (expected_hp == 0), "Incorrect later outcome")
		if expected_hp == 0:
			_check(history[0].contains("−10") and history[1].contains("−0"), "Incorrect clamped loss")
	_check(player.player_health.health == expected_hp, "Unexpected combined HP")
	_check(deaths == (1 if expected_hp == 0 else 0), "Incorrect number of death transitions")
	arena.queue_free()
	await process_frame


func _expiry_and_reset() -> void:
	var arena := Arena.instantiate()
	root.add_child(arena)
	var player: Player = arena.get_node("ArenaObjects/Player")
	player.set_physics_process(false)
	await physics_frame
	var movement := player.movement_fsm
	# Use the real FSM's clock to put expiry in the middle of the tested step.
	movement.request_dodge(Vector2.RIGHT, Vector2.RIGHT)
	movement.step(Vector2.ZERO, 0.0, 0.09)
	_check(movement.was_invulnerable_at(Engine.get_physics_frames(), 0.0), "Dodge initiation must protect")
	_check(movement.was_invulnerable_at(Engine.get_physics_frames(), 0.09), "Protection continues across tick end")
	await physics_frame
	var frame := Engine.get_physics_frames()
	player._physics_process(0.016)
	var expiry := movement.dodge_duration * movement.dodge_invulnerability_fraction - 0.09
	_check(not player.is_invulnerable(), "End-of-tick i-frame should have expired")
	var execution_id := 1
	for offset: float in [expiry - 0.000001, expiry, expiry + 0.000001]:
		var contact := _contact(frame, player.encounter_generation, offset)
		contact.execution_id = execution_id
		execution_id += 1
		player._collect_contact(player, contact)
	player._resolve_contacts(frame, player.encounter_generation)
	_check(player.player_health.health == 70, "Only the pre-expiry contact should block")
	var history := player.player_health.history
	_check(history.size() == 3, "Expected three boundary decisions")
	if history.size() == 3:
		_check(history[0].contains("BLOCKED (DODGE)"), "Pre-expiry decision")
		_check(history[1].contains("APPLIED") and history[2].contains("APPLIED"), "Expiry and post-expiry decisions")
	var uncertain := _contact(frame, player.encounter_generation, expiry + 0.000001)
	uncertain.execution_id = execution_id
	uncertain.earliest_possible = expiry - 0.000001
	player._collect_contact(player, uncertain)
	player._resolve_contacts(frame, player.encounter_generation)
	_check(player.player_health.health == 70, "Ambiguous shadow-edge expiry should protect")
	var stale := _contact(frame, player.encounter_generation, 0.015)
	player._collect_contact(player, stale)
	player._reset_encounter()
	_check(not movement.was_invulnerable_at(frame, 0.0), "Reset must invalidate dodge history")
	# Open a replacement batch with the same frame and a different generation.
	player._physics_process(0.016)
	player._collect_contact(player, stale)
	player._collect_contact(player, _contact(frame, player.encounter_generation, 0.015))
	player._resolve_contacts(frame, stale.generation)
	_check(player.player_health.health == 100, "Stale drain affected the replacement batch")
	await physics_frame
	_check(player.player_health.health == 85 and player.player_health.history.size() == 1, "Fresh batch must resolve exactly once")
	arena.queue_free()
	await process_frame


func _contact(frame: int, generation: int, offset: float) -> Attack.Contact:
	var contact := Attack.Contact.new()
	contact.enemy = &"Pursuer"
	contact.execution_id = 1
	contact.frame = frame
	contact.generation = generation
	contact.earliest_possible = offset
	contact.time = offset
	contact.damage = 15
	return contact
