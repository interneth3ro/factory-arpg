extends Node2D

const Sector = preload("res://scenes/combat/enemy_attack_sector.gd")
const SlideTrace = preload("res://scenes/combat/slide_trace.gd")

## Movement advances this clock inside its avoidance callback. An Active
## interval is resolved synchronously, before the next phase or execution.
signal active_interval(tick_start: float, duration: float)
signal standstill_requested
signal recovery_finished
signal contact_registered(target: CharacterBody2D, contact: Contact)
signal presentation_changed

enum Phase { READY, WIND_UP, ACTIVE, RECOVERY }

class Contact:
	var enemy: StringName
	var execution_id: int
	var frame: int
	var generation: int
	var time: float
	var earliest_possible: float
	var damage: int
	var flash_strength: float
	var flash_seconds: float
	var emphasis_seconds: float

	func precedes(other: Contact) -> bool:
		if time != other.time:
			return time < other.time
		if enemy != other.enemy:
			return String(enemy) < String(other.enemy)
		return execution_id < other.execution_id


@export_range(1, 1000) var damage := 15
@export_range(0, 1) var flash_strength := 0.66
@export_range(0.01, 1) var flash_seconds := 0.12
@export_range(0.01, 1) var emphasis_seconds := 0.04
@export_range(1, 300) var initiation_radius := 65.0
@export_range(0.01, 5) var wind_up := 0.35
@export_range(0.01, 5) var active := 0.15
@export_range(0.01, 5) var recovery := 0.45
@export_range(0.01, 5) var cooldown := 0.30
@export_range(0.0, 5) var engagement_delay := 0.25
@export_range(0.0, 1) var commitment_fraction := 0.60
@export_range(0, 720) var turn_rate := 360.0
@export_range(1, 300) var reach := 60.0
@export_range(1, 179) var sector_degrees := 70.0
@export_range(0, 100) var lunge := 35.0
@export var ground_warning := false

var phase := Phase.READY
var remaining := 0.0
var delay_left := 0.0
var cooldown_left := 0.0
var tracking := Vector2.ZERO
var committed := Vector2.ZERO
var execution := 0
var contacted := false # The arena has exactly one player target.
var displacement := Vector2.ZERO
var paused_this_tick := 0.0
var debug_visible := false
var _acquired := false
var _heading := Vector2.RIGHT
var _pause_frame := -1
var _sector := Sector.new()
var _visible_region: Array[PackedVector2Array] = []
var _region_origin := Vector2.INF
var _region_direction := Vector2.ZERO
@onready var _player_shape: CollisionShape2D = $"../../Player/CollisionShape2D"
@onready var _body: CharacterBody2D = get_parent()
@onready var _player: CharacterBody2D = _player_shape.get_parent()


func _ready() -> void:
	_sector.read_arena(get_tree())
	var actions: Node = $"../../Player/ActionFSM"
	actions.connect("hitstop_consumed", _on_hitstop_consumed)


func _on_hitstop_consumed(seconds: float) -> void:
	if _body.collision_layer == 0:
		return
	_pause_frame = Engine.get_physics_frames()
	paused_this_tick = seconds


func start_tick() -> void:
	if _pause_frame != Engine.get_physics_frames():
		paused_this_tick = 0.0


func acquire() -> void:
	_acquired = true
	delay_left = engagement_delay


func disengage() -> void:
	_acquired = false
	delay_left = 0.0


func reset_encounter() -> void:
	execution = 0
	contacted = false
	displacement = Vector2.ZERO
	cancel_execution()


func cancel_execution() -> void:
	disengage()
	phase = Phase.READY
	remaining = 0.0
	cooldown_left = 0.0
	tracking = Vector2.ZERO
	committed = Vector2.ZERO
	_heading = Vector2.RIGHT
	_visible_region.clear()
	_region_origin = Vector2.INF
	paused_this_tick = 0.0
	_pause_frame = -1
	refresh()


func wait_time() -> float:
	return maxf(delay_left, cooldown_left)


func advance_wait(duration: float) -> void:
	delay_left = maxf(0, delay_left - duration)
	cooldown_left = maxf(0, cooldown_left - duration)


func active_time_in(budget: float) -> float:
	if phase == Phase.WIND_UP:
		return clampf(budget - remaining, 0, active)
	if phase == Phase.ACTIVE:
		return minf(budget, remaining)
	return 0.0


func face_motion(direction: Vector2) -> void:
	if not direction.is_zero_approx():
		_heading = direction.normalized()


