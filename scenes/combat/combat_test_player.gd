extends CharacterBody2D

const AIM_DEAD_ZONE_RADIUS: float = 4.0
const MovementFSM = preload("res://scenes/combat/player_movement_fsm.gd")
const ActionFSM = preload("res://scenes/combat/player_action_fsm.gd")
const MeleeSweep = preload("res://scenes/combat/melee_sweep.gd")
const WeaponEffects = preload("res://scenes/combat/weapon_effects.gd")
const CombatAudio = preload("res://scenes/combat/combat_audio.gd")
const SlideTrace = preload("res://scenes/combat/slide_trace.gd")
const EnemyHealth = preload("res://scenes/combat/enemy_health.gd")
const EnemyAttack = preload("res://scenes/combat/enemy_attack.gd")
const PlayerHealth = preload("res://scenes/combat/player_health.gd")
const HUD_RED := Color(0.84, 0.20, 0.25)
const DAMAGE_RED := Color(1.0, 0.09, 0.11)
const PHASE_COLORS := {
	ActionFSM.State.READY: Color(0.3, 0.82, 0.95),
	ActionFSM.State.WIND_UP: Color(1.0, 0.72, 0.16),
	ActionFSM.State.ACTIVE: Color.WHITE,
	ActionFSM.State.RECOVERY: Color(0.66, 0.43, 0.85),
}

@export var movement_speed: float = 220.0

@onready var facing_marker: Node2D = $FacingMarker
@onready var attack_marker: Node2D = $AttackMarker
@onready var body_marker: Polygon2D = $Body
@onready var movement_fsm: MovementFSM = $MovementFSM
@onready var action_fsm: ActionFSM = $ActionFSM
@onready var player_health: PlayerHealth = $Health
@onready var health_bar: ProgressBar = $Diagnostics/HealthBar
@onready var health_label: Label = $Diagnostics/HealthBar/Value
@onready var death_message: Label = $Diagnostics/Death
@onready var damage_diagnostics: Label = $Diagnostics/DamageLabel
@onready var state_diagnostics: Label = $Diagnostics/StateLabel
@onready var melee_sweep: MeleeSweep = $MeleeSweep
@onready var weapon_effects: WeaponEffects = $WeaponEffects
@onready var combat_audio: CombatAudio = $CombatAudio
@onready var enemies: Array[EnemyHealth] = [$"../Pursuer", $"../Heavy"]
@onready var completion: Label = $Diagnostics/Completion
@onready var start_position := position
var last_damage := "None"
var motion_trace := SlideTrace.new()
var encounter_generation := 0
var _pending: Array[EnemyAttack.Contact] = []
var _contact_frame := -1
var _feedback_frame := -1
var _flash_strength := 0.0
var _flash_left := 0.0
var _emphasis_left := 0.0
var _collapse: Tween
var _resolving_interval: ActionFSM.ActiveInterval


func _ready() -> void:
	melee_sweep.contacted.connect(_apply_contact)
	player_health.health_changed.connect(_update_health_hud)
	player_health.damaged.connect(_show_damage)
	player_health.died.connect(_on_death)
	_update_health_hud()
	_update_presentation()


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("reset_combat_test"):
		_reset_encounter()
		return
	if player_health.health == 0:
		return
	_pending.clear()
	_contact_frame = Engine.get_physics_frames()
	_flash_left = maxf(0.0, _flash_left - delta)
	_emphasis_left = maxf(0.0, _emphasis_left - delta)
	var movement_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_update_facing()
	var facing_direction := Vector2.RIGHT.rotated(facing_marker.global_rotation)
	if Input.is_action_just_pressed("dodge"):
		_request_dodge(movement_input, facing_direction)
	# Sample before advancing movement so the final dodge tick still discards input.
	var movement_multiplier := 1.0
	var attacking_allowed := not movement_fsm.is_dodging()
	if attacking_allowed:
		movement_multiplier = _step_actions(delta, facing_direction)
	var start := global_position
	movement_fsm.step(movement_input, movement_speed, delta, movement_multiplier)
	motion_trace.record(self, start, 0.0, delta, delta)
	melee_sweep.begin_tick()
	if attacking_allowed:
		_resolve_swings(start, delta)
	melee_sweep.select_attack(action_fsm.attack_count)
	_update_presentation()


func _resolve_swings(start: Vector2, delta: float) -> void:
	# Only Active samples advance the blade. Once the last Active slice ends,
	# its cosmetic fade uses elapsed physics time, including recovery hitstop.
	var fade_from := 0.0
	for interval in action_fsm.active_intervals:
		combat_audio.swing(interval.attack_id, interval.weapon)
		weapon_effects.follow(interval)
		fade_from = interval.tick_start + interval.duration
		if interval.duration > 0.0:
			_resolving_interval = interval
			melee_sweep.check_motion_interval(self, start, delta, interval)
			_resolving_interval = null
	weapon_effects.decay_trail(maxf(0.0, delta - fade_from))


