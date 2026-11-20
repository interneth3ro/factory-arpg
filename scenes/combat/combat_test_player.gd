extends CharacterBody2D

const AIM_DEAD_ZONE_RADIUS: float = 4.0
const MovementFSM = preload("res://scenes/combat/player_movement_fsm.gd")
const ActionFSM = preload("res://scenes/combat/player_action_fsm.gd")
const MeleeSweep = preload("res://scenes/combat/melee_sweep.gd")
const EnemyHealth = preload("res://scenes/combat/enemy_health.gd")
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
@onready var state_diagnostics: Label = $Diagnostics/StateLabel
@onready var melee_sweep: MeleeSweep = $MeleeSweep
@onready var enemies: Array[EnemyHealth] = [$"../Pursuer", $"../Heavy"]
@onready var completion: Label = $Diagnostics/Completion
@onready var start_position := position
var last_damage := "None"


func _ready() -> void:
	melee_sweep.contacted.connect(_apply_contact)


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("reset_combat_test"):
		_reset_encounter()
		return
	var movement_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_update_facing()
	var facing_direction := Vector2.RIGHT.rotated(facing_marker.global_rotation)
	if Input.is_action_just_pressed("dodge"):
		if movement_fsm.request_dodge(movement_input, facing_direction):
			action_fsm.interrupt_attack()
	# Sample before advancing movement so the final dodge tick still discards input.
	var movement_multiplier := 1.0
	var attacking_allowed := not movement_fsm.is_dodging()
	if attacking_allowed:
		movement_multiplier = _step_actions(delta, facing_direction)
	var start := global_position
	movement_fsm.step(movement_input, movement_speed, delta, movement_multiplier)
	melee_sweep.begin_tick()
	if attacking_allowed and not action_fsm.active_intervals.is_empty():
		melee_sweep.check_motion(self, start, delta, action_fsm.active_intervals)
	melee_sweep.select_attack(action_fsm.attack_count)
	_update_presentation()


func _update_presentation() -> void:
	body_marker.color = PHASE_COLORS[action_fsm.state]
	attack_marker.visible = action_fsm.state != ActionFSM.State.READY
	if attack_marker.visible:
		attack_marker.global_rotation = action_fsm.attack_direction.angle()
	_update_state_diagnostics()


func _step_actions(delta: float, aim: Vector2) -> float:
	if Input.is_action_just_pressed("weapon_1"):
		action_fsm.select_weapon(ActionFSM.DAGGER)
	elif Input.is_action_just_pressed("weapon_2"):
		action_fsm.select_weapon(ActionFSM.SWORD)
	elif Input.is_action_just_pressed("weapon_3"):
		action_fsm.select_weapon(ActionFSM.GREATSWORD)
	return action_fsm.step(delta, Input.is_action_just_pressed("basic_attack"), Input.is_action_pressed("basic_attack"), aim)


func _process(_delta: float) -> void:
	_update_facing()


func is_invulnerable() -> bool:
	return movement_fsm.is_invulnerable()


func _update_facing() -> void:
	var aim_offset := get_global_mouse_position() - global_position
	if aim_offset.length_squared() > AIM_DEAD_ZONE_RADIUS * AIM_DEAD_ZONE_RADIUS:
		facing_marker.global_rotation = aim_offset.angle()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_combat_debug"):
		state_diagnostics.visible = not state_diagnostics.visible
		melee_sweep.visible = state_diagnostics.visible
		_update_state_diagnostics()


func _update_state_diagnostics() -> void:
	if state_diagnostics.visible:
		var dodge_status := "Available" if movement_fsm.can_dodge() else "Recovering"
		if movement_fsm.is_dodging():
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
		state_diagnostics.text += "\nLast damage: %s\nHitstop: %.0f ms remaining" % [
			last_damage, action_fsm.hitstop_remaining * 1000.0,
		]
		if action_fsm.last_hitstop_attack > 0:
			state_diagnostics.text += " (last %.0f ms on #%d)" % [
				action_fsm.last_hitstop_duration * 1000.0, action_fsm.last_hitstop_attack,
			]


func _apply_contact(target: CollisionObject2D, interval: ActionFSM.ActiveInterval) -> void:
	var enemy := target as EnemyHealth
	if enemy == null:
		return
	var applied := enemy.receive_hit(interval.weapon)
	if applied > 0:
		last_damage = "%d to %s from %s (#%d)" % [applied, enemy.name, interval.weapon.display_name, interval.attack_id]
		action_fsm.request_hitstop(interval)
		if enemy.health == 0:
			completion.visible = enemies.all(func(candidate: EnemyHealth) -> bool: return candidate.health == 0)


func _reset_encounter() -> void:
	for enemy in enemies:
		enemy.reset_encounter()
	position = start_position
	facing_marker.rotation = 0.0
	_update_facing()
	action_fsm.reset_encounter()
	movement_fsm.reset_encounter()
	melee_sweep.select_attack(0)
	melee_sweep.begin_tick()
	last_damage = "None"
	completion.hide()
	_update_presentation()
