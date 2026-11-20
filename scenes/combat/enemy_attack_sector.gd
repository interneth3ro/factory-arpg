extends RefCounted

## The arena's static collision footprints are convex. Project each footprint
## away from the attacker and subtract its entire shadow from the sector.
## Both rendering and intersection consume the resulting polygons.
var _solids: Array[PackedVector2Array] = []


func read_arena(tree: SceneTree) -> void:
	for body in tree.get_nodes_in_group("arena_solid"):
		for child in body.get_children():
			var outline := PackedVector2Array()
			if child is CollisionPolygon2D and not child.disabled:
				outline = child.polygon
			elif child is CollisionShape2D and not child.disabled and child.shape is RectangleShape2D:
				var half_size: Vector2 = child.shape.size * 0.5
				outline = PackedVector2Array([ -half_size, Vector2(half_size.x, -half_size.y),
					half_size, Vector2(-half_size.x, half_size.y) ])
			if outline.size() >= 3:
				_solids.append(child.global_transform * outline)


func visible_region(origin: Vector2, direction: Vector2, reach: float, degrees: float, end_origin: Vector2) -> Array[PackedVector2Array]:
	var arc := PackedVector2Array([Vector2.ZERO])
	# Inscribed chords of at most 3 degrees. The Heavy's largest radial
	# difference is under 0.04 px, identical for warning and contact.
	var count := ceili(degrees / 3.0)
	for i in count + 1:
		arc.append(direction.rotated(deg_to_rad(degrees * (float(i) / count - 0.5))) * reach)
	var regions: Array[PackedVector2Array] = [arc]
	for solid in _solids:
		# In the translating attack's coordinates the solid sweeps a convex
		# hull. Its shadow is blocked for this entire short movement interval.
		var footprint := PackedVector2Array()
		for vertex in solid:
			footprint.append(vertex - origin)
			if end_origin != origin:
				footprint.append(vertex - end_origin)
		if end_origin != origin:
			footprint = Geometry2D.convex_hull(footprint)
			footprint.resize(footprint.size() - 1)
		var distance := INF
		for i in footprint.size():
			var near := Geometry2D.get_closest_point_to_segment(Vector2.ZERO, footprint[i - 1], footprint[i])
			distance = minf(distance, near.length())
		if distance > reach:
			continue
		if distance <= 0.0001 or Geometry2D.is_point_in_polygon(Vector2.ZERO, footprint):
			return []
		var shadow := footprint.duplicate()
		for vertex in footprint:
			shadow.append(vertex * ((reach + 1.0) / distance))
		shadow = Geometry2D.convex_hull(shadow)
		shadow.resize(shadow.size() - 1)
		var clipped: Array[PackedVector2Array] = []
		for region in regions:
			clipped.append_array(Geometry2D.clip_polygons(region, shadow))
		regions = clipped
	return regions


static func touches(regions: Array[PackedVector2Array], start: Vector2, finish: Vector2, radius: float) -> bool:
	for region in regions:
		if Geometry2D.is_point_in_polygon(start, region) or Geometry2D.is_point_in_polygon(finish, region):
			return true
		for i in region.size():
			var a := region[i - 1]
			var b := region[i]
			if start == finish:
				if Geometry2D.get_closest_point_to_segment(start, a, b).distance_squared_to(start) <= radius * radius:
					return true
			else:
				var pair := Geometry2D.get_closest_points_between_segments(start, finish, a, b)
				if pair[0].distance_squared_to(pair[1]) <= radius * radius:
					return true
	return false
