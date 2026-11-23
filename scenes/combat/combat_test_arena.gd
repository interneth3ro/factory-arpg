extends Node2D

const Player = preload("res://scenes/combat/combat_test_player.gd")
const EnemyHealth = preload("res://scenes/combat/enemy_health.gd")
const Sector = preload("res://scenes/combat/enemy_attack_sector.gd")
const HUD_RED := Color(0.84, 0.20, 0.25)

@onready var player: Player = $ArenaObjects/Player
@onready var enemies: Array[EnemyHealth] = [$ArenaObjects/Pursuer, $ArenaObjects/Heavy]
@onready var health_bar: ProgressBar = $Diagnostics/HealthBar
@onready var health_label: Label = $Diagnostics/HealthBar/Value
@onready var death_message: Label = $Diagnostics/Death
@onready var damage_diagnostics: Label = $Diagnostics/DamageLabel
@onready var state_diagnostics: Label = $Diagnostics/StateLabel
@onready var encounter_label: Label = $Diagnostics/Encounter
@onready var style_label: Label = $Diagnostics/CombatStyle
@onready var completion: Label = $Diagnostics/Completion
var encounter_generation := 0
var _solo_enemy: EnemyHealth
var _solids: Array[PackedVector2Array]
var _heavy_map: RID


func _ready() -> void:
	# The two meshes cover the same floor. Isolate their polygon edges while
	# leaving both avoidance participants on the default World2D map.
	_heavy_map = NavigationServer2D.map_create()
	NavigationServer2D.map_set_active(_heavy_map, true)
	$HeavyRegion.set_navigation_map(_heavy_map)
	$HeavyRegion.enabled = true
	$ArenaObjects/Heavy/Movement.set_navigation_map(_heavy_map)
	_solids = Sector.solid_footprints(self)
	player.configure_combat(enemies, _solids)
	for enemy in enemies:
		enemy.movement.bind_player(player, player.motion_trace)
		enemy.attack.bind_player(player.get_node("CollisionShape2D"), player.action_fsm, _solids)
		enemy.defeated.connect(_check_completion)
	player.physics_tick_started.connect(_handle_encounter_input)
	player.style_changed.connect(_update_style_label)
	player.player_health.health_changed.connect(_update_health_hud)
	player.player_health.died.connect(_rest_enemies)
	health_bar.self_modulate = HUD_RED
	_update_health_hud()
	_update_style_label()
	_update_encounter_label()


func _exit_tree() -> void:
	if _heavy_map.is_valid():
		NavigationServer2D.free_rid(_heavy_map)
		_heavy_map = RID()


func _handle_encounter_input() -> void:
	var fresh_configuration := _select_encounter_from_input()
	if fresh_configuration or Input.is_action_just_pressed("reset_combat_test"):
		reset_encounter(fresh_configuration)


func _select_encounter_from_input() -> bool:
	if Input.is_action_just_pressed("combat_test_pursuer_only"):
		_solo_enemy = $ArenaObjects/Pursuer
	elif Input.is_action_just_pressed("combat_test_heavy_only"):
		_solo_enemy = $ArenaObjects/Heavy
	elif Input.is_action_just_pressed("combat_test_combined"):
		_solo_enemy = null
	else:
		return false
	return true


func _update_encounter_label() -> void:
	var configuration := "%s only" % _solo_enemy.name if _solo_enemy else "Pursuer + Heavy"
	encounter_label.text = "Encounter: " + configuration


func reset_encounter(start_with_dagger := false) -> void:
	encounter_generation += 1
	player.reset_combat(encounter_generation, start_with_dagger)
	var targets: Array[EnemyHealth] = []
	for enemy in enemies:
		var participating := _solo_enemy == null or enemy == _solo_enemy
		enemy.reset_encounter(encounter_generation, participating)
		if participating:
			targets.append(enemy)
	player.configure_combat(targets, _solids)
	completion.hide()
	_update_encounter_label()


func _rest_enemies() -> void:
	for enemy in enemies:
		enemy.rest_after_player_death()


func _check_completion() -> void:
	completion.visible = enemies.all(func(enemy: EnemyHealth) -> bool:
		return not enemy.is_encounter_active() or enemy.health == 0)