func begin() -> void:
	execution += 1
	contacted = false
	displacement = Vector2.ZERO
	tracking = _heading
	committed = Vector2.ZERO
	phase = Phase.WIND_UP
	remaining = wind_up


func in_range_and_visible(has_sight: Callable) -> bool:
	return _acquired and global_position.distance_to(_player.global_position) <= initiation_radius and has_sight.call()


## Driven once per valid movement command. A synchronous standstill request
## revokes that command before begin() starts the wind-up clock.
func advance_tick(delta: float, has_sight: Callable, navigate: Callable) -> void:
	var cursor := paused_this_tick
	var ordinary_prefix := cursor if phase == Phase.READY else 0.0
	if ordinary_prefix == delta:
		navigate.call(ordinary_prefix)
	while cursor < delta:
		var budget := delta - cursor
		if phase != Phase.READY:
			var spent := advance_phase(budget, cursor, _player.global_position)
			cursor = delta if spent >= budget else cursor + spent
			if phase == Phase.READY:
				recovery_finished.emit()
			continue
		var eligible := in_range_and_visible(has_sight)
		var wait := minf(budget, wait_time()) if eligible else budget
		navigate.call(ordinary_prefix + wait)
		ordinary_prefix = 0.0
		advance_wait(wait)
		cursor = delta if wait >= budget else cursor + wait
		if eligible and wait_time() <= 0.0 and in_range_and_visible(has_sight):
			standstill_requested.emit()
			begin()
	refresh()


func advance_phase(budget: float, tick_start: float, target: Vector2) -> float:
	var spent := minf(budget, remaining)
	match phase:
		Phase.WIND_UP:
			var until_lock := remaining - wind_up * (1.0 - commitment_fraction)
			var turn := deg_to_rad(turn_rate) * clampf(until_lock, 0.0, spent)
			var aim := global_position.direction_to(target)
			if committed == Vector2.ZERO and not aim.is_zero_approx():
				tracking = tracking.rotated(clampf(tracking.angle_to(aim), -turn, turn))
			if spent >= until_lock and committed == Vector2.ZERO:
				committed = tracking
				_heading = committed
		Phase.ACTIVE:
			active_interval.emit(tick_start, spent)
	remaining -= spent
	if remaining <= 0.0:
		match phase:
			Phase.WIND_UP:
				phase = Phase.ACTIVE
				remaining = active
			Phase.ACTIVE:
				phase = Phase.RECOVERY
				remaining = recovery
			Phase.RECOVERY:
				phase = Phase.READY
				cooldown_left = cooldown
	return spent


func refresh() -> void:
	if phase == Phase.ACTIVE or (ground_warning and phase == Phase.WIND_UP):
		_region_at(global_position, tracking)
	presentation_changed.emit()
	queue_redraw()


func _region_at(origin: Vector2, direction: Vector2) -> Array[PackedVector2Array]:
	if origin != _region_origin or direction != _region_direction:
		_region_origin = origin
		_region_direction = direction
		_visible_region = _sector.visible_region(origin, direction, reach, sector_degrees, origin)
	return _visible_region


func check_contact(enemy: SlideTrace, player: SlideTrace, frame: int, generation: int) -> void:
	if contacted:
		return
	var circle := _player_shape.shape as CircleShape2D
	for i in range(1, enemy.times.size()):
		for j in range(1, player.times.size()):
			var first := maxf(enemy.times[i - 1], player.times[j - 1])
			var last := minf(enemy.times[i], player.times[j])
			if last <= first:
				continue
			var contact := _first_contact(enemy.at(first), enemy.at(last), player.at(first), player.at(last), circle.radius)
			if contact != null:
				contacted = true
				contact.time = lerpf(first, last, contact.time)
				contact.earliest_possible = lerpf(first, last, contact.earliest_possible)
				contact.enemy = _body.name
				contact.execution_id = execution
				contact.frame = frame
				contact.generation = generation
				contact.damage = damage
				contact.flash_strength = flash_strength
				contact.flash_seconds = flash_seconds
				contact.emphasis_seconds = emphasis_seconds
				contact_registered.emit(_player, contact)
				return


func _contact_at(time: float, earliest_possible: float) -> Contact:
	var contact := Contact.new()
	contact.time = time
	contact.earliest_possible = earliest_possible
	return contact


