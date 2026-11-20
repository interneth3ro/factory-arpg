extends Node2D

signal contacted(target: CollisionObject2D)

const ActionFSM = preload("res://scenes/combat/player_action_fsm.gd")
const TARGET_MASK := 1 << 1
const MAX_PADDING := 1.0

var contacts: Dictionary[int, String] = {}
var _attack_id := 0
var _debug_poses: Array[Transform2D] = []
var _debug_shapes: Array[CapsuleShape2D] = []


func select_attack(id: int) -> void:
	if id != _attack_id:
		_attack_id = id
		contacts.clear()


func begin_tick() -> void:
	_debug_poses.clear()
	_debug_shapes.clear()
	queue_redraw()


func check_motion(player: CharacterBody2D, start: Vector2, delta: float, intervals: Array[ActionFSM.ActiveInterval]) -> void:
	# The FSM emits intervals in attack order. Finish every leg for this
	# interval before a newer attack can replace its contact history.
	for interval in intervals:
		select_attack(interval.attack_id)
		_check_motion_interval(player, start, delta, interval)


func _check_motion_interval(player: CharacterBody2D, start: Vector2, delta: float, interval: ActionFSM.ActiveInterval) -> void:
	var position_on_path := start
	var time := 0.0
	# Reconstruct the resolved slide legs. The travel/remainder ratio estimates
	# time to impact, including the stationary tail when a wall stops movement.
	for index in player.get_slide_collision_count():
		var hit := player.get_slide_collision(index)
		var travel := hit.get_travel()
		var distance := travel.length() + hit.get_remainder().length()
		if is_zero_approx(distance):
			continue
		var end_time := lerpf(time, delta, travel.length() / distance)
		_check_leg(interval, position_on_path, position_on_path + travel, time, end_time)
		time = end_time
		position_on_path += travel
	_check_leg(interval, position_on_path, player.global_position, time, delta)


func _check_leg(interval: ActionFSM.ActiveInterval, start: Vector2, finish: Vector2, from: float, until: float) -> void:
	var first := maxf(interval.tick_start, from)
	var last := minf(interval.tick_start + interval.duration, until)
	if last <= first:
		return
	var origin := start.lerp(finish, (first - from) / (until - from))
	var end_origin := start.lerp(finish, (last - from) / (until - from))
	_check_interval(interval, origin, end_origin, first, last)


func _check_interval(interval: ActionFSM.ActiveInterval, start: Vector2, finish: Vector2, first: float, last: float) -> void:
	var weapon := interval.weapon
	var angular_speed := deg_to_rad(weapon.sweep_angle) / weapon.active
	if interval.correction != 0.0:
		angular_speed += deg_to_rad(weapon.correction_speed)
	# Every point on the core segment travels at most this distance. Inflating
	# each midpoint capsule by half a substep covers both translation and turn.
	var travel_bound := start.distance_to(finish) + weapon.reach * angular_speed * (last - first)
	var count := maxi(1, ceili(travel_bound / (2.0 * MAX_PADDING)))
	var capsule := CapsuleShape2D.new()
	var radius := weapon.contact_width * 0.5 + travel_bound / (2.0 * count)
	capsule.height = weapon.reach + 2.0 * radius
	capsule.radius = radius
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = capsule
	query.collision_mask = TARGET_MASK
	query.exclude = [(get_parent() as CollisionObject2D).get_rid()]
	var space := get_world_2d().direct_space_state
	for index in count:
		var fraction := (index + 0.5) / count
		var angle := interval.blade_angle(lerpf(first, last, fraction))
		var center := start.lerp(finish, fraction) + Vector2.from_angle(angle) * weapon.reach * 0.5
		query.transform = Transform2D(angle - PI * 0.5, center)
		for hit in space.intersect_shape(query):
			var target := hit.collider as CollisionObject2D
			var id := target.get_instance_id()
			if not contacts.has(id):
				contacts[id] = str(target.name)
				contacted.emit(target)
		if visible:
			_debug_poses.append(query.transform)
			_debug_shapes.append(capsule)


func _draw() -> void:
	for index in _debug_poses.size():
		var pose := global_transform.affine_inverse() * _debug_poses[index]
		draw_set_transform_matrix(pose)
		_debug_shapes[index].draw(get_canvas_item(), Color(0.3, 1.0, 0.78, 0.12))
