extends CharacterBody2D

signal physics_tick_started
signal style_changed

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
const PistolFiring = preload("res://scenes/combat/pistol_firing.gd")
const PistolProjectiles = preload("res://scenes/combat/pistol_projectiles.gd")
const DAMAGE_RED := Color(1.0, 0.09, 0.11)
enum Style { NONE, DAGGER, SWORD, GREATSWORD, PISTOL }
const SLOT_ACTIONS := {
	&"weapon_1": Style.DAGGER, &"weapon_2": Style.SWORD,
	&"weapon_3": Style.GREATSWORD, &"weapon_4": Style.PISTOL,
}
const MELEE_WEAPONS := {
	Style.DAGGER: ActionFSM.DAGGER, Style.SWORD: ActionFSM.SWORD, Style.GREATSWORD: ActionFSM.GREATSWORD,
}
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
@onready var melee_sweep: MeleeSweep = $MeleeSweep
@onready var weapon_effects: WeaponEffects = $WeaponEffects
@onready var combat_audio: CombatAudio = $CombatAudio
@onready var projectiles: PistolProjectiles = $PistolProjectiles
@onready var start_position := position
var last_damage := "None"
var motion_trace := SlideTrace.new()
var pistol := PistolFiring.new()
var encounter_generation := 0
var active_style := Style.DAGGER
var pending_style := Style.NONE
var aim_direction := Vector2.RIGHT
var _requested_style := Style.NONE
var _request_time_usec := -1
var _targets: Array[EnemyHealth] = []
var _attack_pressed := false
var _attack_held := false
var _dodge_pressed := false
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
	player_health.damaged.connect(_show_damage)
	player_health.died.connect(_on_death)
	_update_presentation()


func configure_combat(targets: Array[EnemyHealth], solids: Array[PackedVector2Array]) -> void:
	_targets = targets
	projectiles.configure(targets, solids, _apply_pistol_contact)


# GUI clicks and releases retire any prior world hold. Only a world press claims the new one.
func _input(event: InputEvent) -> void:
	if event.is_action("basic_attack"):
		_attack_held = false


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo() or player_health.health == 0:
		return
	if event.is_action_pressed("basic_attack"):
		_attack_pressed = true
		_attack_held = true
	if event.is_action_pressed("dodge"):
		_dodge_pressed = true
	# Physics edge flags alone lose the order of distinct presses between ticks.
	var sample_time := Time.get_ticks_usec()
	for action: StringName in SLOT_ACTIONS:
		if event.is_action_pressed(action):
			_record_style_request(SLOT_ACTIONS[action], sample_time)


func _record_style_request(slot: Style, sample_time: int) -> void:
	if sample_time > _request_time_usec or (sample_time == _request_time_usec and slot > _requested_style):
		_requested_style = slot
		_request_time_usec = sample_time


static func style_name(style: Style) -> String:
	return String(Style.keys()[style]).capitalize()


func _clear_combat_input() -> void:
	_attack_pressed = false
	_attack_held = false
	_dodge_pressed = false
	_requested_style = Style.NONE
	_request_time_usec = -1
	pending_style = Style.NONE
	style_changed.emit()


func _activate_pending_style() -> bool:
	if pending_style == Style.NONE:
		return false
	if active_style == Style.PISTOL:
		pistol.interrupt()
	active_style = pending_style
	pending_style = Style.NONE
	if MELEE_WEAPONS.has(active_style):
		action_fsm.select_weapon(MELEE_WEAPONS[active_style])
	style_changed.emit()
	return true


func _physics_process(delta: float) -> void:
	var generation := encounter_generation
	physics_tick_started.emit()
	# A context reset consumes this tick before movement or combat.
	if generation != encounter_generation:
		return
	if player_health.health == 0:
		return
	_pending.clear()
	_contact_frame = Engine.get_physics_frames()
	_flash_left = maxf(0.0, _flash_left - delta)
	_emphasis_left = maxf(0.0, _emphasis_left - delta)
	var movement_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var cursor := get_global_mouse_position()
	_update_facing()
	if _dodge_pressed:
		_dodge_pressed = false
		_request_dodge(movement_input, aim_direction)
	if _requested_style != Style.NONE:
		pending_style = Style.NONE if _requested_style == active_style else _requested_style
		_requested_style = Style.NONE
		_request_time_usec = -1
		style_changed.emit()
	# Attack presses on the final dodge tick still belong to the dodge.
	var movement_multiplier := 1.0
	var attacking_allowed := not movement_fsm.is_dodging()
	if attacking_allowed:
		movement_multiplier = _step_actions(delta,
			_attack_pressed, _attack_held and Input.is_action_pressed("basic_attack"))
	else:
		pistol.idle(delta)
	_attack_pressed = false
	var start := global_position
	movement_fsm.step(movement_input, movement_speed, delta, movement_multiplier)
	if not attacking_allowed and not movement_fsm.is_dodging():
		_activate_pending_style()
	motion_trace.record(self, start, 0.0, delta, delta)
	motion_trace.retime(pistol.times, pistol.movement_times)
	_step_projectiles(delta, cursor)
	melee_sweep.begin_tick()
	if attacking_allowed:
		_resolve_swings(start, delta)
	melee_sweep.select_attack(action_fsm.attack_count)
	_update_presentation()