func _update_health_hud() -> void:
	health_bar.max_value = player.player_health.max_health
	health_bar.value = player.player_health.health
	health_label.text = "%d / %d" % [player.player_health.health, player.player_health.max_health]
	death_message.visible = player.player_health.health == 0


func _update_style_label() -> void:
	style_label.text = "Style: " + Player.style_name(player.active_style)
	if player.pending_style != Player.Style.NONE:
		style_label.text += "   |   Pending: " + Player.style_name(player.pending_style)


func _process(_delta: float) -> void:
	health_bar.self_modulate = HUD_RED.lerp(Color.WHITE, player.damage_emphasis())
	_update_state_diagnostics()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_combat_debug"):
		state_diagnostics.visible = not state_diagnostics.visible
		damage_diagnostics.visible = state_diagnostics.visible
		player.melee_sweep.visible = state_diagnostics.visible
		for enemy in enemies:
			enemy.attack.debug_visible = state_diagnostics.visible
			enemy.attack.queue_redraw()
		_update_state_diagnostics()


func _update_state_diagnostics() -> void:
	if state_diagnostics.visible:
		var dodge_status := "Available" if player.movement_fsm.can_dodge() else "Recovering"
		if player.player_health.health == 0:
			dodge_status = "Disabled"
		elif player.movement_fsm.is_dodging():
			dodge_status = "In progress"
		state_diagnostics.text = "Movement: %s\nAction / phase: %s\nWeapon: %s\nAttack count: %d\nAttack aim: %s\nOrdinary speed: %.2fx\nDodge: %s\nInvulnerability: %s" % [
			player.movement_fsm.get_state_name(),
			player.action_fsm.get_state_name(),
			player.action_fsm.weapon.display_name if Player.MELEE_WEAPONS.has(player.active_style) else "Pistol",
			player.action_fsm.attack_count,
			String(Player.ActionFSM.AimState.keys()[player.action_fsm.get_aim_state()]).capitalize(),
			Player.PistolFiring.MOVEMENT if player.pistol.commitment > 0.0 else player.action_fsm.get_movement_multiplier(),
			dodge_status,
			"Active" if player.is_invulnerable() else "Inactive",
		]
		state_diagnostics.text += "\nContacts (%d): %s\nSweep overlay: On" % [
			player.melee_sweep.contacts.size(), ", ".join(player.melee_sweep.contacts.values()) if not player.melee_sweep.contacts.is_empty() else "None",
		]
		state_diagnostics.text += "\nPistol: %d shots | %d in flight | commit %.0f ms | ready in %.0f ms" % [
			player.pistol.shots_fired, player.projectiles.bullets.size(), player.pistol.commitment * 1000.0, player.pistol.cooldown * 1000.0,
		]

		for enemy in enemies:
			if not enemy.is_encounter_active():
				state_diagnostics.text += "\n%s: Inactive" % enemy.name
				continue
			state_diagnostics.text += "\n%s: %d/%d HP (%s)" % [
				enemy.name, enemy.health, enemy.max_health, "Alive" if enemy.health > 0 else "Defeated",
			]
			state_diagnostics.text += "\n    " + enemy.movement.diagnostics()
			state_diagnostics.text += "\n    " + enemy.attack.diagnostics()
		state_diagnostics.text += "\nLast damage: %s\nHitstop: %.0f ms remaining" % [
			player.last_damage, player.action_fsm.hitstop_remaining * 1000.0,
		]
		if player.action_fsm.last_hitstop_attack > 0:
			state_diagnostics.text += " (last %.0f ms on #%d)" % [
				player.action_fsm.last_hitstop_duration * 1000.0, player.action_fsm.last_hitstop_attack,
			]
		damage_diagnostics.text = "Player %d / %d HP  |  %s  |  I-frames %s\nEnemy contacts (oldest first)\n%s" % [
			player.player_health.health, player.player_health.max_health, "DEAD" if player.player_health.health == 0 else "ALIVE",
			"on" if player.is_invulnerable() else "off",
			"None" if player.player_health.history.is_empty() else "\n".join(player.player_health.history),
		]
