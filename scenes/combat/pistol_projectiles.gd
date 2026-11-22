extends Node2D

const Geometry = preload("res://scenes/combat/enemy_attack_sector.gd")
const Enemy = preload("res://scenes/combat/enemy_health.gd")
const SPEED := 1000.0
const RANGE := 600.0
const MUZZLE := 20.0
const RADIUS := 4.0
const SPARK_TIME := 0.075

class Bullet:
	var muzzle: Vector2
	var direction: Vector2
	var traveled := 0.0
	var generation: int
	var id: int

	func center() -> Vector2:
		return muzzle + direction * traveled

class Contact:
	var bullet: Bullet
	var distance: float
	var target: Enemy
	var point: Vector2

	func precedes(other: Contact) -> bool:
		if distance != other.distance:
			return distance < other.distance
		if bullet.id != other.bullet.id:
			return bullet.id < other.bullet.id
		if target == null or other.target == null:
			return target == null and other.target != null
		return String(target.name) < String(other.target.name)

class Spark:
	var point: Vector2
	var left := SPARK_TIME

var bullets: Array[Bullet] = []
var sparks: Array[Spark] = []
var _solids: Array[PackedVector2Array]
var _enemies: Array[Enemy]
var _damage: Callable
var _generation := 0
var _live := true
var _next_id := 0


func configure(enemies: Array[Enemy], damage: Callable) -> void:
	_solids = Geometry.solid_footprints(get_tree())
	_enemies = enemies
	_damage = damage


func clear(generation: int, live: bool) -> void:
	_generation = generation
	_live = live
	_next_id = 0
	bullets.clear()
	sparks.clear()
	queue_redraw()


func launch(origin: Vector2, direction: Vector2, generation: int) -> void:
	if not _live or generation != _generation:
		return
	var bullet := Bullet.new()
	bullet.generation = generation
	_next_id += 1
	bullet.id = _next_id
	bullet.direction = direction
	bullet.muzzle = origin + direction * MUZZLE
	bullets.append(bullet)
	var hits: Array[Contact] = []
	_sweep(bullet, origin, bullet.muzzle, MUZZLE, hits)
	_resolve(hits)
	queue_redraw()


func advance(delta: float) -> void:
	if bullets.is_empty() or delta <= 0.0:
		return
	var hits: Array[Contact] = []
	for bullet in bullets:
		var start := bullet.center()
		var previous := bullet.traveled
		bullet.traveled = minf(RANGE, bullet.traveled + SPEED * delta)
		_sweep(bullet, start, bullet.center(), bullet.traveled - previous, hits)
	_resolve(hits)
	for i in range(bullets.size() - 1, -1, -1):
		if bullets[i].traveled >= RANGE:
			bullets.remove_at(i)
	queue_redraw()


func _sweep(bullet: Bullet, start: Vector2, finish: Vector2, length: float, hits: Array[Contact]) -> void:
	var solid_fraction := Geometry.first_touch(_solids, start, finish, RADIUS)
	if solid_fraction != INF:
		var wall := Contact.new()
		wall.bullet = bullet
		wall.distance = solid_fraction * length
		hits.append(wall)
	for enemy in _enemies:
		if enemy.health == 0 or not enemy.is_encounter_active():
			continue
		var disk := enemy.damage_shape
		var shape := disk.shape as CircleShape2D
		var radius := shape.radius * disk.global_transform.x.length()
		var distance := _disk_entry(start, bullet.direction, disk.global_position, radius + RADIUS)
		if distance > length:
			continue
		# Compare fractions before converting a wall fraction back to pixels.
		# A multiply/divide round trip must not reverse an exact cover tie.
		if solid_fraction == 0.0 or (length > 0.0 and distance / length >= solid_fraction):
			continue
		var hit := Contact.new()
		hit.bullet = bullet
		hit.distance = distance
		hit.target = enemy
		var normal := disk.global_position.direction_to(start + bullet.direction * distance)
		hit.point = disk.global_position + normal * radius
		hits.append(hit)


static func _disk_entry(start: Vector2, direction: Vector2, center: Vector2, radius: float) -> float:
	var offset := center - start
	if offset.length_squared() <= radius * radius:
		return 0.0
	var lateral := offset.cross(direction)
	var chord_squared := radius * radius - lateral * lateral
	if chord_squared < 0.0:
		return INF
	var entry := offset.dot(direction) - sqrt(chord_squared)
	return entry if entry >= 0.0 else INF


func _resolve(hits: Array[Contact]) -> void:
	# All shots travel at equal speed. Distance within this slice orders
	# impacts in time, even if an older bullet defeats a nearer candidate.
	hits.sort_custom(func(a: Contact, b: Contact) -> bool: return a.precedes(b))
	for hit in hits:
		if not _live or hit.bullet.generation != _generation or not bullets.has(hit.bullet):
			continue
		if hit.target != null:
			if not _damage.call(hit.target, hit.bullet.id, hit.bullet.generation):
				continue
			var spark := Spark.new()
			spark.point = hit.point
			sparks.append(spark)
		bullets.erase(hit.bullet)


func _process(delta: float) -> void:
	if sparks.is_empty():
		return
	for i in range(sparks.size() - 1, -1, -1):
		sparks[i].left -= delta
		if sparks[i].left <= 0.0:
			sparks.remove_at(i)
	queue_redraw()


func _draw() -> void:
	for bullet in bullets:
		var point := to_local(bullet.center())
		draw_line(point - bullet.direction * 9.0, point, Color.GOLD, 3.0, true)
		draw_circle(point, 2.0, Color.WHITE)
	for spark in sparks:
		var point := to_local(spark.point)
		var opacity := spark.left / SPARK_TIME
		for i in 4:
			var axis := Vector2.RIGHT.rotated(PI * (0.25 + i * 0.5))
			draw_line(point + axis * 2.0, point + axis * (8.0 - opacity * 3.0), Color(1, 0.84, 0.44, opacity), 1.5, true)
