extends Node

const GameSessionRoot = preload("res://scenes/game/game_session_root.gd")
const SESSION_PATH := "res://scenes/game/game_session_root.tscn"

enum State { INACTIVE, STARTING, ACTIVE, ENDING }

@onready var entry_screen: Control = $EntryUI/EntryScreen
@onready var start_button: Button = $EntryUI/EntryScreen/Choices/StartSession
@onready var end_button: Button = $EntryUI/EndSession
@onready var error_label: Label = $EntryUI/EntryScreen/Choices/ErrorMessage

var _state := State.INACTIVE
var _active_session: GameSessionRoot


func _ready() -> void:
	start_button.grab_focus()


func start_session() -> void:
	if _state != State.INACTIVE:
		return
	_state = State.STARTING
	start_button.disabled = true
	error_label.hide()

	var scene := load(SESSION_PATH) as PackedScene
	var candidate: Node = scene.instantiate() if scene != null else null
	var session := candidate as GameSessionRoot
	if session == null or not session.initialize():
		if candidate != null:
			candidate.free()
		error_label.show()
		_show_entry()
		return

	add_child(session)
	_active_session = session
	entry_screen.hide()
	end_button.show()
	_state = State.ACTIVE
	# Gameplay receives Space immediately. Tab can still focus End Session.
	start_button.release_focus()


func end_session() -> void:
	if _state != State.ACTIVE:
		return
	_state = State.ENDING
	end_button.hide()
	# The button belongs to the permanent UI, outside the subtree being freed.
	_active_session.teardown()
	_active_session.free()
	_active_session = null
	_show_entry()


func _show_entry() -> void:
	entry_screen.show()
	start_button.disabled = false
	_state = State.INACTIVE
	start_button.grab_focus()
