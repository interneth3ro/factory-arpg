extends NavigationAgent2D

const EnemyAttack = preload("res://scenes/combat/enemy_attack.gd")
const SlideTrace = preload("res://scenes/combat/slide_trace.gd")

enum State { IDLE, PURSUING, HOLDING, RETREATING, WAITING_FOR_PATH, DEFEATED, RESTING, INACTIVE }

const ENVIRONMENT_MASK := 1 << 2
const RETREAT_ANGLES := [0.0, 30.0, -30.0, 55.0, -55.0]
const ENDPOINT_EPSILON := 0.5

@export var detection_distance := 240.0
@export var disengage_distance := 380.0
@export var stop_distance := 55.0
@export var resume_distance := 75.0
@export var retreat_distance := 35.0
@export var repath_interval := 0.15
@export var acceleration := 1800.0
@export var deceleration := 2200.0
@export var destination_change := 6.0
@export var retreat_improvement := 6.0
@export var peer: CharacterBody2D

@onready var _body: CharacterBody2D = get_parent()
var _player: CharacterBody2D
@onready var _avoidance: NavigationAgent2D = $"../Avoidance"
@onready var _attack: EnemyAttack = $"../Attack"
var _player_trace: SlideTrace

var state := State.IDLE
var _retry_in := 0.0
var _has_target := false
var _path_status := "none"
var _reset_frame := -1
var _moving := false
var _speed := 0.0
var _waypoint := Vector2.ZERO
var _blocking_normal := Vector2.ZERO
var _command_frame := -1
var _generation := 0
var _command_generation := -1
var _tick_delta := 0.0
var _navigation_submitted := false
var _lunge_trace := SlideTrace.new()


func _ready() -> void:
	var collider: CollisionShape2D = _body.get_node("CollisionShape2D")
	var shape := collider.shape as CircleShape2D
	_avoidance.radius = shape.radius
	_avoidance.max_speed = max_speed
	_avoidance.avoidance_enabled = true
	_avoidance.velocity_computed.connect(_move_with_safe_velocity)
	_attack.active_interval.connect(_strike)
	_attack.standstill_requested.connect(_stand_still)
	_attack.recovery_finished.connect(_after_recovery)


func bind_player(player: CharacterBody2D, trace: SlideTrace) -> void:
	_player = player
	_player_trace = trace


func defeat() -> void:
	_attack.reset_encounter()
	_clear_motion(State.DEFEATED)
	_avoidance.avoidance_enabled = false


func rest() -> void:
	_attack.cancel_execution()
	_clear_motion(State.RESTING)
	_avoidance.avoidance_enabled = false


func reset_encounter(generation: int, participating := true) -> void:
	_generation = generation
	_attack.reset_encounter()
	_clear_motion(State.IDLE if participating else State.INACTIVE)
	_reset_frame = Engine.get_physics_frames()
	_avoidance.avoidance_enabled = participating
	if participating:
		NavigationServer2D.agent_set_velocity_forced(_avoidance.get_rid(), Vector2.ZERO)


func _clear_motion(next: State) -> void:
	_command_frame = -1
	_navigation_submitted = false
	_change_state(next)
	_waypoint = _body.global_position
	_blocking_normal = Vector2.ZERO
	_moving = false
	_speed = 0.0
	_body.velocity = Vector2.ZERO
	NavigationServer2D.agent_set_velocity(_avoidance.get_rid(), Vector2.ZERO)
	_avoidance.avoidance_priority = 1.0


func _change_state(next: State) -> void:
	if next in [State.IDLE, State.DEFEATED, State.HOLDING, State.RESTING, State.INACTIVE]:
		# Setting a target resets the native path result. Park at this pose
		# until a new movement order arrives, including after an F5 teleport.
		target_position = _body.global_position
	_has_target = false
	_path_status = "none"
	_retry_in = 0.0
	state = next


