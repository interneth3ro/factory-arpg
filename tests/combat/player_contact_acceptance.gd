extends SceneTree

## Owner-run fixtures for boundaries that are hard to reproduce by hand.
const Arena = preload("res://scenes/combat/combat_test_arena.tscn")
const Player = preload("res://scenes/combat/combat_test_player.gd")
const Attack = preload("res://scenes/combat/enemy_attack.gd")
const Sector = preload("res://scenes/combat/enemy_attack_sector.gd")
const SlideTrace = preload("res://scenes/combat/slide_trace.gd")
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
	if expected_hp > 0 and history.size() == 2:
		_check(history[0].get_slice("  ", 1) != history[1].get_slice("  ", 1), "Expected distinct contact offsets")
		var heavy: Attack = arena.get_node("ArenaObjects/Heavy/Attack")
		_check_feedback(player, heavy)
		# physics_frame resumed at the start of the following tick.
		var pursuer: Attack = arena.get_node("ArenaObjects/Pursuer/Attack")
		var next := _contact(Engine.get_physics_frames(), player.encounter_generation, 0.0)
		next.flash_strength = pursuer.flash_strength
		next.flash_seconds = pursuer.flash_seconds
		next.emphasis_seconds = pursuer.emphasis_seconds
		player.player_health.resolve(next)
		_check_feedback(player, pursuer)
	arena.queue_free()
	await process_frame


func _check_feedback(player: Player, attack: Attack) -> void:
	_check(player._flash_strength == attack.flash_strength, "Expected %s flash strength" % attack.get_parent().name)
	_check(player._flash_left == attack.flash_seconds, "Expected a single flash duration")
	_check(player._emphasis_left == attack.emphasis_seconds, "Expected a single emphasis duration")


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
	_check_shadow_contacts(player, frame, expiry)
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


func _check_shadow_contacts(player: Player, frame: int, expiry: float) -> void:
	var attack: Attack = player.get_node("../Pursuer/Attack")
	var collider: CollisionShape2D = player.get_node("CollisionShape2D")
	var original := collider.shape
	var disk := CircleShape2D.new()
	disk.radius = 0.1
	collider.shape = disk
	attack._sector._solids.assign([PackedVector2Array([
		Vector2(10, -3), Vector2(12, -3), Vector2(12, 0), Vector2(10, 0),
	])])
	attack.committed = Vector2.RIGHT
	# Behind the block at t=0. Horizontal attacker travel keeps the upper
	# shadow edge at y=0; the disk rising from -2 first touches at y=-0.1.
	var enemy := SlideTrace.new()
	var target := SlideTrace.new()
	enemy.positions = PackedVector2Array([Vector2.ZERO, Vector2(0.5, 0)])
	target.positions = PackedVector2Array([Vector2(40, -2), Vector2(40, 0.5)])
	enemy.times = PackedFloat64Array([0.0, 0.016])
	target.times = enemy.times
	attack.check_contact(enemy, target, frame, player.encounter_generation)
	if player._pending.size() == 1:
		var exact := player._pending[0]
		_check(is_equal_approx(exact.time, 0.016 * 1.9 / 2.5), "Incorrect clipped contact time")
		_check(exact.shadow_miss_time < 0.0, "Clipped entry should have a single verified time")
	player._resolve_contacts(frame, player.encounter_generation)
	_check(player.player_health.health == 55, "Verified clipped entry after expiry must deal damage")

	# Vertical attacker travel opens the shadow onto a stationary disk.
	# At x=40 the ray over (10, 0) first grazes it near fraction 0.3667.
	# Eight halvings put the miss/touch bracket at [93/256, 94/256].
	enemy.positions = PackedVector2Array([Vector2(0, -0.25), Vector2(0, 0.25)])
	target.positions = PackedVector2Array([Vector2(40, 0.1), Vector2(40, 0.1)])
	var duration := 0.008
	for expiry_fraction: float in [0.365, 0.30]:
		var start := expiry - duration * expiry_fraction
		enemy.times = PackedFloat64Array([start, start + duration])
		target.times = enemy.times
		attack.contacted = false
		attack.execution += 1
		attack.check_contact(enemy, target, frame, player.encounter_generation)
		_check(player._pending.size() == 1, "Expected one collected moving-shadow touch")
		if player._pending.size() == 1:
			var sampled := player._pending[0]
			_check(sampled.time > expiry, "Expected a verified vulnerable-side touch")
			_check(sampled.shadow_miss_time >= start and sampled.shadow_miss_time < sampled.time, "Expected a clipped miss/touch bracket")
			_check(sampled.time - sampled.shadow_miss_time <= duration / 256.0 + 1e-12, "Shadow bracket too wide")
		player._resolve_contacts(frame, player.encounter_generation)
		if expiry_fraction == 0.365:
			_check(player.player_health.health == 55, "A shadow interval spanning expiry should protect")
		else:
			_check(player.player_health.health == 40, "A shadow interval entirely after expiry must deal damage")
	collider.shape = original


func _contact(frame: int, generation: int, offset: float) -> Attack.Contact:
	var contact := Attack.Contact.new()
	contact.enemy = &"Pursuer"
	contact.execution_id = 1
	contact.frame = frame
	contact.generation = generation
	contact.time = offset
	contact.damage = 15
	return contact
