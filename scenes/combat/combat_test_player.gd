extends CharacterBody2D

const AIM_DEAD_ZONE_RADIUS: float = 4.0

@export var movement_speed: float = 220.0

@onready var facing_marker: Node2D = $FacingMarker


func _physics_process(_delta: float) -> void:
	var movement_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = movement_input * movement_speed
	move_and_slide()


func _process(_delta: float) -> void:
	var aim_offset := get_global_mouse_position() - global_position
	if aim_offset.length_squared() > AIM_DEAD_ZONE_RADIUS * AIM_DEAD_ZONE_RADIUS:
		facing_marker.global_rotation = aim_offset.angle()