func _has_sight() -> bool:
	var query := PhysicsRayQueryParameters2D.create(_body.global_position, _player.global_position, ENVIRONMENT_MASK)
	return _body.get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _physics_process(delta: float) -> void:
	if state in [State.DEFEATED, State.RESTING, State.INACTIVE] or Engine.get_physics_frames() == _reset_frame:
		return
	_attack.start_tick(delta)
	_retry_in = maxf(0.0, _retry_in - delta)
	var distance := _body.global_position.distance_to(_player.global_position)
	if state == State.IDLE:
		if distance > detection_distance or not _has_sight():
			_attack.advance_wait(delta - _attack.paused_this_tick)
			return
		_change_state(State.PURSUING)
		_attack.acquire()
	elif _attack.phase == EnemyAttack.Phase.READY and distance > disengage_distance:
		_attack.disengage()
		_clear_motion(State.IDLE)
		_attack.advance_wait(delta - _attack.paused_this_tick)
		return
	_tick_delta = delta
	_command_frame = Engine.get_physics_frames()
	_command_generation = _generation
	_navigation_submitted = false
	# A recovery that finishes inside this tick can use a fresh avoidance
	# result for its ordinary tail. The body is stationary at this pose.
	var ordinary := 0.0
	match _attack.phase:
		EnemyAttack.Phase.READY:
			ordinary = delta
			if _attack.in_range_and_visible(_has_sight):
				ordinary = minf(delta, _attack.paused_this_tick + _attack.wait_time())
		EnemyAttack.Phase.RECOVERY:
			if distance <= disengage_distance:
				ordinary = delta - _attack.paused_this_tick - _attack.remaining
	if ordinary > 0.0:
		_prepare_navigation(distance, ordinary)
		_navigation_submitted = true
	else:
		# Advertise only the committed motion to the peer's avoidance agent.
		# The lunging body itself follows the committed vector through physics.
		var strike_time := _attack.active_time_in(delta - _attack.paused_this_tick)
		var velocity_request := _attack.committed * (_attack.lunge / _attack.active) * strike_time / delta
		NavigationServer2D.agent_set_velocity(_avoidance.get_rid(), velocity_request)
		_avoidance.avoidance_priority = 1.0


func _prepare_navigation(distance: float, delta: float) -> void:
	# A nearby player on the opposite side of a wall still needs a route.
	var spacing_visible := distance <= resume_distance and _has_sight()
	var direction := _engagement_direction(distance, spacing_visible)
	if direction.dot(_blocking_normal) < -0.95:
		if state == State.RETREATING:
			direction = _hold_after_retreat("retreat obstructed")
		else:
			direction = _wait_for_path("obstructed")
	_submit_velocity(direction, distance, spacing_visible, delta)


func _engagement_direction(distance: float, spacing_visible: bool) -> Vector2:
	if not spacing_visible:
		return _pursue()
	if distance < retreat_distance or (state == State.RETREATING and distance < stop_distance):
		return _retreat(distance)
	if distance <= stop_distance or state == State.HOLDING or state == State.RETREATING:
		if state != State.HOLDING or _path_status != "none":
			_change_state(State.HOLDING)
		return Vector2.ZERO
	return _pursue()


func _submit_velocity(direction: Vector2, distance: float, spacing_visible: bool, delta: float) -> void:
	var to_waypoint := _body.global_position.distance_to(_waypoint)
	var speed_limit := minf(max_speed, sqrt(2.0 * acceleration * to_waypoint))
	if state == State.PURSUING and spacing_visible:
		speed_limit = minf(speed_limit, sqrt(2.0 * deceleration * maxf(distance - stop_distance, 1.0)))
	if state == State.RETREATING:
		speed_limit = minf(speed_limit, sqrt(2.0 * deceleration * maxf(stop_distance - distance, 1.0)))
	var desired := _passing_direction(direction) * speed_limit
	var rate := deceleration if desired.length_squared() < _body.velocity.length_squared() else acceleration
	var preferred := _body.velocity.move_toward(desired, rate * delta)
	# Waiting at a path endpoint or a blocked retreat must not coast into it.
	if state == State.WAITING_FOR_PATH or (state == State.HOLDING and _path_status != "none"):
		preferred = Vector2.ZERO
	_moving = not preferred.is_zero_approx()
	_avoidance.avoidance_priority = 0.5 if _moving else 1.0
	# Godot 4.7.2 only forwards node velocity when that node has a path target.
	# This sibling handles avoidance only, so submit to its server agent directly.
	NavigationServer2D.agent_set_velocity(_avoidance.get_rid(), preferred)


