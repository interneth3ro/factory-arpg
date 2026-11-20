extends CharacterBody2D

const WeaponAttack = preload("res://scenes/combat/weapon_attack.gd")
const EnemyMovement = preload("res://scenes/combat/enemy_movement.gd")
const EnemyAttack = preload("res://scenes/combat/enemy_attack.gd")
const DEFEATED_TINT := Color(0.48, 0.48, 0.48)

@export_range(1, 1000) var max_health := 75
@export_range(0.5, 10.0, 0.1) var recoil_distance := 6.0
@export_range(0.05, 0.3, 0.01) var recoil_duration := 0.12
@export_range(0.0, 12.0, 0.5) var recoil_degrees := 7.0

@onready var health := max_health
@onready var movement: EnemyMovement = $Movement
@onready var attack: EnemyAttack = $Attack
@onready var _start_position := position
@onready var _solid_layers := collision_layer
@onready var _initial_mask := collision_mask
@onready var _body: Polygon2D = $Body
@onready var _body_color := _body.color
@onready var _initial_tint := modulate
var _flash: Tween
var _recoil: Tween
# Local visual displacement (x, y) and tilt in radians (z).
var _recoil_pose := Vector3.ZERO
var _flash_strength := 0.0:
	set(value):
		_flash_strength = value
		_update_body()


func _ready() -> void:
	attack.presentation_changed.connect(_update_body)


func _update_body() -> void:
	var tint := _body_color
	var lean := 0.0
	var pose := 0.0
	if health > 0:
		match attack.phase:
			EnemyAttack.Phase.WIND_UP:
				var progress := 1.0 - attack.remaining / attack.wind_up
				lean = -progress
				pose = progress
				tint = tint.lerp(Color.ORANGE_RED, 0.6 * progress)
				if attack.committed != Vector2.ZERO:
					tint = tint.lerp(Color.GOLD, 0.45)
			EnemyAttack.Phase.ACTIVE:
				lean = 1.0
				pose = 1.0
				var flash := attack.remaining / attack.active
				tint = tint.lerp(Color.WHITE, flash * (0.95 if attack.ground_warning else 0.68))
			EnemyAttack.Phase.RECOVERY:
				pose = attack.remaining / attack.recovery
				lean = pose
				tint = tint.lerp(Color.CORAL, 0.4 * pose * pose)
	var direction := attack.tracking
	_body.position = direction * lean * (8.0 if attack.ground_warning else 5.0)
	_body.rotation = lerp_angle(0.0, direction.angle() + PI / 2.0, pose)
	var limit := _recoil_phase_scale()
	_body.position += Vector2(_recoil_pose.x, _recoil_pose.y).limit_length(recoil_distance * limit)
	var max_tilt := deg_to_rad(recoil_degrees) * limit
	_body.rotation += clampf(_recoil_pose.z, -max_tilt, max_tilt)
	_body.scale = Vector2(1.0 - 0.10 * pose, 1.0 + 0.16 * pose)
	_body.color = tint.lerp(Color.WHITE, _flash_strength)


func _recoil_phase_scale() -> float:
	match attack.phase:
		EnemyAttack.Phase.WIND_UP:
			return 0.35
		EnemyAttack.Phase.ACTIVE:
			return 0.12
	return 1.0


func _react(direction: Vector2, weapon: WeaponAttack) -> void:
	if _recoil:
		_recoil.kill()
	var limit := _recoil_phase_scale()
	var strength := lerpf(0.42, 1.0, weapon.feedback_weight) * limit
	var offset := direction * recoil_distance * strength
	var angle := direction.x * deg_to_rad(recoil_degrees) * strength
	var current := Vector2(_recoil_pose.x, _recoil_pose.y).limit_length(recoil_distance * limit)
	var max_tilt := deg_to_rad(recoil_degrees) * limit
	var start := Vector3(current.x, current.y, clampf(_recoil_pose.z, -max_tilt, max_tilt))
	var peak := Vector3(offset.x, offset.y, angle)
	_recoil = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_recoil.tween_method(_set_recoil, start, peak, recoil_duration * 0.28)
	_recoil.tween_method(_set_recoil, peak, Vector3.ZERO, recoil_duration * 0.72)


func _set_recoil(value: Vector3) -> void:
	_recoil_pose = value
	_update_body()


func _clear_recoil() -> void:
	if _recoil:
		_recoil.kill()
		_recoil = null
	_recoil_pose = Vector3.ZERO


func receive_hit(weapon: WeaponAttack, direction := Vector2.ZERO) -> int:
	var applied := mini(health, weapon.damage)
	if applied <= 0:
		return 0
	health -= applied
	if health == 0:
		_clear_recoil()
		# Called from a direct-space query in the player's physics step.
		collision_layer = 0
		collision_mask = 0
		movement.defeat()
	elif not direction.is_zero_approx():
		_react(direction.normalized(), weapon)
	if _flash:
		_flash.kill()
	_flash_strength = weapon.flash_strength
	_flash = create_tween()
	_flash.tween_property(self, "_flash_strength", 0.0, weapon.flash_duration)
	if health == 0:
		_flash.tween_property(self, "modulate", _initial_tint * DEFEATED_TINT, 0.08)
	return applied


func rest_after_player_death() -> void:
	if health == 0:
		return
	# Cancel combat now, then settle only the artwork from its visible pose.
	var pose := _body.transform
	var tint := _body.color
	_clear_recoil()
	if _flash:
		_flash.kill()
	_flash_strength = 0.0
	movement.rest()
	_body.transform = pose
	_body.color = tint
	_flash = create_tween().set_parallel(true)
	_flash.tween_property(_body, "position", Vector2.ZERO, 0.20)
	_flash.tween_property(_body, "rotation", 0.0, 0.20)
	_flash.tween_property(_body, "scale", Vector2.ONE, 0.20)
	_flash.tween_property(_body, "color", _body_color, 0.20)


func reset_encounter(generation: int) -> void:
	_clear_recoil()
	if _flash:
		_flash.kill()
		_flash = null
	health = max_health
	collision_layer = _solid_layers
	collision_mask = _initial_mask
	position = _start_position
	movement.reset_encounter(generation)
	_flash_strength = 0.0
	modulate = _initial_tint
