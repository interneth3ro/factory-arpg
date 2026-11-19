extends CharacterBody2D

const AIM_DEAD_ZONE_RADIUS: float = 4.0
const MovementFSM = preload("res://scenes/combat/player_movement_fsm.gd")
const ActionFSM = preload("res://scenes/combat/player_action_fsm.gd")

@export var movement_speed: float = 220.0

@onready var facing_marker: Node2D = $FacingMarker
@onready var movement_fsm: MovementFSM = $MovementFSM
@onready var action_fsm: ActionFSM = $ActionFSM
@onready var state_diagnostics: Label = $Diagnostics/StateLabel


func _physics_process(delta: float) -> void:
	var movement_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if Input.is_action_just_pressed("dodge"):
		_update_facing()
		var facing_direction := Vector2.RIGHT.rotated(facing_marker.global_rotation)
		movement_fsm.request_dodge(movement_input, facing_direction)
	movement_fsm.step(movement_input, movement_speed, delta)
	_update_state_diagnostics()


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
		state_diagnostics.text = "Movement: %s\nAction: %s\nDodge: %s\nInvulnerability: %s" % [
			movement_fsm.get_state_name(),
			action_fsm.get_state_name(),
			dodge_status,
			"Active" if is_invulnerable() else "Inactive",
		]
