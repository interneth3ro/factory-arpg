extends Node

const WeaponAttack = preload("res://scenes/combat/weapon_attack.gd")

@onready var _swing: AudioStreamPlayer = $Swing
@onready var _primary: AudioStreamPlayer = $Primary
@onready var _secondary: AudioStreamPlayer = $Secondary
var _last_swing := 0
var _last_impact := 0


func swing(id: int, weapon: WeaponAttack) -> void:
	if id <= _last_swing:
		return
	_last_swing = id
	_play(_swing, weapon.swing_sound)


func impact(id: int, weapon: WeaponAttack) -> void:
	if id > _last_impact:
		_last_impact = id
		_play(_primary, weapon.impact_sound)
	elif id == _last_impact and not _secondary.playing:
		_play(_secondary, weapon.impact_sound)


func _play(voice: AudioStreamPlayer, recording: AudioStream) -> void:
	if recording:
		# Reassigning the stream stops its other playbacks. A long simulation
		# tick can legitimately start the same weapon more than once.
		if voice.stream != recording:
			voice.stream = recording
		voice.play()


func interrupt_swing() -> void:
	_swing.stop()


func reset() -> void:
	_swing.stop()
	_primary.stop()
	_secondary.stop()
	_last_swing = 0
	_last_impact = 0
