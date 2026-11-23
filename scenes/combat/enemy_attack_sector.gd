extends RefCounted

## The arena's static collision footprints are convex. Project each footprint
## away from the attacker and subtract its entire shadow from the sector.
## Both rendering and intersection consume the resulting polygons.
var solids: Array[PackedVector2Array] = []


static func solid_footprints(arena: Node) -> Array[PackedVector2Array]:
	var footprints: Array[PackedVector2Array] = []
	for body in arena.get_tree().get_nodes_in_group("arena_solid"):
		if not arena.is_ancestor_of(body):
			continue
		for child in body.get_children():
			var outline := PackedVector2Array()
			if child is CollisionPolygon2D and not child.disabled:
				outline = child.polygon
			elif child is CollisionShape2D and not child.disabled and child.shape is RectangleShape2D:
				var half_size: Vector2 = child.shape.size * 0.5
				outline = PackedVector2Array([ -half_size, Vector2(half_size.x, -half_size.y),
					half_size, Vector2(-half_size.x, half_size.y) ])
			if outline.size() >= 3:
				footprints.append(child.global_transform * outline)
	return footprints


static func outline(direction: Vector2, reach: float, degrees: float) -> PackedVector2Array:
	var arc := PackedVector2Array([Vector2.ZERO])
	# Inscribed chords of at most 3 degrees. The Heavy's largest radial
	# difference is under 0.04 px, identical for warning and contact.
	var count := ceili(degrees / 3.0)
	for i in count + 1:
		arc.append(direction.rotated(deg_to_rad(degrees * (float(i) / count - 0.5))) * reach)
	return arc


func visible_region(origin: Vector2, direction: Vector2, reach: float, degrees: float, end_origin: Vector2) -> Array[PackedVector2Array]:
	var regions: Array[PackedVector2Array] = [outline(direction, reach, degrees)]
	for solid in solids:
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


## First entry of a translating disk into the clipped polygons. Outside a
## polygon the expanded boundary consists of offset edges and vertex disks.
static func first_touch(regions: Array[PackedVector2Array], start: Vector2, finish: Vector2, radius: float) -> float:
	var travel := finish - start
	var length := travel.length()
	var direction := travel.normalized()
	var earliest := INF
	for region in regions:
		if Geometry2D.is_point_in_polygon(start, region):
			return 0.0
		for i in region.size():
			var a := region[i - 1]
			var b := region[i]
			if a == b:
				continue
			if Geometry2D.get_closest_point_to_segment(start, a, b).distance_squared_to(start) <= radius * radius:
				return 0.0
			if length == 0.0:
				continue
			var tangent := a.direction_to(b)
			var normal := tangent.orthogonal()
			var offset := (start - a).dot(normal)
			var across := travel.dot(normal)
			if offset * across < 0.0:
				var entry := (signf(offset) * radius - offset) / across
				if entry >= 0.0 and entry <= 1.0 and entry < earliest:
					var along := (start + travel * entry - a).dot(tangent)
					if along >= 0.0 and along <= a.distance_to(b):
						earliest = entry
			var to_vertex := b - start
			var lateral := to_vertex.cross(direction)
			var chord_squared := radius * radius - lateral * lateral
			if chord_squared >= 0.0:
				var entry := (to_vertex.dot(direction) - sqrt(chord_squared)) / length
				if entry >= 0.0 and entry <= 1.0:
					earliest = minf(earliest, entry)
	return earliest
