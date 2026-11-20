extends CharacterBody2D

const WeaponAttack = preload("res://scenes/combat/weapon_attack.gd")
const EnemyMovement = preload("res://scenes/combat/enemy_movement.gd")
const EnemyAttack = preload("res://scenes/combat/enemy_attack.gd")
const DEFEATED_TINT := Color(0.48, 0.48, 0.48)

@export_range(1, 1000) var max_health := 75

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
	_body.scale = Vector2(1.0 - 0.10 * pose, 1.0 + 0.16 * pose)
	_body.color = tint.lerp(Color.WHITE, _flash_strength)


func receive_hit(weapon: WeaponAttack) -> int:
	var applied := mini(health, weapon.damage)
	if applied <= 0:
		return 0
	health -= applied
	if health == 0:
		# Called from a direct-space query in the player's physics step.
		collision_layer = 0
		collision_mask = 0
		movement.defeat()
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