func _step_projectiles(delta: float, cursor: Vector2) -> void:
	var advanced := 0.0
	for offset in pistol.shots:
		projectiles.advance(offset - advanced)
		var origin := motion_trace.at(offset)
		var direction := cursor - origin
		if direction.length_squared() > AIM_DEAD_ZONE_RADIUS * AIM_DEAD_ZONE_RADIUS:
			_sample_aim_direction(direction)
		projectiles.launch(origin, aim_direction, encounter_generation)
		advanced = offset
	projectiles.advance(delta - advanced)


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
	if _flash_left > 0.0:
		color = color.lerp(DAMAGE_RED, _damage_strength())
	body_marker.color = color
	attack_marker.visible = action_fsm.state != ActionFSM.State.READY
	if attack_marker.visible:
		attack_marker.global_rotation = action_fsm.attack_direction.angle()


func _damage_strength() -> float:
	return minf(1.0, _flash_strength + 0.18) if _emphasis_left > 0.0 else _flash_strength


func damage_emphasis() -> float:
	if _flash_left <= 0.0:
		return 0.0
	return _damage_strength() * (0.85 if _emphasis_left > 0.0 else 0.35)


func _step_actions(delta: float, pressed: bool, held: bool) -> float:
	var switched := action_fsm.state == ActionFSM.State.READY and pistol.commitment == 0.0 and _activate_pending_style()
	if active_style == Style.PISTOL:
		action_fsm.step(delta, false, false, aim_direction)
		return pistol.step(delta, pressed and not switched, held, _activate_pending_style)
	pistol.idle(delta)
	# Ready starts only on a press edge after the activation tick.
	var melee_input := MELEE_WEAPONS.has(active_style) and not switched
	var on_ready := Callable()
	if pending_style != Style.NONE:
		on_ready = _activate_pending_style
	return action_fsm.step(delta, pressed and melee_input, held and melee_input, aim_direction, on_ready)


func _process(_delta: float) -> void:
	if player_health.health > 0:
		_update_facing()


func is_invulnerable() -> bool:
	return movement_fsm.is_invulnerable()


func _update_facing() -> void:
	var aim_offset := get_global_mouse_position() - global_position
	if aim_offset.length_squared() > AIM_DEAD_ZONE_RADIUS * AIM_DEAD_ZONE_RADIUS:
		_sample_aim_direction(aim_offset)
	facing_marker.global_rotation = aim_direction.angle()


func _sample_aim_direction(direction: Vector2) -> void:
	if direction.is_finite():
		var heading := direction.normalized()
		if heading.is_normalized():
			aim_direction = heading


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
		pistol.interrupt()
		_interrupt_swing()


func _interrupt_swing() -> void:
	_resolving_interval = null
	action_fsm.interrupt_attack()
	action_fsm.active_intervals.clear()
	weapon_effects.clear_trail()
	combat_audio.interrupt_swing()


func _on_death() -> void:
	projectiles.clear(encounter_generation, false)
	pistol.reset()
	_interrupt_swing()
	_clear_combat_input()
	combat_audio.reset()
	movement_fsm.reset_encounter()
	melee_sweep.begin_tick()
	_flash_left = 0.0
	_emphasis_left = 0.0
	body_marker.color = PHASE_COLORS[ActionFSM.State.READY]
	attack_marker.hide()
	facing_marker.hide()
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
	if enemy == null or not _targets.has(enemy):
		return
	var applied := enemy.receive_hit(interval.weapon, direction)
	if applied > 0:
		last_damage = "%d to %s from %s (#%d)" % [applied, enemy.name, interval.weapon.display_name, interval.attack_id]
		action_fsm.request_hitstop(interval)
		weapon_effects.burst(point, direction, interval.weapon)
		combat_audio.impact(interval.attack_id, interval.weapon)


func _apply_pistol_contact(enemy: EnemyHealth, shot: int, generation: int) -> bool:
	if generation != encounter_generation or player_health.health == 0:
		return false
	var applied := enemy.receive_pistol_hit()
	if applied == 0:
		return false
	last_damage = "%d to %s from Pistol (#%d)" % [applied, enemy.name, shot]
	return true


func reset_combat(generation: int, start_with_dagger: bool) -> void:
	encounter_generation = generation
	projectiles.clear(encounter_generation, true)
	pistol.reset()
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
	_flash_left = 0.0
	_emphasis_left = 0.0
	_feedback_frame = -1
	player_health.reset_encounter()
	position = start_position
	motion_trace.record(self, global_position, 0.0, 0.0, 0.0)
	aim_direction = Vector2.RIGHT
	_update_facing()
	action_fsm.reset_encounter()
	if start_with_dagger:
		active_style = Style.DAGGER
	elif MELEE_WEAPONS.has(active_style):
		action_fsm.select_weapon(MELEE_WEAPONS[active_style])
	_clear_combat_input()
	movement_fsm.reset_encounter()
	melee_sweep.select_attack(0)
	melee_sweep.begin_tick()
	last_damage = "None"
	_update_presentation()
