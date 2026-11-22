extends Node

@export var location_scene: PackedScene

var _active_location: Node


func initialize() -> bool:
	var host := get_node_or_null("ActiveLocation")
	if _active_location != null or host == null or location_scene == null:
		return false

	var location := location_scene.instantiate()
	if location == null:
		return false

	host.add_child(location)
	_active_location = location
	return true


func teardown() -> void:
	if _active_location != null:
		_active_location.free()
		_active_location = null