func _map_ready() -> bool:
	return NavigationServer2D.map_get_iteration_id(get_navigation_map()) > 0


func _pursue() -> Vector2:
	if state != State.PURSUING and state != State.WAITING_FOR_PATH:
		_change_state(State.PURSUING)
	if state == State.WAITING_FOR_PATH and _retry_in > 0.0:
		return Vector2.ZERO
	if _retry_in <= 0.0:
		_retry_in = repath_interval
		if not _map_ready():
			return _wait_for_path("map syncing")
		var player_position := _player.global_position
		var retry := state == State.WAITING_FOR_PATH or _path_status == "partial"
		if not _has_target or retry or target_position.distance_to(player_position) >= destination_change:
			target_position = player_position
			_has_target = true
		state = State.PURSUING
	_waypoint = get_next_path_position()
	var path := get_current_navigation_path()
	if path.size() < 2 or get_path_length() < ENDPOINT_EPSILON:
		return _wait_for_path("unreachable")
	var endpoint := path[path.size() - 1]
	var complete := is_target_reachable() and endpoint.distance_to(target_position) <= ENDPOINT_EPSILON
	_path_status = "complete" if complete else "partial"
	if is_navigation_finished() or _body.global_position.distance_to(endpoint) <= target_desired_distance:
		return _wait_for_path("at target" if complete else "partial endpoint")
	return _body.global_position.direction_to(_waypoint)


func _wait_for_path(reason: String) -> Vector2:
	state = State.WAITING_FOR_PATH
	_path_status = reason
	return Vector2.ZERO


func _retreat(distance: float) -> Vector2:
	if state != State.RETREATING:
		if state == State.HOLDING and _retry_in > 0.0:
			return Vector2.ZERO
		_change_state(State.RETREATING)
	if _retry_in <= 0.0:
		_retry_in = repath_interval
		if not _has_target or target_position.distance_to(_player.global_position) < distance + retreat_improvement:
			if not _choose_retreat_target(distance):
				return _hold_after_retreat("retreat blocked")
	_waypoint = get_next_path_position()
	if is_navigation_finished():
		return _hold_after_retreat("retreat endpoint")
	if get_current_navigation_path().size() < 2 or not is_target_reachable():
		return _hold_after_retreat("retreat blocked")
	_path_status = "complete"
	return _body.global_position.direction_to(_waypoint)


func _choose_retreat_target(distance: float) -> bool:
	if not _map_ready():
		return false
	var origin := _body.global_position
	var away := _player.global_position.direction_to(origin)
	if away.is_zero_approx():
		away = Vector2.RIGHT
	var best_gain := 0.0
	var destination := origin
	for angle: float in RETREAT_ANGLES:
		var offset := away.rotated(deg_to_rad(angle)) * (stop_distance - distance + retreat_improvement)
		var path := NavigationServer2D.map_get_path(get_navigation_map(), origin, origin + offset, true, navigation_layers)
		if path.size() < 2:
			continue
		var end := path[path.size() - 1]
		var travel := 0.0
		for index in range(1, path.size()):
			travel += path[index - 1].distance_to(path[index])
		var gain := end.distance_to(_player.global_position) - distance
		# A projected endpoint can work along a wall. Reject long detours and
		# paths that initially lead back towards the player.
		var first_leg := origin.direction_to(path[1])
		if first_leg.dot(_blocking_normal) < -0.95:
			continue
		if gain < retreat_improvement or travel > gain * 2.0 or first_leg.dot(away) <= 0.0:
			continue
		if gain > best_gain:
			destination = end
			best_gain = gain
			if distance + gain >= stop_distance:
				break
	if best_gain == 0.0:
		return false
	target_position = destination
	_has_target = true
	return true


