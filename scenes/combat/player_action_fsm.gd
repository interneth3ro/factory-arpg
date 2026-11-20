extends Node

const WeaponAttack = preload("res://scenes/combat/weapon_attack.gd")
const DAGGER: WeaponAttack = preload("res://scenes/combat/dagger.tres")
const SWORD: WeaponAttack = preload("res://scenes/combat/one_handed_sword.tres")
const GREATSWORD: WeaponAttack = preload("res://scenes/combat/greatsword.tres")

enum State { READY, WIND_UP, ACTIVE, RECOVERY }
enum AimState { INACTIVE, TRACKING, CORRECTING, LOCKED }
const PHASE_NAMES := ["Ready", "Wind-up", "Active", "Recovery"]

@export_range(0.01, 0.5, 0.01, "suffix:s") var late_recovery_window: float = 0.15
@export_range(0.01, 0.5, 0.01, "suffix:s") var buffer_lifetime: float = 0.10

var state := State.READY
var weapon: WeaponAttack = DAGGER
var attack_count: int = 0
var attack_direction := Vector2.ZERO
var _phase_elapsed: float = 0.0
var _buffer_remaining: float = 0.0


func get_state_name() -> String:
	return PHASE_NAMES[state]


func get_aim_state() -> AimState:
	match state:
		State.READY:
			return AimState.INACTIVE
		State.WIND_UP:
			if weapon.aim_mode == WeaponAttack.AimMode.LOCK_DURING_WIND_UP:
				if _phase_elapsed >= weapon.wind_up * weapon.wind_up_lock_fraction:
					return AimState.LOCKED
			return AimState.TRACKING
		State.ACTIVE:
			if weapon.aim_mode == WeaponAttack.AimMode.CORRECT_ACTIVE:
				return AimState.CORRECTING
	return AimState.LOCKED


func get_movement_multiplier() -> float:
	match state:
		State.WIND_UP:
			return weapon.wind_up_movement
		State.ACTIVE:
			return weapon.active_movement
		State.RECOVERY:
			return weapon.recovery_movement
	return 1.0


func select_weapon(selection: WeaponAttack) -> void:
	if state == State.READY:
		weapon = selection


func interrupt_attack() -> void:
	state = State.READY
	attack_direction = Vector2.ZERO
	_phase_elapsed = 0.0
	_buffer_remaining = 0.0


## Returns the time-weighted ordinary movement multiplier for this physics tick.
func step(delta: float, pressed: bool, held: bool, aim: Vector2) -> float:
	if pressed:
		if state == State.READY:
			_start_attack(aim)
		elif state == State.RECOVERY and weapon.recovery - _phase_elapsed <= late_recovery_window:
			_buffer_remaining = buffer_lifetime

	# Consume time up to each boundary, including the instant a repeat can start.
	var remaining := delta
	var weighted_time := 0.0
	while remaining > 0.0 and state != State.READY:
		var until_boundary := _phase_duration() - _phase_elapsed
		var spent := minf(remaining, until_boundary)
		weighted_time += spent * get_movement_multiplier()
		# Aim is sampled once per tick. Crossing the wind-up lock point keeps
		# this sample and prevents subsequent ticks from tracking again.
		match get_aim_state():
			AimState.TRACKING:
				attack_direction = aim
			AimState.CORRECTING:
				var limit := deg_to_rad(weapon.correction_speed) * spent
				attack_direction = attack_direction.rotated(clampf(attack_direction.angle_to(aim), -limit, limit))
		_buffer_remaining = maxf(0.0, _buffer_remaining - spent)
		if remaining < until_boundary:
			_phase_elapsed += spent
			remaining = 0.0
			break
		remaining -= spent
		_phase_elapsed = 0.0
		match state:
			State.WIND_UP:
				state = State.ACTIVE
			State.ACTIVE:
				state = State.RECOVERY
			State.RECOVERY:
				if held or _buffer_remaining > 0.0:
					_start_attack(aim)
				else:
					interrupt_attack()
	# Any unused time belongs to Ready, at full movement speed.
	return (weighted_time + remaining) / delta if delta > 0.0 else get_movement_multiplier()


func _start_attack(aim: Vector2) -> void:
	state = State.WIND_UP
	attack_direction = aim
	_phase_elapsed = 0.0
	_buffer_remaining = 0.0
	attack_count += 1


func _phase_duration() -> float:
	match state:
		State.WIND_UP:
			return weapon.wind_up
		State.ACTIVE:
			return weapon.active
		State.RECOVERY:
			return weapon.recovery
	return 0.0