func _update_presentation() -> void:
	var color: Color = PHASE_COLORS[action_fsm.state]
	if movement_fsm.is_dodging():
		color = Color(0.55, 0.96, 1.0)
	health_bar.self_modulate = HUD_RED
	if _flash_left > 0.0:
		var strength := _flash_strength
		if _emphasis_left > 0.0:
			strength = minf(1.0, strength + 0.18)
		color = color.lerp(DAMAGE_RED, strength)
		health_bar.self_modulate = HUD_RED.lerp(Color.WHITE, strength * (0.85 if _emphasis_left > 0.0 else 0.35))
	body_marker.color = color
	attack_marker.visible = action_fsm.state != ActionFSM.State.READY
	if attack_marker.visible:
		attack_marker.global_rotation = action_fsm.attack_direction.angle()


func _step_actions(delta: float, aim: Vector2) -> float:
	if Input.is_action_just_pressed("weapon_1"):
		action_fsm.select_weapon(ActionFSM.DAGGER)
	elif Input.is_action_just_pressed("weapon_2"):
		action_fsm.select_weapon(ActionFSM.SWORD)
	elif Input.is_action_just_pressed("weapon_3"):
		action_fsm.select_weapon(ActionFSM.GREATSWORD)
	return action_fsm.step(delta, Input.is_action_just_pressed("basic_attack"), Input.is_action_pressed("basic_attack"), aim)


func _process(_delta: float) -> void:
	if player_health.health > 0:
		_update_facing()
	_update_state_diagnostics()


func is_invulnerable() -> bool:
	return movement_fsm.is_invulnerable()


func _update_facing() -> void:
	var aim_offset := get_global_mouse_position() - global_position
	if aim_offset.length_squared() > AIM_DEAD_ZONE_RADIUS * AIM_DEAD_ZONE_RADIUS:
		facing_marker.global_rotation = aim_offset.angle()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_combat_debug"):
		state_diagnostics.visible = not state_diagnostics.visible
		damage_diagnostics.visible = state_diagnostics.visible
		melee_sweep.visible = state_diagnostics.visible
		for enemy in enemies:
			enemy.attack.debug_visible = state_diagnostics.visible
			enemy.attack.queue_redraw()
		_update_state_diagnostics()


func _update_state_diagnostics() -> void:
	if state_diagnostics.visible:
		var dodge_status := "Available" if movement_fsm.can_dodge() else "Recovering"
		if player_health.health == 0:
			dodge_status = "Disabled"
		elif movement_fsm.is_dodging():
			dodge_status = "In progress"
		state_diagnostics.text = "Movement: %s\nAction / phase: %s\nWeapon: %s\nAttack count: %d\nAttack aim: %s\nOrdinary speed: %.2fx\nDodge: %s\nInvulnerability: %s" % [
			movement_fsm.get_state_name(),
			action_fsm.get_state_name(),
			action_fsm.weapon.display_name,
			action_fsm.attack_count,
			String(ActionFSM.AimState.keys()[action_fsm.get_aim_state()]).capitalize(),
			action_fsm.get_movement_multiplier(),
			dodge_status,
			"Active" if is_invulnerable() else "Inactive",
		]
		state_diagnostics.text += "\nContacts (%d): %s\nSweep overlay: On" % [
			melee_sweep.contacts.size(), ", ".join(melee_sweep.contacts.values()) if not melee_sweep.contacts.is_empty() else "None",
		]

		for enemy in enemies:
			state_diagnostics.text += "\n%s: %d/%d HP (%s)" % [
				enemy.name, enemy.health, enemy.max_health, "Alive" if enemy.health > 0 else "Defeated",
			]
			state_diagnostics.text += "\n    " + enemy.movement.diagnostics()
			state_diagnostics.text += "\n    " + enemy.attack.diagnostics()
		state_diagnostics.text += "\nLast damage: %s\nHitstop: %.0f ms remaining" % [
			last_damage, action_fsm.hitstop_remaining * 1000.0,
		]
		if action_fsm.last_hitstop_attack > 0:
			state_diagnostics.text += " (last %.0f ms on #%d)" % [
				action_fsm.last_hitstop_duration * 1000.0, action_fsm.last_hitstop_attack,
			]
		damage_diagnostics.text = "Player %d / %d HP  |  %s  |  I-frames %s\nEnemy contacts (oldest first)\n%s" % [
			player_health.health, player_health.max_health, "DEAD" if player_health.health == 0 else "ALIVE",
			"on" if is_invulnerable() else "off",
			"None" if player_health.history.is_empty() else "\n".join(player_health.history),
		]


