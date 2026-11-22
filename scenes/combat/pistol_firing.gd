extends RefCounted

const INTERVAL := 1.0 / 3.0
const COMMITMENT := 0.120
const MOVEMENT := 0.80
# A sub-nanosecond residue from splitting one interval across physics ticks.
const CLOCK_EPSILON := 1.0e-12

var cooldown := 0.0
var commitment := 0.0
var shots_fired := 0
var repeating := false
var _needs_ready_press := true
# Physics offsets at which the coordinator must sample a launch pose.
var shots := PackedFloat64Array()
# Piecewise map from elapsed time to equivalent full-speed movement time.
var times := PackedFloat64Array()
var movement_times := PackedFloat64Array()


func interrupt() -> void:
	commitment = 0.0
	repeating = false
	_needs_ready_press = true


func reset() -> void:
	interrupt()
	cooldown = 0.0
	shots_fired = 0
	idle(0.0)


func idle(delta: float) -> void:
	cooldown = _remaining(cooldown, delta)
	shots.clear()
	times.clear()
	movement_times.clear()


func step(delta: float, pressed: bool, held: bool, on_uncommitted: Callable) -> float:
	shots.clear()
	times = PackedFloat64Array([0.0])
	movement_times = PackedFloat64Array([0.0])
	# A new hold between ordinary shots can repeat at readiness. After a
	# dodge or activation the first shot must come from a ready press.
	repeating = held and (repeating or (pressed and not _needs_ready_press))
	var now := 0.0
	while true:
		if cooldown == 0.0 and (pressed or repeating):
			shots.append(now)
			shots_fired += 1
			cooldown = INTERVAL
			commitment = COMMITMENT
			_needs_ready_press = false
			repeating = held
		pressed = false
		if now >= delta:
			break
		var spent := delta - now
		var committed := commitment > 0.0
		if committed:
			spent = minf(spent, commitment)
		elif repeating:
			spent = minf(spent, cooldown)
		movement_times.append(movement_times[-1] + spent * (MOVEMENT if committed else 1.0))
		now += spent
		times.append(now)
		cooldown = _remaining(cooldown, spent)
		commitment = _remaining(commitment, spent)
		if committed and commitment == 0.0 and on_uncommitted.call():
			repeating = false
	return movement_times[-1] / delta if delta > 0.0 else (MOVEMENT if commitment > 0.0 else 1.0)


func _remaining(timer: float, spent: float) -> float:
	var left := timer - spent
	return left if left > CLOCK_EPSILON else 0.0
