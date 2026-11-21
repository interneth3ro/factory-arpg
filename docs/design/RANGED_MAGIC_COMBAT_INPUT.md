# Factory ARPG — Ranged, magic, and combat input

**Status:** Approved design for the next standalone combat prototype extension. Implementation and runtime acceptance are pending.

**Engine:** Godot 4.7.2

The extension adds two ways to fight the existing Pursuer and Heavy. One tests aiming a moving projectile while strafing. The other tests placing a persistent area by direction alone. Both share the three melee weapons' primary attack input and dodge. The [decision log](DECISION_LOG.md#ranged-magic-and-combat-input-decisions) registers all 36 decisions. The [frozen melee baseline](COMBAT_PROTOTYPE_V0.1.md) and [completed Phase 1 evaluation](PHASE_1_COMBAT_EVALUATION_RESULTS.md) describe the earlier milestone.

The firing, casting, pulse, switching and reset rules below are approved behavior. Rates, speeds, distances, damage, durations and movement multipliers are approved **initial prototype tuning**, provisional for balance. Use the stated values for first acceptance. Four shared pulses, their ordering, and the limit of one field are behavioral requirements.

## Pistol

**R1–R6.** The physical firearm is a simple semi-automatic pistol with unlimited ammunition. It has no magazine or reload. Each shot launches a traveling bullet along the player's current aim, independent of movement. Sweep the distance actually traveled between physics samples. The first eligible enemy takes one damage event and stops the bullet. A nearer solid obstacle stops it without damaging an enemy behind it. Contact ends the shot, including when multiple targets lie on the same path. Bullets neither penetrate nor ricochet.

**R7–R12.** A press fires immediately when ready. Holding primary repeats at three shots per second (one interval is ⅓ s, approximately 333 ms). A bullet travels at 1,000 px/s for at most 600 px and deals 15 damage. Clip its last sweep to its remaining range. On each shot ordinary movement drops to 80% for 120 ms (176 px/s at the current 220 px/s base speed). A subsequent shot refreshes the window from that shot. A successful dodge interrupts the firing commitment and uses the normal dodge trajectory and speed.

## Magic field

**MGC1–MGC4.** The spell places a persistent circular damage field on the ground at a fixed distance in the aim direction. Cursor distance has no effect on placement. The field owns one pulse schedule shared by all targets. On each pulse, every eligible enemy inside the field can take damage once. Entry, exit and re-entry do not start an enemy-specific timer or produce a contact hit.

**MGC5–MGC7.** Measure field age from successful cast completion. The field has an 85 px radius and lasts 3.00 s. Its four pulses occur at ages 0.75, 1.50, 2.25 and 3.00 s. Resolve the final pulse before natural expiration. At 15 damage per pulse, a surviving enemy present for all four takes 60 damage from that field.

**MGC8–MGC11.** A fresh primary press starts a 450 ms cast. Ordinary movement continues at 60% (132 px/s at the current base speed). The player can turn aim throughout the cast. On completion, take the player's then-current world position and final normalized aim together. The center is `completion_position + 220 px × final_direction` and stays at that ground location. A successful dodge before completion cancels the cast and creates no field.

**MGC12.** After completion a fresh press can begin another cast immediately. During the recast, the existing field continues its own pulse schedule and can expire naturally. Only a successfully completed recast replaces a still-active field. The replacement starts at age zero with its own schedule. Canceling the recast leaves the previous field on its original clock. At most one player-created field exists at any time.

## Combat input and HUD

| Slot (INT1, INT7) | Active style | Universal primary attack (INT5, INT6) |
| --- | --- | --- |
| 1 | Dagger | Existing melee press, hold and late-recovery click buffer |
| 2 | Sword (one-handed sword) | Same input with the sword's own swing phases |
| 3 | Greatsword | Same input with the greatsword's own swing phases |
| 4 | Pistol | Immediate ready shot, then controlled repeats while held |
| 5 | Magic Field | One cast per fresh press |

