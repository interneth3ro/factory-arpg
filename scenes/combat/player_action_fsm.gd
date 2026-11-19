extends Node

enum State { READY }

var _state := State.READY


func get_state_name() -> String:
	return String(State.keys()[_state]).capitalize()
