# Factory ARPG — Ranged, magic, and combat input

**Implementation status.** The owner authorized the shared input foundation for slots 1–4. The feature branch implements style selection, aiming, primary-input transitions, HUD and resets, pending merge and runtime acceptance. Pistol is selectable with firing deferred to a separately authorized PR. Magic implementation is deferred indefinitely pending design review. [Arena controls](../README.md#combat-style-selection)

**Engine:** Godot 4.7.2

The next standalone arena milestone focuses on aiming a traveling projectile while strafing and switching between melee and Pistol. Keep the shared input and normalized aim direction usable by future styles. The milestone excludes a functional fifth slot, placeholder magic infrastructure, controller bindings, radial menus and targeting assistance.

MGC1–MGC12 and the magic-specific portions of the INT and IR decisions preserve the previously approved magic-field design as a provisional exploration. The owner may retain, revise or replace the approach before deciding whether to implement magic. Casting, field placement and effects, damage pulses, and the integration and runtime tests for magic are deferred.

Rates, speeds, distances, damage, durations and movement multipliers are provisional initial tuning. Within the preserved magic design, four shared pulses, their ordering and the one-field limit are behavioral rules. The [decision log](DECISION_LOG.md#ranged-magic-and-combat-input-decisions) records all 60 decisions. The earlier melee milestone is documented in the [frozen melee baseline](COMBAT_PROTOTYPE_V0.1.md) and [completed Phase 1 evaluation](PHASE_1_COMBAT_EVALUATION_RESULTS.md).

## Pistol

**R1–R6.** The physical firearm is a simple semi-automatic pistol with unlimited ammunition. It has no magazine or reload. Each shot launches a traveling bullet along the player's current aim, independent of movement. Sweep the distance actually traveled between physics samples. The first eligible enemy takes one damage event and stops the bullet. A nearer solid obstacle stops it without damaging an enemy behind it. Contact ends the shot, including when multiple targets lie on the same path. Bullets neither penetrate nor ricochet.

**IR1–IR4.** At firing, place the muzzle along the shot's aim direction. Sweep the bullet's circular collision shape from the player's combat origin to the muzzle before advancing from it. Use the same circle for every subsequent sweep. The initial muzzle offset is 20 px and the bullet radius is 4 px, both provisional.

**IR5–IR7.** Count range from the muzzle. The initial sweep can end the shot and costs zero range. Compare first-contact distances along the bullet center's path. At an exact tie between an eligible enemy and a solid, the solid stops the bullet and the enemy takes no damage. Resolve the final clipped sweep, including contact at exactly 600 px of center travel, before expiring the bullet.

**R7–R12.** A press fires immediately when ready. Holding primary repeats at three shots per second (one interval is ⅓ s, approximately 333 ms). A bullet travels at 1,000 px/s for at most 600 px and deals 15 damage. Clip its last sweep to its remaining range. On each shot ordinary movement drops to 80% for 120 ms (176 px/s at the current 220 px/s base speed). A subsequent shot refreshes the window from that shot. A successful dodge interrupts the firing commitment and uses the normal dodge trajectory and speed.

**IR16–IR17.** The 120 ms slowdown is also the shot's switching commitment. Buffer a switch during this window and apply it when the commitment ends if otherwise permitted. The longer shot interval governs when the pistol can fire again. A successful dodge interrupts the commitment immediately and ends held firing. To resume, release primary and make a fresh press when firing is permitted and the cadence allows it.

## Magic field

**MGC1–MGC4.** The spell places a persistent circular damage field on the ground at a nominal fixed distance in the aim direction. Cursor distance has no effect on placement. The field owns one pulse schedule shared by all targets. On each pulse, every eligible enemy whose damage-receiving shape touches or overlaps the field can take damage once. Entry, exit and re-entry do not start an enemy-specific timer or produce a contact hit.

**IR9–IR11.** At each pulse, check each eligible enemy's damage-receiving shape against the field circle. Overlap or exact boundary contact qualifies for the radius check. To deal damage, at least one point on or within that shape must be both within the closed field circle and visible along an unobstructed segment from the field center. An exposed edge can qualify even when the enemy's center is hidden. An exposed part entirely outside the circle cannot qualify.

**MGC5–MGC7.** Measure field age from successful cast completion. The field has an 85 px radius and lasts 3.00 s. Its four pulses occur at ages 0.75, 1.50, 2.25 and 3.00 s. Resolve the final pulse before natural expiration. At 15 damage per pulse, a surviving enemy eligible on all four pulses takes 60 damage from that field.

**MGC8–MGC11.** A fresh primary press starts a 450 ms cast. Ordinary movement continues at 60% (132 px/s at the current base speed). The player can turn aim throughout the cast. On completion, take the player's then-current world position and final normalized aim together. The intended center is `completion_position + 220 px × final_direction`. The placed field stays at its resolved ground location. A successful dodge before completion cancels the cast and creates no field.

**IR8, IR12.** Trace from the completion position toward the intended center. If a solid wall blocks placement, stop the center on the accessible side of the first such wall with a small collision-safe margin. The cast succeeds there. Only the center needs clearance. The field circle may extend through the wall visually, and pulse damage still requires line of sight.

**IR14.** If successful dodge initiation and cast completion occur at exactly the same time, resolve the dodge first. Cancel the cast without spawning a field. Any existing field continues on its original schedule.

**MGC12.** After completion a fresh press can begin another cast immediately. During the recast, the existing field continues its own pulse schedule and can expire naturally. Only a successfully completed recast replaces a still-active field. The replacement starts at age zero with its own schedule. Canceling the recast leaves the previous field on its original clock. At most one player-created field exists at any time.

**IR15.** If an old field's scheduled pulse falls exactly at successful replacement-cast completion, resolve that pulse at the old location first, including the final pulse at 3.00 s. Then establish the new field at age zero. Its first damage opportunity is its own 0.75 s pulse.

## Combat input and HUD

For ranged planning, apply the shared rules below to slots 1–4. The fifth row and references to casting or fields in the input, HUD and encounter rules document the deferred design.

| Slot (INT1, INT7) | Active style | Universal primary attack (INT5, INT6) |
| --- | --- | --- |
| 1 | Dagger | Existing melee press, hold and late-recovery click buffer |
| 2 | Sword (one-handed sword) | Same input with the sword's own swing phases |
| 3 | Greatsword | Same input with the greatsword's own swing phases |
| 4 | Pistol | Immediate ready shot, then controlled repeats while held |
| 5 | Magic Field | One cast per fresh press |

**INT2–INT4.** A permitted selection takes effect immediately. During a committed action, keep the active style and remember at most one pending selection. Each later valid request replaces the previous one. Apply the pending choice at the first permitted opportunity. A successful dodge can interrupt the action and clear its attack buffer while preserving the pending style. Requests during dodge movement follow the same one-selection rule. Selection cannot interrupt or steer the dodge.

**IR18–IR19.** For exactly simultaneous valid slot requests, process the highest-numbered slot as the winning request. For distinct request times, the latest valid request wins. If the winning request selects the active style, clear any pending choice and its HUD indication. With nothing pending, selecting the active style has no effect.

**INT8–INT9.** All five styles consume one normalized world-space aim direction. Today the input is the mouse offset from the player. A future stick can supply a direction through the same interface. A neutral or invalid sample retains the last valid heading. Before any valid sample, every style uses the same consistent initial facing. Melee still applies its weapon-specific tracking and lock rules to this input.

**INT10–INT11.** Holding primary allows a selection request. When a different style activates under a held attack, release and press again to attack with it. Neither the old style's repeat nor its queued melee click can initiate the new style. Show the active style on the HUD and identify any pending style separately. When the request takes effect or clears, remove the pending indication.

**INT12.** F5 restarts the current encounter with the style active at reset. Discard any pending selection, unfinished cast, in-flight player bullets and active player field. The existing atomic reset still restores HP, positions and combat state, preserves F3 visibility, rejects stale damage and requires a fresh primary press. INT12 supersedes the default-weapon part of M66 and E12 for **F5**. Arena startup and the F7/F10/F9 encounter-configuration keys retain their existing fresh-start behavior. [Survivability reset contract](PR16_PLAYER_HEALTH_DAMAGE_DEATH.md#m66-----immediate-atomic-f5-reset-option-b) · [Selector reset contract](COMBAT_ENCOUNTER_SELECTOR.md#4-fresh-encounter-and-reset-contract)

## Integration with existing combat

- **Input and movement.** The player coordinator currently samples aim, selects weapons and dispatches dodge before advancing actions. The Action FSM owns melee commitment and buffered clicks. The Movement FSM owns collision-resolved movement, dodge and invulnerability. Keep style selection distinct from the attack buffer so a dodge can clear one and preserve the other. Apply firing and casting multipliers to ordinary movement. [Player coordinator](../../scenes/combat/combat_test_player.gd) · [Action FSM](../../scenes/combat/player_action_fsm.gd) · [Movement FSM](../../scenes/combat/player_movement_fsm.gd)
- **Damage and encounter lifecycle.** Bullet contacts and field pulses use the existing enemy HP, defeat, active-encounter and completion rules. A living, selected enemy can take damage. An excluded or defeated enemy cannot. The current melee path couples confirmed damage to swing feedback and hitstop. Its feedback decisions apply to melee. [Enemy health](../../scenes/combat/enemy_health.gd) · [Melee feedback specification](PR17_COMBAT_IMPACT_FEEDBACK.md) · [Encounter selector](COMBAT_ENCOUNTER_SELECTOR.md)
- **IR13. Gameplay clocks.** During localized hitstop, bullets travel at their normal speed, casts advance toward completion and field age advances through its scheduled pulses. A boundary reached during hitstop resolves at its scheduled time. The existing melee hitstop rules still apply to melee.
- **IR20–IR22. Effect lifetime.** Switching styles leaves each in-flight bullet on its original heading with the same collision, damage and remaining range. An active field keeps its damage, pulse times and expiration. On player death, immediately remove all player-created bullets and fields and discard their pending damage so the terminal encounter takes no further damage from them. F5 also clears these effects and rejects their stale damage in the new encounter.
- **IR23–IR24. Impact feedback.** On confirmed pistol damage, show a small spark at contact, flash the damaged enemy briefly and apply restrained localized hitstop. Reuse existing feedback components where practical. Exclude heavy recoil and knockback. Each scheduled magic pulse is visible on the field. Briefly flash only enemies damaged by that pulse. Field damage produces neither hitstop nor recoil.
- **Presentation.** The style HUD reports selection independently of the F3 toggle. Preserve the existing HP and encounter labels, melee aim and phase diagnostics, dodge status, enemy state and contact history. [Current arena behavior and diagnostics](../README.md#implementation-documentation)

## Behavioral acceptance

For a separately authorized ranged implementation, use the pistol checks and the melee and pistol portions of the shared checks at the initial tuning above.

### Pistol checks

| Exercise | Observable result |
| --- | --- |
| Fire across open ground, then across a thin solid between consecutive bullet samples. Repeat with two aligned enemies and with a wall in front of them. | In open ground the bullet travels 100 px in 100 ms. The sweep finds the first contact even between samples. Only the nearer enemy takes 15 once when it is first. A wall in front protects both. |
| Put a thin solid halfway between the combat origin and the 20 px muzzle, with an enemy beyond. Repeat with the nearest edge 3 px off the aim line and then 5 px off it. Repeat the grazing trials beyond the muzzle. | The swept 4 px circle hits the solid in the direct and 3 px cases and protects the enemy. In the 5 px cases the bullet clears the solid and can hit the enemy. |
| Arrange first contact when the bullet center would be 599, 600 or 601 px from the muzzle. Use a step that crosses the limit. | The first two contacts register. In the third trial the bullet expires at 600 px with no hit. In open ground the center reaches 620 px from the combat origin after 0.60 s of flight from the muzzle. |
| Align an enemy and a solid so their first swept-circle contacts occur at the same travel distance. Repeat with the enemy slightly nearer. | The tied shot stops at the solid with zero enemy HP loss. The nearer enemy takes 15 once in the second trial. |
| Strafe at full input, fire sideways and hold for just under one second. Release, then make a fresh press once ready. | Shots occur at approximately 0, 333 and 667 ms. Release stops repeats. The fresh press fires immediately. Repeated tapping cannot exceed the cadence. |
| Measure unobstructed, full-input movement after each shot. In a second run, dodge during the 120 ms window. | Each shot starts a full 120 ms at 176 px/s, followed by 220 px/s until the next shot. Dodge interrupts the slowdown and follows its existing speed and distance profile. |

### Magic field checks

**Deferred pending magic design review.** These scenarios are retained for future reference and are excluded from ranged implementation acceptance.

| Exercise | Observable result |
| --- | --- |
| Start a cast walking east on open ground, turn aim north before completion, then turn again afterward. Repeat with near and far cursor positions along the same valid heading. | During the 450 ms cast, speed is 132 px/s at full input. No field appears early. Its center is 220 px north of the completion position on both trials and stays there after the player turns. |
| Aim through two solid walls within 220 px and complete a cast. Place a target entirely behind the first wall but within the resulting field circle. | The cast succeeds. Its center stops just clear of the first wall on the player's side. The circle can overlap the wall. The target loses zero HP on every pulse. |
| At a pulse, put one visible target shape tangent to the 85 px circle and another across its edge with its center hidden and a sliver exposed inside the circle. Repeat with only the out-of-radius part of the second shape exposed. | Each target loses 15 once in the first trial. In the repeat, the second loses zero because no in-radius point is visible. |
| Hold primary through a completed cast, then release and press again. Separately dodge during an unfinished first cast. | Holding produces one field. The fresh press can start the next cast. The interrupted first cast produces none, even after its original completion time passes. |
| Keep a healthy Heavy in clear sight well inside the 85 px radius for a full field. Keep the visible Pursuer entirely outside for pulse one, inside for pulses two and three, and outside for pulse four. Move it out and back between pulses two and three. | Damage is zero on placement. Heavy loses 15 at each scheduled boundary, including 3.00 s, for 60 total. Pursuer loses 30 total. There is no entry damage, duplicate hit or pulse after expiry. |
| Start a recast while the old field has a pulse due during casting. First cancel with dodge, then repeat in another attempt and complete the recast at a distinct location. | The due pulse occurs in both trials. After cancellation the old field can finish its remaining pulses. After completion only the new field can pulse, starting 0.75 s after replacement. |
| Initiate a successful dodge exactly when a recast would finish. | No replacement appears. The old field pulses at its remaining original times and expires at its original 3.00 s boundary. |
| Complete a replacement exactly at an old field's 1.50 s pulse, then repeat at its 3.00 s pulse. Keep one healthy enemy in each area, visible from its own field center and outside the other circle. | At the tie only the old target loses 15. The old field disappears and the new target first loses 15 at replacement age 0.75 s. |

### Shared input, timing and encounter lifecycle checks

| Exercise | Observable result | Milestone scope |
| --- | --- | --- |
| While Ready, select each slot. During a committed greatsword swing request Pistol, then Magic Field. Repeat with a dodge after queuing Pistol and request Magic Field during dodge movement. | Ready selections are immediate. During commitment the HUD keeps Greatsword active and shows only the latest pending choice. Dodge preserves the queued choice until replaced and completes normally. Magic Field becomes active at the first permitted opportunity and the pending indicator clears. | Check ready and buffered selection across slots 1–4, including requests during dodge. Defer the Magic Field selection. |
| Hold primary across an immediate or buffered switch. Check a transition into each of melee, Pistol and Magic Field, including a late buffered click in the outgoing melee style. | The new style activates without attacking. Release alone produces no attack. The next press starts the selected style's own attack, with its own hold behavior. | Check transitions into melee and Pistol. Defer the transition into Magic Field. |
| Before first valid aim, use neutral input. Then aim diagonally, move the pointer into the existing dead zone, and supply an invalid direction at the aim interface. | Initial heading is consistent across styles. Later neutral or invalid samples preserve the last normalized diagonal. Pistol heading, spell placement and melee tracking all receive the same valid direction. | Check shared aim for melee and Pistol. Defer spell placement. |
| Fire once and request a switch 60 ms later. Separately fire and immediately dodge while holding primary, keeping Pistol selected through the next ready shot time. | The HUD shows a pending choice at 60 ms and the new active style at 120 ms, before another shot is ready. In the dodge trial, holding produces no second shot. Release and a fresh press when ready fire one. | Ranged milestone. |
| During a committed sword swing queue Pistol, then select Sword. Repeat the Sword request. | The pending indicator clears on the first Sword request. The second changes nothing. Sword stays active when commitment ends. | Ranged milestone. |
| During commitment request slots 4 and 5 at exactly the same instant. Repeat with slot 4 requested strictly later. | Only slot 5 is pending and then active in the tied trial. Slot 4 wins the later-request trial. | Check the same tie and later-request rules with two valid slots among 1–4. Defer the slot 5 trial. |
| In separate trials, overlap localized hitstop with open bullet flight, the end of a cast and a scheduled field pulse. | The bullet covers 1 px per elapsed ms throughout hitstop. The cast still completes at 450 ms. A visible eligible target loses 15 at the scheduled field age even during hitstop. | Check bullet travel during hitstop. Defer cast and pulse timing. |
| Fire at a distant enemy and switch to melee before impact. Separately switch away from a field after its first pulse with a healthy Heavy in clear sight inside it. | The bullet continues on its original heading and deals 15 on first enemy contact within its original range. The field deals 15 at ages 1.50, 2.25 and 3.00 s, then expires. | Check the in-flight bullet after switching. Defer the active-field trial. |
| With Magic Field active, start a recast over an existing field, queue Pistol and press F5 while holding primary. Repeat with F3 both open and closed. | The HUD shows Magic Field, with nothing pending. HP and positions reset, F3 retains its setting, neither cast nor field can later deal damage, and holding primary does not start a cast. | Deferred. This setup requires Magic Field as the active style and a recast in progress. |
| With a bullet in flight and a field still due to pulse, trigger player death. Repeat with F5. Include damage awaiting delivery when each transition occurs. | Both effects disappear immediately. Neither later contacts, scheduled pulses nor queued damage change enemy HP in the terminal or restarted encounter. | Check death and F5 with the bullet and its pending damage. Defer field setup and pulse cleanup. |
| Observe a confirmed pistol hit, then a magic pulse with one visible enemy and one fully occluded enemy in radius. Repeat the pulse with neither enemy exposed. | The shot gives a small contact spark, a brief target flash and restrained localized hitstop without heavy recoil or knockback. Both field pulses are visible. Only the damaged enemy flashes, and neither pulse causes hitstop or recoil. | Check pistol impact feedback. Defer pulse feedback. |
| Exercise each melee weapon with tap, hold, late recovery click and dodge interruption. Toggle F3, then defeat the last selected enemy with a bullet or pulse. | Melee timing, aim locks, one hit per target per swing, hitstop and weapon feedback follow the baseline. F3 still reports combat state and damage history. HP, encounter labels, defeat and completion remain accurate, including in solo encounters. | Check melee, F3 and encounter completion with a bullet. Defer completion by pulse. |

## Open questions

If the owner retains the magic-field approach, the exact wall-clearance margin remains an implementation detail. The center must stay clear on the accessible side of the first wall. Clearance for the full field radius is unnecessary.

## Deferred features

The extension excludes ammunition inventory, magazines, reloading, penetration, ricochet, mana or other resource costs, character classes, progression systems, equipment crafting and new enemies. Controller bindings, radial menus, targeting assistance and input-device detection are deferred. Future assistance could be configurable and input-aware, with controller-friendly defaults. Directional field placement works without pinpoint cursor targeting.
