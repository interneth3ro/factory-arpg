extends Node

const WeaponAttack = preload("res://scenes/combat/weapon_attack.gd")
const DAGGER: WeaponAttack = preload("res://scenes/combat/dagger.tres")
const SWORD: WeaponAttack = preload("res://scenes/combat/one_handed_sword.tres")
const GREATSWORD: WeaponAttack = preload("res://scenes/combat/greatsword.tres")

enum State { READY, WIND_UP, ACTIVE, RECOVERY }
const PHASE_NAMES := ["Ready", "Wind-up", "Active", "Recovery"]

@export_range(0.01, 0.5, 0.01, "suffix:s") var late_recovery_window: float = 0.15
@export_range(0.01, 0.5, 0.01, "suffix:s") var buffer_lifetime: float = 0.10

var state := State.READY
var weapon: WeaponAttack = DAGGER
var attack_count: int = 0
var _phase_elapsed: float = 0.0
var _buffer_remaining: float = 0.0


func get_state_name() -> String:
	return PHASE_NAMES[state]


func select_weapon(selection: WeaponAttack) -> void:
	if state == State.READY:
		weapon = selection


func interrupt_attack() -> void:
	state = State.READY
	_phase_elapsed = 0.0
	_buffer_remaining = 0.0


func step(delta: float, pressed: bool, held: bool) -> void:
	if pressed:
		if state == State.READY:
			_start_attack()
		elif state == State.RECOVERY and weapon.recovery - _phase_elapsed <= late_recovery_window:
			_buffer_remaining = buffer_lifetime

	# Consume time up to each boundary, including the instant a repeat can start.
	var remaining := delta
	while remaining > 0.0 and state != State.READY:
		var until_boundary := _phase_duration() - _phase_elapsed
		var spent := minf(remaining, until_boundary)
		_buffer_remaining = maxf(0.0, _buffer_remaining - spent)
		if remaining < until_boundary:
			_phase_elapsed += spent
			return
		remaining -= spent
		_phase_elapsed = 0.0
		match state:
			State.WIND_UP:
				state = State.ACTIVE
			State.ACTIVE:
				state = State.RECOVERY
			State.RECOVERY:
				if held or _buffer_remaining > 0.0:
					_start_attack()
				else:
					state = State.READY


func _start_attack() -> void:
	state = State.WIND_UP
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
