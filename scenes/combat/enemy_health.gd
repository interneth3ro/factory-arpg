extends CharacterBody2D

const WeaponAttack = preload("res://scenes/combat/weapon_attack.gd")
const EnemyMovement = preload("res://scenes/combat/enemy_movement.gd")
const EnemyAttack = preload("res://scenes/combat/enemy_attack.gd")
const DEFEATED_TINT := Color(0.48, 0.48, 0.48)
const PHASE_BLEND_SECONDS := 0.020

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
# Local visual displacement (x, y) and tilt in radians (z).
var _recoil_pose := Vector3.ZERO
var _recoil_target := Vector3.ZERO
var _recoil_limit := 1.0
var _time_to_target := 0.0
var _release_left := 0.0
var _flash_strength := 0.0:
	set(value):
		_flash_strength = value
		_update_body()


func _ready() -> void:
	set_process(false)
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
	_body.position += Vector2(_recoil_pose.x, _recoil_pose.y)
	_body.rotation += _recoil_pose.z
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
	_recoil_limit = _recoil_phase_scale()
	var strength := lerpf(0.42, 1.0, weapon.feedback_weight) * _recoil_limit
	var offset := direction * recoil_distance * strength
	var angle := direction.x * deg_to_rad(recoil_degrees) * strength
	_recoil_target = Vector3(offset.x, offset.y, angle)
	_time_to_target = recoil_duration * 0.28
	if _recoil_limit < 1.0:
		_time_to_target = minf(_time_to_target, PHASE_BLEND_SECONDS)
	_release_left = recoil_duration - _time_to_target
	set_process(true)


func _process(delta: float) -> void:
	var limit := _recoil_phase_scale()
	if limit < _recoil_limit:
		var attenuation := limit / _recoil_limit
		_recoil_limit = limit
		if _time_to_target > 0.0:
			_recoil_target *= attenuation
			var blend := minf(_time_to_target, PHASE_BLEND_SECONDS)
			_release_left += _time_to_target - blend
			_time_to_target = blend
		elif _release_left > PHASE_BLEND_SECONDS:
			# Split the existing return at the blend boundary. Aim for the
			# attenuated pose it would have reached there, then finish on time.
			_time_to_target = PHASE_BLEND_SECONDS
			_recoil_target = _ease_recoil(Vector3.ZERO, _time_to_target, _release_left) * attenuation
			_release_left -= _time_to_target
	var approach := minf(delta, _time_to_target)
	if approach > 0.0:
		_recoil_pose = _ease_recoil(_recoil_target, approach, _time_to_target)
		_time_to_target -= approach
	var release := minf(delta - approach, _release_left)
	if release > 0.0:
		_recoil_pose = _ease_recoil(Vector3.ZERO, release, _release_left)
		_release_left -= release
	if _release_left == 0.0:
		_clear_recoil()
	_update_body()


func _ease_recoil(target: Vector3, step: float, remaining: float) -> Vector3:
	# Remaining-distance form of quadratic ease-out, independent of frame splits.
	var fraction_left := 1.0 - step / remaining
	return target.lerp(_recoil_pose, fraction_left * fraction_left)


func _clear_recoil() -> void:
	set_process(false)
	_time_to_target = 0.0
	_release_left = 0.0
	_recoil_target = Vector3.ZERO
	_recoil_pose = Vector3.ZERO


func is_encounter_active() -> bool:
	return movement.state != EnemyMovement.State.INACTIVE


func receive_hit(weapon: WeaponAttack, direction := Vector2.ZERO) -> int:
	if not is_encounter_active():
		return 0
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
	if health == 0 or not is_encounter_active():
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


func reset_encounter(generation: int, participating := true) -> void:
	_clear_recoil()
	if _flash:
		_flash.kill()
		_flash = null
	health = max_health
	visible = participating
	collision_layer = _solid_layers if participating else 0
	collision_mask = _initial_mask if participating else 0
	position = _start_position
	movement.reset_encounter(generation, participating)
	_flash_strength = 0.0
	modulate = _initial_tint
