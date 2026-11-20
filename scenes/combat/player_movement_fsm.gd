extends Node

signal state_changed

enum State { IDLE, MOVING, DODGING }

@export_range(0.05, 1.0, 0.01, "suffix:s") var dodge_duration: float = 0.24
@export_range(1.0, 500.0, 1.0, "suffix:px") var dodge_distance: float = 120.0
@export_range(0.05, 0.50, 0.01) var dodge_invulnerability_fraction: float = 0.40
@export_range(0.01, 1.0, 0.01, "suffix:s") var dodge_recovery_duration: float = 0.16

var _state := State.IDLE
var _dodge_direction := Vector2.ZERO
var _dodge_elapsed: float = 0.0
var _dodge_recovery_remaining: float = 0.0

@onready var _body := get_parent() as CharacterBody2D


func request_dodge(movement_input: Vector2, facing_direction: Vector2) -> bool:
	if not can_dodge():
		return false

	var direction := facing_direction if movement_input == Vector2.ZERO else movement_input
	_dodge_direction = direction.normalized()
	_dodge_elapsed = 0.0
	_transition_to(State.DODGING)
	return true


func step(direction: Vector2, movement_speed: float, delta: float, ordinary_multiplier: float = 1.0) -> void:
	var ordinary_state := State.IDLE if direction == Vector2.ZERO else State.MOVING
	if is_dodging():
		_step_dodge(delta)
		if _dodge_elapsed >= dodge_duration:
			_dodge_recovery_remaining = dodge_recovery_duration
			_transition_to(ordinary_state)
		return

	_body.velocity = direction * movement_speed * ordinary_multiplier
	_body.move_and_slide()
	_dodge_recovery_remaining = maxf(0.0, _dodge_recovery_remaining - delta)
	_transition_to(ordinary_state)


func can_dodge() -> bool:
	return not is_dodging() and _dodge_recovery_remaining <= 0.0


func is_dodging() -> bool:
	return _state == State.DODGING


func is_invulnerable() -> bool:
	return is_dodging() and _dodge_elapsed < dodge_duration * dodge_invulnerability_fraction


func get_state_name() -> String:
	return String(State.keys()[_state]).capitalize()


func _step_dodge(delta: float) -> void:
	var next_elapsed := minf(_dodge_elapsed + delta, dodge_duration)
	var midpoint_progress := (_dodge_elapsed + next_elapsed) / (2.0 * dodge_duration)
	var initial_speed := 2.0 * dodge_distance / dodge_duration
	var average_speed := initial_speed * (1.0 - midpoint_progress)
	# Scale the final partial step because move_and_slide uses the full physics delta.
	var step_fraction := (next_elapsed - _dodge_elapsed) / delta
	_body.velocity = _dodge_direction * (average_speed * step_fraction)
	_body.move_and_slide()
	_dodge_elapsed = next_elapsed


func _transition_to(next_state: State) -> void:
	if next_state != _state:
		_state = next_state
		state_changed.emit()
