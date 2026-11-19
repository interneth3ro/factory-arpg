extends Node

signal state_changed

enum State { IDLE, MOVING }

var _state := State.IDLE

@onready var _body := get_parent() as CharacterBody2D


func step(direction: Vector2, movement_speed: float) -> void:
	_body.velocity = direction * movement_speed
	_body.move_and_slide()

	var next_state := State.IDLE if direction == Vector2.ZERO else State.MOVING
	if next_state != _state:
		_state = next_state
		state_changed.emit()


func get_state_name() -> String:
	return String(State.keys()[_state]).capitalize()
