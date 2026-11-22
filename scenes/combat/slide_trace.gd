extends RefCounted

## Positions and physics-tick offsets for one collision-resolved move. As in
## the player melee sweep, the travel/remainder ratio estimates time to impact.
var positions := PackedVector2Array()
var times := PackedFloat64Array()


func record(body: CharacterBody2D, start: Vector2, from: float, travel_time: float, until: float) -> void:
	positions = PackedVector2Array([start])
	times = PackedFloat64Array([from])
	var point := start
	var time := from
	var finish := from + travel_time
	if travel_time > 0.0:
		for i in body.get_slide_collision_count():
			var hit := body.get_slide_collision(i)
			var travel := hit.get_travel()
			var total := travel.length() + hit.get_remainder().length()
			if total > 0.0:
				time = lerpf(time, finish, travel.length() / total)
				point += travel
				_append(time, point)
	_append(finish, body.global_position)
	_append(until, body.global_position)


func _append(time: float, point: Vector2) -> void:
	if time <= times[-1]:
		positions[-1] = point
	else:
		times.append(time)
		positions.append(point)


func at(time: float) -> Vector2:
	for i in range(1, times.size()):
		if time <= times[i]:
			return positions[i - 1].lerp(positions[i], clampf((time - times[i - 1]) / (times[i] - times[i - 1]), 0, 1))
	return positions[-1]


## move_and_slide used one average speed. Put the speed changes and slide
## vertices on the real tick clock before anyone samples a firing/contact pose.
func retime(elapsed: PackedFloat64Array, weighted: PackedFloat64Array) -> void:
	if elapsed.size() < 3:
		return
	var average := weighted[-1] / elapsed[-1]
	var points := PackedVector2Array([positions[0]])
	var offsets := PackedFloat64Array([0.0])
	var vertex := 1
	for i in range(1, elapsed.size()):
		var start := weighted[i - 1] / average
		var finish := weighted[i] / average
		while vertex < times.size() and times[vertex] < finish:
			if times[vertex] > start:
				points.append(positions[vertex])
				offsets.append(remap(times[vertex], start, finish, elapsed[i - 1], elapsed[i]))
			vertex += 1
		points.append(at(finish))
		offsets.append(elapsed[i])
	positions = points
	times = offsets