func _collect_contact(target: CharacterBody2D, contact: EnemyAttack.Contact) -> void:
	if target != self or contact.generation != encounter_generation or contact.frame != _contact_frame:
		return
	if player_health.health == 0:
		return
	if _pending.is_empty():
		# Only called inside synchronous navigation avoidance dispatch. Godot
		# flushes deferred calls after all agents return, within this tick.
		_resolve_contacts.call_deferred(contact.frame, contact.generation)
	_pending.append(contact)


func _resolve_contacts(frame: int, generation: int) -> void:
	if generation != encounter_generation or frame != _contact_frame or frame != Engine.get_physics_frames():
		return
	_pending.sort_custom(func(a: EnemyAttack.Contact, b: EnemyAttack.Contact) -> bool: return a.precedes(b))
	for contact in _pending:
		player_health.resolve(contact)
	_pending.clear()


func _update_health_hud() -> void:
	health_bar.max_value = player_health.max_health
	health_bar.value = player_health.health
	health_label.text = "%d / %d" % [player_health.health, player_health.max_health]


func _show_damage(contact: EnemyAttack.Contact) -> void:
	if contact.frame == _feedback_frame and contact.flash_strength < _flash_strength:
		return
	_feedback_frame = contact.frame
	_flash_strength = contact.flash_strength
	_flash_left = contact.flash_seconds
	_emphasis_left = contact.emphasis_seconds
	_update_presentation()


func _request_dodge(movement_input: Vector2, facing: Vector2) -> void:
	if movement_fsm.request_dodge(movement_input, facing):
		_interrupt_swing()


func _interrupt_swing() -> void:
	_resolving_interval = null
	action_fsm.interrupt_attack()
	action_fsm.active_intervals.clear()
	weapon_effects.clear_trail()
	combat_audio.interrupt_swing()


func _on_death() -> void:
	_interrupt_swing()
	combat_audio.reset()
	movement_fsm.reset_encounter()
	melee_sweep.begin_tick()
	_flash_left = 0.0
	_emphasis_left = 0.0
	health_bar.self_modulate = HUD_RED
	body_marker.color = PHASE_COLORS[ActionFSM.State.READY]
	attack_marker.hide()
	facing_marker.hide()
	death_message.show()
	for enemy in enemies:
		enemy.rest_after_player_death()
	_collapse = create_tween().set_parallel(true)
	_collapse.tween_property(body_marker, "rotation", -0.42, 0.35)
	_collapse.tween_property(body_marker, "scale", Vector2(1.12, 0.50), 0.35)
	_collapse.tween_property(body_marker, "position", Vector2(0, 7), 0.35)
	_collapse.tween_property(body_marker, "color", Color(0.27, 0.32, 0.34), 0.35)


func _apply_contact(target: CollisionObject2D, interval: ActionFSM.ActiveInterval, point: Vector2, direction: Vector2) -> void:
	# Only the direct signal inside this exact interval may apply a hit.
	# IDs restart at F5, but interval objects are never reused.
	if interval == null or interval != _resolving_interval or player_health.health == 0:
		return
	var enemy := target as EnemyHealth
	if enemy == null:
		return
	var applied := enemy.receive_hit(interval.weapon, direction)
	if applied > 0:
		last_damage = "%d to %s from %s (#%d)" % [applied, enemy.name, interval.weapon.display_name, interval.attack_id]
		action_fsm.request_hitstop(interval)
		weapon_effects.burst(point, direction, interval.weapon)
		combat_audio.impact(interval.attack_id, interval.weapon)
		if enemy.health == 0:
			completion.visible = enemies.all(func(candidate: EnemyHealth) -> bool: return candidate.health == 0)


func _reset_encounter() -> void:
	encounter_generation += 1
	_resolving_interval = null
	weapon_effects.reset()
	combat_audio.reset()
	_contact_frame = -1
	_pending.clear()
	if _collapse:
		_collapse.kill()
		_collapse = null
	body_marker.transform = Transform2D.IDENTITY
	facing_marker.show()
	death_message.hide()
	_flash_left = 0.0
	_emphasis_left = 0.0
	_feedback_frame = -1
	player_health.reset_encounter()
	for enemy in enemies:
		enemy.reset_encounter(encounter_generation)
	position = start_position
	motion_trace.record(self, global_position, 0.0, 0.0, 0.0)
	facing_marker.rotation = 0.0
	_update_facing()
	action_fsm.reset_encounter()
	movement_fsm.reset_encounter()
	melee_sweep.select_attack(0)
	melee_sweep.begin_tick()
	last_damage = "None"
	completion.hide()
	_update_presentation()
