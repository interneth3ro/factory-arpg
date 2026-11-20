extends CharacterBody2D

const WeaponAttack = preload("res://scenes/combat/weapon_attack.gd")
const DEFEATED_TINT := Color(0.48, 0.48, 0.48)

@export_range(1, 1000) var max_health := 75

@onready var health := max_health
@onready var _start_position := position
@onready var _solid_layers := collision_layer
@onready var _initial_mask := collision_mask
@onready var _body: Polygon2D = $Body
@onready var _body_color := _body.color
@onready var _initial_tint := modulate
var _flash: Tween


func receive_hit(weapon: WeaponAttack) -> int:
	var applied := mini(health, weapon.damage)
	if applied <= 0:
		return 0
	health -= applied
	if health == 0:
		# Called from a direct-space query in the player's physics step.
		collision_layer = 0
		collision_mask = 0
	if _flash:
		_flash.kill()
	_body.color = _body_color.lerp(Color.WHITE, weapon.flash_strength)
	_flash = create_tween()
	_flash.tween_property(_body, "color", _body_color, weapon.flash_duration)
	if health == 0:
		_flash.tween_property(self, "modulate", _initial_tint * DEFEATED_TINT, 0.08)
	return applied


func reset_encounter() -> void:
	if _flash:
		_flash.kill()
		_flash = null
	health = max_health
	collision_layer = _solid_layers
	collision_mask = _initial_mask
	position = _start_position
	_body.color = _body_color
	modulate = _initial_tint