func _first_contact(origin: Vector2, end_origin: Vector2, start: Vector2, finish: Vector2, radius: float) -> Contact:
	var relative_start := start - origin
	var relative_end := finish - end_origin
	if origin == end_origin:
		var entry := Sector.first_touch(_region_at(origin, committed), relative_start, relative_end, radius)
		return _contact_at(entry, entry) if entry != INF else null
	var nearest := relative_start
	if relative_start != relative_end:
		nearest = Geometry2D.get_closest_point_to_segment(Vector2.ZERO, relative_start, relative_end)
	if nearest.length() > reach + radius:
		return null
	# Both traces are linear here. Test the moving disk continuously against
	# the region guaranteed visible over each half-pixel of attacker travel.
	var parts := ceili(origin.distance_to(end_origin) / 0.5)
	var sector: Array[PackedVector2Array] = [Sector.outline(committed, reach, sector_degrees)]
	for k in parts:
		var low := float(k) / parts
		var high := float(k + 1) / parts
		var a := origin.lerp(end_origin, low)
		var b := origin.lerp(end_origin, high)
		var p := relative_start.lerp(relative_end, low)
		var q := relative_start.lerp(relative_end, high)
		var possible := Sector.first_touch(sector, p, q, radius)
		if possible == INF:
			continue
		# If the earliest unoccluded touch is visible at that instant, it
		# is also the exact first contact against the moving shadows.
		var instant := p.lerp(q, possible)
		if Sector.first_touch(_region_at(a.lerp(b, possible), committed), instant, instant, radius) == 0.0:
			var exact := lerpf(low, high, possible)
			return _contact_at(exact, exact)
		var region := _sector.visible_region(a, committed, reach, sector_degrees, b)
		var verified := Sector.first_touch(region, p, q, radius)
		if verified == INF and Sector.first_touch(_region_at(b, committed), q, q, radius) == 0.0:
			verified = 1.0
		if verified != INF:
			return _contact_at(lerpf(low, high, verified), lerpf(low, high, minf(possible, verified)))
	return null


func diagnostics() -> String:
	var readiness := "ready" if _acquired and delay_left == 0.0 else "waiting"
	var lock_direction := "open" if committed == Vector2.ZERO else str(committed.snapped(Vector2.ONE * 0.01))
	if phase == Phase.READY:
		lock_direction = "inactive"
	return "%s %.3fs | initial %s %.3fs | cooldown %.3fs | range %.0f\n    Track %s | lock %s | #%d contact %s\n    Lunge %.1f/%.0f px | paused %.1f ms" % [
		Phase.keys()[phase], remaining, readiness, delay_left, cooldown_left, initiation_radius,
		tracking.snapped(Vector2.ONE * 0.01), lock_direction,
		execution, "yes" if contacted else "no", displacement.length(), lunge, paused_this_tick * 1000,
	]


func _draw() -> void:
	if _body.collision_layer == 0:
		return
	if debug_visible:
		draw_arc(Vector2.ZERO, initiation_radius, 0, TAU, 96, Color(0.55, 0.85, 1, 0.5), 1)
	var warning := ground_warning and phase in [Phase.WIND_UP, Phase.ACTIVE]
	if warning or (debug_visible and phase == Phase.ACTIVE):
		var fill := Color(1.0, 0.42, 0.18, 0.14 if phase == Phase.WIND_UP else 0.28)
		if not ground_warning:
			fill = Color(0.3, 0.85, 1.0, 0.23)
		var edge := Color(1, 0.65, 0.3, 0.65) if ground_warning else Color(0.3, 0.85, 1, 0.7)
		for region in _visible_region:
			draw_colored_polygon(region, fill)
			var outline := region.duplicate()
			outline.append(region[0])
			draw_polyline(outline, edge, 1, true)
	if phase == Phase.READY:
		return
	var heading := tracking if committed == Vector2.ZERO else committed
	var strength := 1.0 - remaining / recovery if phase == Phase.RECOVERY else 0.0
	var cue := Color(1, 0.78, 0.32) if committed == Vector2.ZERO else Color(1, 0.96, 0.74)
	cue.a = 1.0 - strength
	# A silhouette cue stays readable through hit flashes and color overlap.
	var tip := heading * (36.0 if ground_warning else 24.0)
	var wing := heading.orthogonal() * (7.0 if committed != Vector2.ZERO else 4.0)
	draw_polyline(PackedVector2Array([tip - heading * 8 + wing, tip, tip - heading * 8 - wing]), cue, 3, true)
	if debug_visible:
		draw_line(Vector2.ZERO, heading * reach, cue, 1.5)
		if lunge > 0 and committed != Vector2.ZERO:
			draw_line(-displacement, committed * lunge - displacement, Color.AQUA, 2)
