extends CharacterBody2D

const AIM_DEAD_ZONE_RADIUS: float = 4.0
const MovementFSM = preload("res://scenes/combat/player_movement_fsm.gd")
const ActionFSM = preload("res://scenes/combat/player_action_fsm.gd")
const PHASE_COLORS := {
	ActionFSM.State.READY: Color(0.3, 0.82, 0.95),
	ActionFSM.State.WIND_UP: Color(1.0, 0.72, 0.16),
	ActionFSM.State.ACTIVE: Color.WHITE,
	ActionFSM.State.RECOVERY: Color(0.66, 0.43, 0.85),
}

@export var movement_speed: float = 220.0

@onready var facing_marker: Node2D = $FacingMarker
@onready var body_marker: Polygon2D = $Body
@onready var movement_fsm: MovementFSM = $MovementFSM
@onready var action_fsm: ActionFSM = $ActionFSM
@onready var state_diagnostics: Label = $Diagnostics/StateLabel


func _physics_process(delta: float) -> void:
	var movement_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if Input.is_action_just_pressed("dodge"):
		_update_facing()
		var facing_direction := Vector2.RIGHT.rotated(facing_marker.global_rotation)
		if movement_fsm.request_dodge(movement_input, facing_direction):
			action_fsm.interrupt_attack()
	# Sample before advancing movement so the final dodge tick still discards input.
	if not movement_fsm.is_dodging():
		_step_actions(delta)
	movement_fsm.step(movement_input, movement_speed, delta)
	body_marker.color = PHASE_COLORS[action_fsm.state]
	_update_state_diagnostics()


func _step_actions(delta: float) -> void:
	if Input.is_action_just_pressed("weapon_1"):
		action_fsm.select_weapon(ActionFSM.DAGGER)
	elif Input.is_action_just_pressed("weapon_2"):
		action_fsm.select_weapon(ActionFSM.SWORD)
	elif Input.is_action_just_pressed("weapon_3"):
		action_fsm.select_weapon(ActionFSM.GREATSWORD)
	action_fsm.step(delta, Input.is_action_just_pressed("basic_attack"), Input.is_action_pressed("basic_attack"))


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
		_update_state_diagnostics()


func _update_state_diagnostics() -> void:
	if state_diagnostics.visible:
		var dodge_status := "Available" if movement_fsm.can_dodge() else "Recovering"
		if movement_fsm.is_dodging():
			dodge_status = "In progress"
		state_diagnostics.text = "Movement: %s\nAction / phase: %s\nWeapon: %s\nAttack count: %d\nDodge: %s\nInvulnerability: %s" % [
			movement_fsm.get_state_name(),
			action_fsm.get_state_name(),
			action_fsm.weapon.display_name,
			action_fsm.attack_count,
			dodge_status,
			"Active" if is_invulnerable() else "Inactive",
		]
