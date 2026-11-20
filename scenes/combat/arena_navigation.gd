extends Node2D

var _heavy_map: RID


func _ready() -> void:
	# The two meshes cover the same floor. Isolate their polygon edges while
	# leaving both avoidance participants on the default World2D map.
	_heavy_map = NavigationServer2D.map_create()
	NavigationServer2D.map_set_active(_heavy_map, true)
	$HeavyRegion.set_navigation_map(_heavy_map)
	$HeavyRegion.enabled = true
	$ArenaObjects/Heavy/Movement.set_navigation_map(_heavy_map)


func _exit_tree() -> void:
	if _heavy_map.is_valid():
		NavigationServer2D.free_rid(_heavy_map)
		_heavy_map = RID()