func _hold_after_retreat(reason: String) -> Vector2:
	_change_state(State.HOLDING)
	_path_status = reason
	_retry_in = repath_interval
	return Vector2.ZERO


func _passing_direction(direction: Vector2) -> Vector2:
	if direction.is_zero_approx() or peer.collision_layer == 0:
		return direction
	# Break the symmetric head-on case for RVO. Bias only when the other
	# solid body lies directly ahead, always to the mover's own right.
	var offset := peer.global_position - _body.global_position
	if offset.length() < _avoidance.neighbor_distance and direction.dot(offset.normalized()) > 0.90:
		return (direction + direction.rotated(PI / 2.0) * 0.25).normalized()
	return direction


func _move_with_safe_velocity(safe_velocity: Vector2) -> void:
	if _command_frame != Engine.get_physics_frames() or _command_generation != _generation:
		return
	_command_frame = -1 # Each submission can move the body only once.
	_speed = 0.0
	_attack.advance_tick(_tick_delta, _has_sight, _move_navigation.bind(safe_velocity))


func _stand_still() -> void:
	_clear_motion(State.HOLDING)
	NavigationServer2D.agent_set_velocity_forced(_avoidance.get_rid(), Vector2.ZERO)


func _after_recovery() -> void:
	if _body.global_position.distance_to(_player.global_position) > disengage_distance:
		_attack.disengage()
		_clear_motion(State.IDLE)


func _move_navigation(duration: float, safe_velocity: Vector2) -> void:
	if duration <= 0.0 or not _navigation_submitted:
		return
	if not _moving:
		_body.velocity = Vector2.ZERO
		_speed = 0.0
		return
	var start := _body.global_position
	_move(safe_velocity.limit_length(max_speed), duration)
	var motion := _body.global_position - start
	_attack.face_motion(-motion if state == State.RETREATING else motion)
	_speed = motion.length() / duration
	_update_blocking_normal()


func _move(velocity_request: Vector2, duration: float) -> void:
	# move_and_slide integrates a full physics delta, even for a phase slice.
	var fraction := duration / _tick_delta
	_body.velocity = velocity_request * fraction
	_body.move_and_slide()
	_body.velocity /= fraction


func _strike(from: float, duration: float) -> void:
	var origin := _body.global_position
	var travel_time := 0.0
	if _attack.lunge > 0.0:
		var velocity_request := _attack.committed * (_attack.lunge / _attack.active)
		var hit := KinematicCollision2D.new()
		travel_time = duration
		if _body.test_move(_body.global_transform, velocity_request * duration, hit):
			travel_time = clampf(hit.get_travel().dot(_attack.committed) / velocity_request.length(), 0, duration)
		if travel_time > 0.0:
			_move(velocity_request, travel_time)
	_attack.displacement += _body.global_position - origin
	_lunge_trace.record(_body, origin, from, travel_time, from + duration)
	_attack.check_contact(_lunge_trace, _player_trace, Engine.get_physics_frames(), _command_generation)
	_body.velocity = Vector2.ZERO
	_speed = _body.global_position.distance_to(origin) / _tick_delta


func _update_blocking_normal() -> void:
	_blocking_normal = Vector2.ZERO
	if _speed < 1.0:
		for index in _body.get_slide_collision_count():
			var contact := _body.get_slide_collision(index)
			if contact.get_collider() is StaticBody2D:
				_blocking_normal = contact.get_normal()
				break


func diagnostics() -> String:
	var engaged := state not in [State.IDLE, State.DEFEATED, State.RESTING, State.INACTIVE]
	var target := str(target_position.round()) if _has_target else "none"
	return "%s | %s | %.0f px | %.0f px/s\n    Target %s | Path %s" % [
		String(State.keys()[state]).capitalize(), "engaged" if engaged else "inactive",
		_body.global_position.distance_to(_player.global_position), _speed, target, _path_status,
	]
