extends Node

const EnemyAttack = preload("res://scenes/combat/enemy_attack.gd")
const MovementFSM = preload("res://scenes/combat/player_movement_fsm.gd")

signal health_changed
signal damaged(contact: EnemyAttack.Contact)
signal died

@export_range(1, 1000) var max_health := 100
@onready var health := max_health
@onready var _movement: MovementFSM = $"../MovementFSM"
var history := PackedStringArray()


func resolve(contact: EnemyAttack.Contact) -> void:
	var outcome := "IGNORED (DEAD)"
	var applied := 0
	if health > 0:
		var protected_at_contact := _movement.was_invulnerable_at(contact.frame, contact.time)
		if not protected_at_contact and contact.shadow_miss_time >= 0.0 and contact.shadow_miss_time < contact.time:
			# The verified touch is vulnerable. Favor protection only when
			# the clipped miss and touch fall on opposite sides of expiry.
			protected_at_contact = _movement.was_invulnerable_at(contact.frame, contact.shadow_miss_time)
		if protected_at_contact:
			outcome = "BLOCKED (DODGE)"
		else:
			applied = mini(contact.damage, health)
			health -= applied
			outcome = "APPLIED (vulnerable)"
	var lethal := applied > 0 and health == 0
	history.append("Tick %d  +%.4f ms  %s #%d\n    %s  −%d  → %d HP%s" % [
		contact.frame, contact.time * 1000.0, contact.enemy, contact.execution_id,
		outcome, applied, health, "  LETHAL" if lethal else "",
	])
	if history.size() > 5:
		history.remove_at(0)
	if applied > 0:
		health_changed.emit()
		if lethal:
			died.emit()
		else:
			damaged.emit(contact)


func reset_encounter() -> void:
	history.clear()
	health = max_health
	health_changed.emit()