**INT2–INT4.** A permitted selection takes effect immediately. During a committed action, keep the active style and remember at most one pending selection. Each later valid request replaces the previous one. Apply the pending choice at the first permitted opportunity. A successful dodge can interrupt the action and clear its attack buffer while preserving the pending style. Requests during dodge movement follow the same one-selection rule. Selection cannot interrupt or steer the dodge.

**INT8–INT9.** All five styles consume one normalized world-space aim direction. Today the input is the mouse offset from the player. A future stick can supply a direction through the same interface. A neutral or invalid sample retains the last valid heading. Before any valid sample, every style uses the same consistent initial facing. Melee still applies its weapon-specific tracking and lock rules to this input.

**INT10–INT11.** Holding primary allows a selection request. When a different style activates under a held attack, release and press again to attack with it. Neither the old style's repeat nor its queued melee click can initiate the new style. Show the active style on the HUD and identify any pending style separately. When the request takes effect or clears, remove the pending indication.

**INT12.** F5 restarts the current encounter with the style active at reset. Discard any pending selection, unfinished cast and active player field. The existing atomic reset still restores HP, positions and combat state, preserves F3 visibility, rejects stale damage and requires a fresh primary press. INT12 supersedes the default-weapon part of M66 and E12 for **F5**. Arena startup and the F7/F10/F9 encounter-configuration keys retain their existing fresh-start behavior. [Survivability reset contract](PR16_PLAYER_HEALTH_DAMAGE_DEATH.md#m66-----immediate-atomic-f5-reset-option-b) · [Selector reset contract](COMBAT_ENCOUNTER_SELECTOR.md#4-fresh-encounter-and-reset-contract)

## Integration with existing combat

- **Input and movement.** The player coordinator currently samples aim, selects weapons and dispatches dodge before advancing actions. The Action FSM owns melee commitment and buffered clicks. The Movement FSM owns collision-resolved movement, dodge and invulnerability. Keep style selection distinct from the attack buffer so a dodge can clear one and preserve the other. Apply firing and casting multipliers to ordinary movement. [Player coordinator](../../scenes/combat/combat_test_player.gd) · [Action FSM](../../scenes/combat/player_action_fsm.gd) · [Movement FSM](../../scenes/combat/player_movement_fsm.gd)
- **Damage and encounter lifecycle.** Bullet contacts and field pulses use the existing enemy HP, defeat, active-encounter and completion rules. A living, selected enemy can take damage. An excluded or defeated enemy cannot. The current melee path couples confirmed damage to swing feedback and hitstop. Its feedback decisions apply to melee. Reset must prevent old projectiles, pulses or deferred damage from affecting the fresh encounter. [Enemy health](../../scenes/combat/enemy_health.gd) · [Melee feedback specification](PR17_COMBAT_IMPACT_FEEDBACK.md) · [Encounter selector](COMBAT_ENCOUNTER_SELECTOR.md)
- **Presentation.** The style HUD reports selection independently of the F3 toggle. Preserve the existing HP and encounter labels, melee aim and phase diagnostics, dodge status, enemy state and contact history. [Current arena behavior and diagnostics](../README.md#implementation-documentation)

## Behavioral acceptance

These are checks for a separately authorized implementation, using the initial tuning above.

| Exercise | Observable result |
| --- | --- |
| Fire across open ground, then across a thin solid between consecutive bullet samples. Repeat with two aligned enemies and with a wall in front of them. | In open ground the bullet travels 100 px in 100 ms. The sweep finds the first contact even between samples. Only the nearer enemy takes 15 once when it is first. A wall in front protects both. |
| Put the nearest contact surface just inside 600 px, then just beyond it. Let a physics step cross the range limit. | The inside contact registers. In the second case the bullet expires at 600 px, about 0.60 s in open ground, with zero damage beyond range. |
| Strafe at full input, fire sideways and hold for just under one second. Release, then make a fresh press once ready. | Shots occur at approximately 0, 333 and 667 ms. Release stops repeats. The fresh press fires immediately. Repeated tapping cannot exceed the cadence. |
| Measure unobstructed, full-input movement after each shot. In a second run, dodge during the 120 ms window. | Each shot starts a full 120 ms at 176 px/s, followed by 220 px/s until the next shot. Dodge interrupts the slowdown and follows its existing speed and distance profile. |
| Start a cast walking east, turn aim north before completion, then turn again afterward. Repeat with near and far cursor positions along the same valid heading. | During the 450 ms cast, speed is 132 px/s at full input. No field appears early. Its center is 220 px north of the completion position on both trials and stays there after the player turns. |
| Hold primary through a completed cast, then release and press again. Separately dodge during an unfinished first cast. | Holding produces one field. The fresh press can start the next cast. The interrupted first cast produces none, even after its original completion time passes. |
| Keep a healthy Heavy well inside the 85 px radius for a full field. Keep the Pursuer outside for pulse one, inside for pulses two and three, and outside for pulse four. Move it out and back between pulses two and three. | Damage is zero on placement. Heavy loses 15 at each scheduled boundary, including 3.00 s, for 60 total. Pursuer loses 30 total. There is no entry damage, duplicate hit or pulse after expiry. |
| Start a recast while the old field has a pulse due during casting. First cancel with dodge, then repeat in another attempt and complete the recast at a distinct location. | The due pulse occurs in both trials. After cancellation the old field can finish its remaining pulses. After completion only the new field can pulse, starting 0.75 s after replacement. |
| While Ready, select each slot. During a committed greatsword swing request Pistol, then Magic Field. Repeat with a dodge after queuing Pistol and request Magic Field during dodge movement. | Ready selections are immediate. During commitment the HUD keeps Greatsword active and shows only the latest pending choice. Dodge preserves the queued choice until replaced and completes normally. Magic Field becomes active at the first permitted opportunity and the pending indicator clears. |
| Hold primary across an immediate or buffered switch. Check a transition into each of melee, Pistol and Magic Field, including a late buffered click in the outgoing melee style. | The new style activates without attacking. Release alone produces no attack. The next press starts the selected style's own attack, with its own hold behavior. |
| Before first valid aim, use neutral input. Then aim diagonally, move the pointer into the existing dead zone, and supply an invalid direction at the aim interface. | Initial heading is consistent across styles. Later neutral or invalid samples preserve the last normalized diagonal. Pistol heading, spell placement and melee tracking all receive the same valid direction. |
| With Magic Field active, start a recast over an existing field, queue Pistol and press F5 while holding primary. Repeat with F3 both open and closed. | The HUD shows Magic Field, with nothing pending. HP and positions reset, F3 retains its setting, neither cast nor field can later deal damage, and holding primary does not start a cast. |
| Exercise each melee weapon with tap, hold, late recovery click and dodge interruption. Toggle F3, then defeat the last selected enemy with a bullet or pulse. | Melee timing, aim locks, one hit per target per swing, hitstop and weapon feedback follow the baseline. F3 still reports combat state and damage history. HP, encounter labels, defeat and completion remain accurate, including in solo encounters. |

## Open questions

- Which projectile origin and collision shape should be used? How should exactly tied enemy/solid contacts or contact exactly at the range limit resolve?
- Does a solid or arena boundary affect field placement or pulse coverage? Which part of an enemy counts at the exact radius?
- Do projectile, cast and field clocks advance during hitstop? Which event wins if dodge coincides exactly with cast completion, or replacement with an old field's due pulse?
- Which part of the pistol's slowdown or shot interval blocks switching? If primary stays held through a dodge with Pistol active, when can firing resume?
- Does selecting the already-active slot clear a different pending selection? How should simultaneous slot requests be ordered?
- What happens to an in-flight bullet or active field on switching away or on player death? Which impact cues should identify pistol and field damage?

## Deferred features

The extension excludes ammunition inventory, magazines, reloading, penetration, ricochet, mana or other resource costs, character classes, progression systems, equipment crafting and new enemies. Controller bindings, radial menus, targeting assistance and input-device detection are deferred. Future assistance could be configurable and input-aware, with controller-friendly defaults. Directional field placement works without pinpoint cursor targeting.
