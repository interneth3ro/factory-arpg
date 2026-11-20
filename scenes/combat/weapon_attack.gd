extends Resource

enum AimMode { LOCK_AT_ACTIVE, CORRECT_ACTIVE, LOCK_DURING_WIND_UP }

@export var display_name: String
@export_range(0.01, 5.0, 0.01, "suffix:s") var wind_up: float = 0.1
@export_range(0.01, 5.0, 0.01, "suffix:s") var active: float = 0.1
@export_range(0.01, 5.0, 0.01, "suffix:s") var recovery: float = 0.2

@export_range(0.0, 1.0) var wind_up_movement: float = 1.0
@export_range(0.0, 1.0) var active_movement: float = 1.0
@export_range(0.0, 1.0) var recovery_movement: float = 1.0
@export var aim_mode: AimMode = AimMode.LOCK_AT_ACTIVE
@export_range(0.0, 720.0, 1.0, "suffix:deg/s") var correction_speed: float = 180.0
@export_range(0.0, 1.0) var wind_up_lock_fraction: float = 0.75
