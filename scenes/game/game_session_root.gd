extends Node

const Player = preload("res://scenes/combat/combat_test_player.gd")

@export var location_scene: PackedScene

var _active_location: Node
var _player: Player
var _health_label: Label
var _style_label: Label
var _death_message: Label


func initialize() -> bool:
	var host := get_node_or_null("ActiveLocation")
	if _active_location != null or host == null or location_scene == null:
		return false
	_player = get_node_or_null("Player") as Player
	_health_label = get_node_or_null("SessionHUD/Health") as Label
	_style_label = get_node_or_null("SessionHUD/Style") as Label
	_death_message = get_node_or_null("SessionHUD/Death") as Label
	if _player == null or _health_label == null or _style_label == null or _death_message == null:
		return false

	var location := location_scene.instantiate()
	if location == null:
		return false

	host.add_child(location)
	_active_location = location
	return true


func _ready() -> void:
	if _active_location == null:
		return
	_player.configure_combat([], [])
	_player.player_health.health_changed.connect(_update_health)
	_player.style_changed.connect(_update_style)
	_update_health()
	_update_style()


func _update_health() -> void:
	var hp := _player.player_health
	_health_label.text = "HP: %d / %d" % [hp.health, hp.max_health]
	_death_message.visible = hp.health == 0


func _update_style() -> void:
	_style_label.text = "Style: " + Player.style_name(_player.active_style)
	if _player.pending_style != Player.Style.NONE:
		_style_label.text += "   |   Pending: " + Player.style_name(_player.pending_style)


func teardown() -> void:
	if _active_location != null:
		_active_location.free()
		_active_location = null
