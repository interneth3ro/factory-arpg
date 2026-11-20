"""Check the combat arena's static navigation meshes. Pass --write to rebuild.

Authoring dependency: Shapely 2.1.2. The Godot project uses only the saved meshes.
"""

import argparse
import re
from pathlib import Path

from shapely import constrained_delaunay_triangles, union_all
from shapely.geometry import Point, Polygon, box


ARENA = Path(__file__).resolve().parents[1] / "scenes/combat"
MARGIN = 4


def numbers(value):
    return [float(part) for part in value.split("(", 1)[1].rstrip(")").split(",")]


def scene_geometry():
    nodes, resources = {}, {}
    scene = (ARENA / "combat_test_arena.tscn").read_text()
    for header, body in re.findall(r"^\[([^\n]+)\]\n(.*?)(?=^\[|\Z)", scene, re.M | re.S):
        attrs = dict(re.findall(r'(\w+)="([^"]*)"', header))
        props = dict(line.split(" = ", 1) for line in body.splitlines() if " = " in line)
        if header.startswith("sub_resource "):
            resources[attrs["id"]] = props
        elif header.startswith("node "):
            parent = attrs.get("parent")
            path = attrs["name"] if parent == "." else f"{parent}/{attrs['name']}"
            nodes[path if parent else "."] = (attrs["type"], props)

    def origin(path):
        x = y = 0.0
        while True:
            props = nodes[path][1]
            if {"transform", "scale", "skew", "rotation", "rotation_degrees"} & props.keys():
                raise ValueError(f"Unsupported collider transform on {path}")
            dx, dy = numbers(props.get("position", "Vector2(0, 0)"))
            x, y = x + dx, y + dy
            if path == ".":
                return x, y
            path = path.rpartition("/")[0] or "."

    def shape(props):
        return resources[props["shape"].split('"')[1]]

    walls, blocks = [], []
    for path, (kind, props) in nodes.items():
        parent = path.rpartition("/")[0]
        if not parent or nodes[parent][0] != "StaticBody2D":
            continue
        if kind not in ("CollisionPolygon2D", "CollisionShape2D"):
            continue
        x, y = origin(path)
        if props.get("disabled") == "true":
            continue
        if kind == "CollisionPolygon2D":
            coords = numbers(props["polygon"])
            polygon = Polygon([(x + a, y + b) for a, b in zip(coords[::2], coords[1::2])])
        else:
            w, h = numbers(shape(props)["size"])
            polygon = box(x - w / 2, y - h / 2, x + w / 2, y + h / 2)
        (walls if parent == "Boundaries" else blocks).append(polygon)

    perimeter = union_all(walls)
    if perimeter.geom_type != "Polygon" or len(perimeter.interiors) != 1:
        raise ValueError("Perimeter colliders must enclose one arena floor")
    floor = Polygon(perimeter.interiors[0])
    for enemy in ("Pursuer", "Heavy"):
        path = f"ArenaObjects/{enemy}"
        collider = nodes[f"{path}/CollisionShape2D"][1]
        yield enemy, float(shape(collider)["radius"]), Point(origin(path)), floor, blocks


def vector_array(points):
    return "PackedVector2Array(" + ", ".join(f"{v:g}" for p in points for v in p) + ")"


def mesh_resource(radius, spawn, floor, blocks):
    clearance = radius + MARGIN
    surface = floor.difference(union_all(blocks)).buffer(-clearance, quad_segs=4)
    if surface.geom_type != "Polygon" or not surface.contains(spawn):
        raise ValueError("Spawn or a walkable corridor was disconnected")
    triangles = constrained_delaunay_triangles(surface).geoms
    verts = sorted({(round(x, 3), round(y, 3)) for t in triangles for x, y in t.exterior.coords})
    indices = {point: i for i, point in enumerate(verts)}
    faces = []
    for triangle in triangles:
        ring = triangle.exterior
        coords = list(ring.coords)[:-1]
        if ring.is_ccw:
            coords.reverse()
        face = [indices[round(x, 3), round(y, 3)] for x, y in coords]
        first = face.index(min(face))
        faces.append(face[first:] + face[:first])
    mesh = union_all([Polygon([verts[i] for i in face]) for face in faces])
    if mesh.geom_type != "Polygon" or len(mesh.interiors) != len(surface.interiors):
        raise ValueError("Rounded mesh lost a corridor or an obstacle")
    gap = min(mesh.distance(solid) for solid in [floor.boundary, *blocks])
    if gap <= radius:
        raise ValueError(f"Mesh has insufficient physical clearance ({gap:g} px)")
    polygons = ", ".join("PackedInt32Array(%d, %d, %d)" % tuple(f) for f in sorted(faces))
    outline = vector_array(list(floor.simplify(0).exterior.coords)[:-1])
    return (
        '[gd_resource type="NavigationPolygon" format=3]\n\n[resource]\n'
        f'vertices = {vector_array(verts)}\npolygons = [{polygons}]\noutlines = [{outline}]\n'
        'parsed_geometry_type = 1\nparsed_collision_mask = 4\nsource_geometry_mode = 2\n'
        f'source_geometry_group_name = &"arena_solid"\nagent_radius = {clearance:.1f}\n'
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    for enemy, radius, spawn, floor, blocks in scene_geometry():
        resource = ARENA / f"{enemy.lower()}_navigation.tres"
        expected = mesh_resource(radius, spawn, floor, blocks)
        if args.write:
            resource.write_bytes(expected.encode("ascii"))
        if not resource.exists() or resource.read_text() != expected:
            raise SystemExit(f"{resource.name} is stale. Regenerate using --write.")
        print(f"{enemy}: mesh matches physical arena, nominal clearance {radius + MARGIN:g} px")


if __name__ == "__main__":
    main()
