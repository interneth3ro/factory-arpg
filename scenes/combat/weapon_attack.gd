extends Resource

@export var display_name: String
@export_range(0.01, 5.0, 0.01, "suffix:s") var wind_up: float = 0.1
@export_range(0.01, 5.0, 0.01, "suffix:s") var active: float = 0.1
@export_range(0.01, 5.0, 0.01, "suffix:s") var recovery: float = 0.2
