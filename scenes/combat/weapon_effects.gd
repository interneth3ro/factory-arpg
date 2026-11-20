extends Node2D

const ActionFSM = preload("res://scenes/combat/player_action_fsm.gd")
const WeaponAttack = preload("res://scenes/combat/weapon_attack.gd")
const INK := Color(0.69, 0.76, 0.79)
const LIGHT := Color(0.98, 0.97, 0.90)

class Burst:
	var point: Vector2
	var direction: Vector2
	var weight: float
	var age := 0.0
	var lifetime: float

var _bursts: Array[Burst] = []
var _trail_id := 0
var _weapon: WeaponAttack
var _angles := PackedFloat64Array()
var _times := PackedFloat64Array()
var _fade_left := 0.0
var _fade_duration := 0.0
var _fade_origin := Vector2.ZERO


func follow(interval: ActionFSM.ActiveInterval, end_origin: Vector2) -> void:
	if interval.attack_id != _trail_id:
		clear_trail()
		_trail_id = interval.attack_id
		_weapon = interval.weapon
		_angles.append(interval.blade_angle(interval.tick_start))
		_times.append(interval.active_elapsed)
	if interval.duration > 0.0:
		# Sample the FSM's bounded correction and keep a short history of
		# the blade's outer edge, including on long physics steps.
		var steps := maxi(1, ceili(interval.duration / _weapon.active * _weapon.sweep_angle / 4.0))
		for i in range(1, steps + 1):
			var offset := interval.duration * i / steps
			_angles.append(interval.blade_angle(interval.tick_start + offset))
			_times.append(interval.active_elapsed + offset)
		var cutoff := _times[-1] - _weapon.active * lerpf(0.35, 0.52, _weapon.feedback_weight)
		while _times.size() > 2 and _times[1] <= cutoff:
			_times.remove_at(0)
			_angles.remove_at(0)
	if interval.ends_active:
		_fade_origin = end_origin
		_fade_duration = lerpf(0.035, 0.075, _weapon.feedback_weight)
		_fade_left = _fade_duration
	queue_redraw()


func decay_trail(seconds: float) -> void:
	if _fade_left > 0.0:
		_fade_left = maxf(0.0, _fade_left - seconds)
		if _fade_left == 0.0:
			clear_trail()
		queue_redraw()


func clear_trail() -> void:
	_trail_id = 0
	_weapon = null
	_angles.clear()
	_times.clear()
	_fade_left = 0.0
	queue_redraw()


func burst(point: Vector2, direction: Vector2, weapon: WeaponAttack) -> void:
	var effect := Burst.new()
	effect.point = point
	effect.direction = direction
	effect.weight = weapon.feedback_weight
	effect.lifetime = lerpf(0.075, 0.16, effect.weight)
	_bursts.append(effect)
	set_process(true)
	queue_redraw()


func reset() -> void:
	clear_trail()
	_bursts.clear()
	set_process(false)


func _process(delta: float) -> void:
	for i in range(_bursts.size() - 1, -1, -1):
		_bursts[i].age += delta
		if _bursts[i].age >= _bursts[i].lifetime:
			_bursts.remove_at(i)
	set_process(not _bursts.is_empty())
	queue_redraw()


func _draw() -> void:
	if _weapon:
		_draw_trail()
	for effect in _bursts:
		_draw_burst(effect)


func _draw_trail() -> void:
	var origin := to_local(_fade_origin) if _fade_left > 0.0 else Vector2.ZERO
	var opacity := _fade_left / _fade_duration if _fade_left > 0.0 else 1.0
	var width := lerpf(3.0, 13.0, _weapon.feedback_weight)
	var tip := origin + Vector2.from_angle(_angles[0]) * _weapon.reach
	var initial_width := width if _angles.size() == 1 else width * 0.15
	var inside := tip - Vector2.from_angle(_angles[0]) * initial_width
	for i in range(1, _angles.size()):
		var t := float(i) / (_angles.size() - 1)
		var blade := Vector2.from_angle(_angles[i])
		var next_tip := origin + blade * _weapon.reach
		if next_tip.is_equal_approx(tip):
			continue
		var next_inside := next_tip - blade * width * lerpf(0.15, 1.0, t)
		draw_colored_polygon(PackedVector2Array([inside, tip, next_tip, next_inside]), Color(INK, opacity * t * 0.48))
		draw_line(tip, next_tip, Color(LIGHT, opacity * t * 0.80), 1.2, true)
		tip = next_tip
		inside = next_inside
	draw_line(inside, tip, Color(LIGHT, opacity * 0.9), 1.6, true)


func _draw_burst(effect: Burst) -> void:
	var t := effect.age / effect.lifetime
	var length := lerpf(9.0, 21.0, effect.weight)
	var spread := lerpf(0.18, 0.76, effect.weight)
	var rays := 5 if effect.weight > 0.75 else 3
	var center := to_local(effect.point)
	for i in rays:
		var side := 2.0 * i / (rays - 1) - 1.0
		var axis := effect.direction.rotated(side * spread)
		var base := center + axis * (t * length * 0.48)
		var half_width := axis.orthogonal() * lerpf(0.75, 2.3, effect.weight) * (1.0 - t)
		var tip := base + axis * length * (1.0 - 0.5 * absf(side)) * (1.0 - 0.65 * t)
		var tint := LIGHT.lerp(INK, absf(side) * 0.7)
		draw_colored_polygon(PackedVector2Array([base - half_width, tip, base + half_width]), Color(tint, 1.0 - t))
