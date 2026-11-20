extends Resource

enum AimMode { LOCK_AT_ACTIVE, CORRECT_ACTIVE, LOCK_DURING_WIND_UP }

@export var display_name: String
@export_range(1, 1000) var damage := 10
@export_range(0.0, 0.2, 0.001, "suffix:s") var hitstop := 0.025
@export_range(0.01, 0.5, 0.01, "suffix:s") var flash_duration := 0.07
@export_range(0.0, 1.0) var flash_strength := 0.35
@export_range(1.0, 300.0, 1.0, "suffix:px") var reach := 85.0
@export_range(1.0, 360.0, 1.0, "suffix:deg") var sweep_angle := 110.0
@export_range(1.0, 100.0, 1.0, "suffix:px") var contact_width := 16.0
@export_range(0.01, 5.0, 0.01, "suffix:s") var wind_up: float = 0.1
@export_range(0.01, 5.0, 0.01, "suffix:s") var active: float = 0.1
@export_range(0.01, 5.0, 0.01, "suffix:s") var recovery: float = 0.2

@export_range(0.0, 1.0) var wind_up_movement: float = 1.0
@export_range(0.0, 1.0) var active_movement: float = 1.0
@export_range(0.0, 1.0) var recovery_movement: float = 1.0
@export var aim_mode: AimMode = AimMode.LOCK_AT_ACTIVE
@export_range(0.0, 720.0, 1.0, "suffix:deg/s") var correction_speed: float = 180.0
@export_range(0.0, 1.0) var wind_up_lock_fraction: float = 0.75
