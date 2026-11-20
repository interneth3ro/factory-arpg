# Factory ARPG documentation

Keep design decisions and implementation details versioned alongside the project so contributors can trace what the game should do and how the code delivers it.

- [Combat Prototype v0.1](design/COMBAT_PROTOTYPE_V0.1.md) is the frozen gameplay baseline for the prototype. Consult it before implementing related systems.
- [Player health, enemy damage and death](design/PR16_PLAYER_HEALTH_DAMAGE_DEATH.md) records the approved M57–M74 survivability decisions.
- [Combat impact and feedback](design/PR17_COMBAT_IMPACT_FEEDBACK.md) records the approved M75–M90 requirements for contact bursts, enemy recoil, swing trails and combat audio.
- [Combat balance and encounter evaluation](design/COMBAT_BALANCE_ENCOUNTER_EVALUATION.md) defines the Phase 1 playtest matrix, observation rubric, and owner exit decision.
- [Development-only encounter selector](design/COMBAT_ENCOUNTER_SELECTOR.md) records the approved E11–E16 design for repeatable isolated and combined encounters in the standalone arena. Implementation requires separate owner approval.
- [Decision log](design/DECISION_LOG.md) indexes approved gameplay and evaluation decisions and links to their specifications.
- [Godot metadata policy](GODOT_METADATA.md) describes how to handle resource metadata and run the read-only validator.

## Approved specifications

Frozen specifications describe approved behavior and its rationale. They guide implementation and acceptance checks. Proposed approaches, provisional tuning, and deferred features are labeled separately. Keep the approved baseline intact when implementation behavior differs.

When implementation suggests a design change, identify the affected specification and decision, describe the proposed deviation, and obtain owner approval before changing approved behavior. After approval, update the specification and decision log together and preserve the history of any superseded decisions.

## Implementation documentation

Implementation documentation describes how the current code works. Refactors that preserve approved behavior can update implementation documentation as needed while leaving the design baseline intact.

The [combat test arena](../scenes/combat/combat_test_arena.tscn) is a standalone scene. Open it in the Godot editor and press F6 to run it. The [player coordinator](../scenes/combat/combat_test_player.gd) samples screen-relative WASD with normalized diagonals and passes that intent to the Movement FSM each physics step. It also aims the facing marker independently of movement. Within 4 pixels of the player's center in world coordinates, the marker keeps its previous heading. The Player's exported `movement_speed` defaults to a provisional 220 pixels per second.

The [Movement FSM](../scenes/combat/player_movement_fsm.gd) starts Idle and switches to Moving while it receives a nonzero movement vector, including when a collision blocks travel. It owns player velocity and native 2D collision movement.

### Universal dodge

Space requests a dodge in the same physics step as the input. The Movement FSM enters Dodging and locks a normalized direction from held WASD or, when movement input is zero, the current mouse-facing direction. Mouse aim continues to update during the dodge and retains the last valid heading within the 4-pixel dead zone.

The dodge starts at high speed and slows linearly toward zero. The Movement FSM averages the speed over each physics step and scales the final partial step to preserve the configured travel distance on unobstructed terrain. Native collision stays active and can stop or constrain travel.

The Player's `is_invulnerable()` query reports the current early dodge window. It turns on at dodge start and expires during dodge movement. At the end of movement, the FSM returns to Idle or Moving and starts a separate dodge recovery timer. Normal WASD movement resumes on the next physics step. Space presses during execution or recovery are discarded, and dodge has no resource cost.

The MovementFSM inspector exposes provisional defaults of 0.24 seconds of movement, 120 pixels of unobstructed travel, invulnerability for the first 40% of the dodge (0.096 seconds before physics-step sampling), and 0.16 seconds of recovery. Invulnerability and recovery status update on physics ticks.

F3 toggles the diagnostic label, which starts hidden. While visible it displays the latest completed physics state each rendered frame, including the Movement and Action FSM states, dodge status (Available, In progress, or Recovering), and whether invulnerability is active.

### Melee attack timing

Press 1, 2 or 3 while Ready to select a weapon. The player starts with the dagger. Each [weapon definition](../scenes/combat/weapon_attack.gd) supplies three provisional durations for owner evaluation.

| Key | Weapon | Wind-up | Active | Recovery |
| --- | --- | ---: | ---: | ---: |
| 1 | [Dagger](../scenes/combat/dagger.tres) | 80 ms | 70 ms | 160 ms |
| 2 | [One-handed sword](../scenes/combat/one_handed_sword.tres) | 160 ms | 120 ms | 260 ms |
| 3 | [Greatsword](../scenes/combat/greatsword.tres) | 320 ms | 180 ms | 420 ms |

A fresh LMB press starts an attack. At the end of Recovery, the [Action FSM](../scenes/combat/player_action_fsm.gd) starts the next attack if LMB is held or a buffered press is still live. Releasing LMB lets the current attack finish. A new press during the final 150 ms of Recovery sets or refreshes a single pending click that expires after 100 ms of physics time. For example, a quick tap with 130 ms remaining expires before the next attack, while a tap with 60 ms remaining starts one more attack. The ActionFSM inspector exposes both buffer settings.

A successful dodge interrupts any phase and clears the buffer. Attack and selection presses during dodge movement are discarded. A fresh LMB press after movement ends can attack during dodge recovery, even if a simultaneous Space request fails. Holding LMB across a dodge requires a new press to restart. Weapon changes during an attack are ignored.

The player's body shows Ready in cyan, Wind-up in amber, Active in white, and Recovery in violet. F3 shows the current phase, weapon and cumulative attack count, including interrupted attacks.

### Attack direction and mobility

The dark center marker follows the mouse. During an attack, a separate gold pointer outside the body shows the Action FSM's attack direction through Recovery. Each new swing samples the latest facing, including repeats. F3 shows whether attack aim is tracking, correcting, locked or inactive, alongside the current phase's ordinary-movement multiplier.

| Weapon | Attack direction | Wind-up | Active | Recovery |
| --- | --- | ---: | ---: | ---: |
| Dagger | Tracks through Wind-up, turns toward the mouse at up to 180°/s during Active, then holds | 0.90× | 0.85× | 0.95× |
| One-handed sword | Tracks through Wind-up and locks at Active start | 0.80× | 0.65× | 0.85× |
| Greatsword | Tracks until 75% of Wind-up (240 ms), then locks | 0.60× | 0.40× | 0.70× |

These values are provisional. The Movement FSM scales ordinary WASD speed by the time spent in each phase within a physics tick. Ready uses full speed. Under owner decision M2 Option B, a successful dodge can still interrupt every phase, including late greatsword Wind-up. It clears attack aim and pending attack input immediately and uses the usual locked dodge trajectory and burst speed.

### Melee contact geometry

During Active, a radial segment sweeps clockwise from minus half the weapon arc to plus half the arc relative to the Action FSM's attack direction. Reach measures the segment from the player's world center to its tip. The round contact envelope extends half the configured width around the segment, including at the tip. Provisional dimensions are:

| Weapon | Reach | Total arc | Full width |
| --- | ---: | ---: | ---: |
| Dagger | 55 px | 65° | 12 px |
| One-handed sword | 85 px | 110° | 16 px |
| Greatsword | 115 px | 155° | 22 px |

The [sweep detector](../scenes/combat/melee_sweep.gd) clips each recorded Active interval to the player's resolved slide path. It estimates time to each collision from travel and remainder and interpolates along each leg. Native capsule queries cover the intervening translation, blade rotation and bounded dagger correction. Each midpoint capsule carries at most one extra pixel of radius, so borderline grazes can register. Queries see each enemy at its current physics pose. An enemy can cross the blade between samples. Continuous detection of that relative motion would require target motion history. Check approach, retreat, cross-arc motion and repeated swings during owner acceptance.

Living Pursuer and Heavy placeholders keep their solid collision layer and also occupy 2D layer 2, **Melee targets**. Each body's instance ID can register once per attack, including across multiple shapes or ticks. Repeated attacks get fresh IDs.

F3 toggles diagnostics and the translucent capsules queried during the latest physics tick. The attack count identifies the current or most recent attack. The contact list and count persist through Recovery and clear when a new attack starts. A tick crossing into Recovery can display its final Active slice until the next tick.

### Damage and hit feedback

The player routes each contact with its originating Active interval to the shared [enemy health script](../scenes/combat/enemy_health.gd). Pursuer starts at 75 HP and Heavy at 150 HP. The target loses at most its remaining HP. F3 retains the most recent HP loss, target, weapon and attack ID, alongside both enemies' health and the last applied hitstop.

| Weapon | Damage | Attack hitstop | Flash duration | Body color blended toward white |
| --- | ---: | ---: | ---: | ---: |
| Dagger | 10 | 25 ms | 70 ms | 35% |
| One-handed sword | 25 | 40 ms | 100 ms | 55% |
| Greatsword | 45 | 60 ms | 140 ms | 75% |

Each successful hit replaces the target's current flash. A lethal hit immediately clears the target's collision layer and mask. After the flash the whole placeholder dims to 48% brightness over 80 ms. Both defeated placeholders stay in the arena, and defeating the second displays the completion message even with F3 closed.

Contacts resolve after movement. The first successful hit from the attack still in progress schedules its hitstop for the next physics tick. Completed intervals still deal damage when a tick spans attacks. A finished attack cannot pause a later swing. During the paused portion of a tick the attack holds its phase and movement multiplier. The remaining time advances the usual phase loop, with sweep intervals measured from the real tick start. Movement and click-buffer expiry use physics time. A successful dodge clears the pause immediately.

F5 takes priority over gameplay input for that physics tick. It restores spawn positions, health, collision settings, colors, the starting dagger and Ready/Idle states. It clears attack and contact history, hitstop, dodge recovery, flashes and completion while preserving the F3 toggle. Held LMB needs a fresh press to restart.

### Weapon impact, recoil, trails and audio

PR #19 implements milestone M75–M90. Independent source review is complete, and the owner reports 12/12 runtime checks passed at `dce0a4b6e5ca83eb02b4b7f12ed970ddc57bdc4d` with no exceptions. The owner manually merged PR #19 and completed cleanup. Every Active interval uses the Action FSM's blade angle, including dagger correction. An exact end-of-tick entry seeds the first trail edge and plays the swing even when the first positive-duration sweep falls in the next tick. Longer ticks consume intervals in execution order. The ribbon uses player-local coordinates throughout Active and Recovery. Offensive hitstop holds the active blade angle. After the last Active sample, the same geometry stays attached to the moving player and its opacity fades over 35/55/75 ms (dagger/sword/greatsword). Only the portion of a boundary-crossing tick after Active counts toward the fade. A recovery hitstop holds the attack clock while this cosmetic fade continues. A successful dodge or player death clears the recorded intervals and cuts the trail and swing immediately. [Weapon effects](../scenes/combat/weapon_effects.gd) · [Action FSM](../scenes/combat/player_action_fsm.gd)

The existing capsule query supplies the matched enemy shape and blade pose. The burst begins on the facing edge of the enemy disk nearest that sampled blade, an approximation at the midpoint of the first matching substep. Each distinct damaged target gets one world-space burst. Needle, slash and broad fan decay over 75/118/160 ms. A surviving enemy blends from its current recoil toward the new direction, then back to neutral. The body pose applies Pursuer limits of 6 px and 7° over 120 ms and Heavy limits of 3 px and 3° over 180 ms. New recoil peaks use 35% strength in wind-up and 12% in Active. On entry into a stricter phase, an existing reaction eases into the smaller offset and tilt within 20 ms. A reaction already returning to neutral uses its remaining time. A frame crossing the end of the blend continues along the reduced release, and a frame reaching the original expiry settles at neutral. Entering Recovery lets that hit finish at its existing strength. A fresh hit starts from the displayed offset and tilt. Defeat clears recoil, surviving enemies settle from their visible pose on player death, and F5 clears every effect. [Sweep](../scenes/combat/melee_sweep.gd) · [Enemy body presentation](../scenes/combat/enemy_health.gd)

Each Active entry plays the weapon's swing at −12 dB. The first successful damage application per execution plays the primary impact at −8 dB. Swing and primary players each retain up to two playbacks, so two executions in one physics tick can both sound. A third replaces the oldest on that player. Changing the recording replaces that player's previous stream. Later targets in the existing query order can use one free secondary voice at −20 dB. A busy secondary drops only that sound. The cap is three impacts plus two swings. Death and F5 stop all playback. [Combat audio](../scenes/combat/combat_audio.gd) · [Recording credits and processing](COMBAT_AUDIO_CREDITS.md)

The [automated Godot fixture](../tests/combat/weapon_feedback_acceptance.gd) has assertions for moving misses and blade-tip positions on all three weapons, phase entry and fade timing, active and recovery hitstop, two-target hits, repeated executions, dodge, death, F5 and recoil transitions on both archetypes. For a hit already in release at Active entry, it compares the displayed offset and tilt after one 33 ms frame and three 11 ms frames, then checks the original expiry. It requires an authorized engine run. Owner playtesting separately evaluates visible attachment, perceived impact, telegraph readability and audible onset, weight and overlap in the arena mix.

### Enemy pursuit and navigation

The Pursuer and Heavy start Idle. Each detects the player by range and a native physics ray against the four perimeter walls and three solid blocks. Once engaged, an enemy follows the player around obstructions until the player exceeds the disengagement radius. Coming back into view inside detection range can start another pursuit.

| Provisional value | Pursuer | Heavy |
| --- | ---: | ---: |
| Maximum speed (px/s) | 240 | 130 |
| Acceleration / deceleration (px/s²) | 1800 / 2200 | 600 / 850 |
| Detect / disengage (px) | 240 / 380 | 190 / 320 |
| Stop / resume / begin retreat (px) | 55 / 75 / 35 | 90 / 115 / 65 |
| Target update interval (s) | 0.15 | 0.25 |
| Collision radius / nominal mesh clearance (px) | 14 / 18 | 25 / 29 |

Distances are center to center. Pursuing ends inside the stopping distance with clear sight. Holding lasts until the player exceeds the resume threshold, passes behind cover, or steps inside the retreat threshold. Retreating aims for the stopping distance, shortening its route at a boundary if that still gains at least 6 px. The enemy tries directly away, then offsets of ±30° and ±55°, rejecting routes that initially close distance or require a long detour. A blocked retreat holds and retries on the archetype's timer.

Each movement agent follows its current waypoints every physics tick. A 6 px target change triggers an update at the next interval. A partial route follows the reachable portion, then enters Waiting for path and retries even for a stationary player. The native reachability result and the endpoint's distance from the requested target distinguish a complete route. Empty or negligible routes also wait. F3 shows the state, engagement, distance, actual movement speed, active destination and path status alongside HP and defeat.

The arena loads two static navigation polygons. The Pursuer uses the world map and layer 1. The Heavy uses a scene-owned map and layer 2. Isolating the overlapping meshes keeps each path query on its own clearance geometry. Both bodies have an avoidance agent on the world map, where they can see each other. The movement controller smooths the preferred velocity before submission. Its sole movement callback applies the avoidance result through the existing body's `move_and_slide()`. A stationary enemy retains avoidance priority. [Godot's actor-size guidance](https://docs.godotengine.org/en/4.7/tutorials/navigation/navigation_different_actor_types.html)

The [offline mesh builder](../tools/arena_navigation.py) derives the floor from the inner faces of the physical walls, subtracts the static obstacle footprints, erodes the surface by the body radius plus 4 px, then triangulates it. With Shapely 2.1.2 in an authoring environment, run `python tools/arena_navigation.py` to check for drift. After a collider edit, add `--write` to regenerate both resources. The resources also retain the outer outline and the static-collider bake settings for the `arena_solid` group. The running game loads the saved vertices and polygons directly.

Lethal damage immediately stops movement and disables avoidance. The player coordinator's F5 reset restores both enemies to their spawn points, cancels destinations and retries, clears velocity and re-enables avoidance. Enemies remain Idle through the reset tick.

### Enemy attacks and telegraphs

PR #15 introduced geometric contact. The owner passed all 47 runtime checks at `ee9a5a8ef472ecc3301a04dd54fffe8f688a5d28` with no reported exceptions. Each enemy's Attack node exposes its own provisional tuning. The approved ranges, durations, commitment points, sector dimensions and lunge distance are recorded in the [M27–M56 decision register](design/DECISION_LOG.md#enemy-attack-decisions).

After acquisition, the initial delay counts down during pursuit. A ready enemy in range with clear environmental sight parks its path and zeros its velocity inside the movement callback. This handoff establishes standstill before the wind-up clock starts. Early aim turns from the enemy's heading toward the player. The bright chevron marks commitment. Heavy also displays a ground warning through its active strike. The hit flash blends over the current pose, and both enemies visibly return to neutral over recovery.

The movement callback accepts one submission per physics frame. During the Pursuer's active interval it tests forward travel against native collision, then moves only the available distance through the same body movement function used for pursuit. Recovery releases movement and checks disengagement. The next navigation request accelerates from rest. Cooldown runs during ordinary positioning.

The sector uses inscribed chords at most 3° apart. At Heavy reach the maximum difference from a circular rim is under 0.04 px. The geometry code subtracts shadows projected from the arena's static collision rectangles and convex footprints. Heavy draws and tests the same clipped polygons. The player circle is swept along its resolved slide legs within each active interval. During a lunge, contact also follows the enemy's resolved travel and any blocked stationary tail. Travel/remainder ratios estimate collision times. Over each half-pixel of attacker travel the test uses the region visible throughout that slice and checks both endpoint poses. A fleeting graze at a moving shadow edge can be missed between those bounds. [Sector construction](../scenes/combat/enemy_attack_sector.gd) · [Motion traces](../scenes/combat/slide_trace.gd)

The player updates first and reports the exact hitstop consumed at the start of that physics tick. Each enemy excludes that prefix from attack progression, including on the final fractional tick. Hitstop scheduled by a new contact takes effect when the player consumes it. F3 shows the per-enemy pause, phase, lock, execution number, contact, lunge displacement and geometry alongside player dodge invulnerability. F5 clears both attacks and preserves the diagnostic toggle. The first geometric contact consumes the strike even during dodge. [Enemy attack controller](../scenes/combat/enemy_attack.gd)

### Player survivability

PR #16 delivered M57–M74. The owner reports that independent corrective review passed at `c586db88e3ebd02db59b92ea115bdb1a0b516b19` and all applicable runtime playtesting checks passed for that implementation with no reported exceptions. The owner merged PR #16 and completed cleanup. Player/Health owns HP and death. Each Attack node exports its damage and visual feedback tuning. The fixed upper-left HUD shows HP even while dead or with F3 closed. F3 adds the last five resolver decisions, oldest first, with physics frame, verified offset in milliseconds, enemy, execution, outcome, actual HP loss, remaining HP and lethal source. [Player health](../scenes/combat/player_health.gd) · [Owner acceptance checklist](PR16_RUNTIME_ACCEPTANCE.md)

| Enemy | Damage | Body flash | Stronger body and HUD flash |
| --- | ---: | ---: | ---: |
| Pursuer | 15 HP | 0.12 s | First 0.04 s |
| Heavy | 30 HP | 0.20 s | First 0.07 s |

The detector intersects the two collision-resolved traces in time order. On each linear leg it finds the player disk's first entry against the clipped polygons using offset edges and circles around their vertices. Initial overlap gives offset zero within the leg. During a lunge, entry into the unclipped sector supplies a candidate. The detector tests visibility at that instant, then sweeps the region visible throughout the half-pixel slice. A verified entry supplies the time for sorting and the dodge decision. If only the slice's end pose reveals contact, eight bisections narrow the interval between a clipped miss and a verified touch. The touch sets the sort time. Protection wins if dodge immunity expires inside that interval, including at the touch. A shadow opening and closing entirely between checks can still hide a fleeting graze. Collision travel/remainder timing and the inscribed sector remain approximations. [Sector geometry](../scenes/combat/enemy_attack_sector.gd) · [Trace interpolation](../scenes/combat/slide_trace.gd)

The existing player physics priority schedules input and movement before enemy submissions. Movement records the tick's protected interval from its dodge clock before advancing it. A successful Space request starts at tick offset zero. `was_invulnerable_at(frame, offset)` includes the start and excludes the exact expiry. The end of a tick is protected if time remains in the window. Death and F5 invalidate the snapshot. [Movement FSM](../scenes/combat/player_movement_fsm.gd)

Enemy movement submits one frame- and generation-tagged command. Its direct `velocity_computed` connection advances the attack and reports contacts synchronously. The first contact queues one deferred drain **inside avoidance dispatch**. Godot 4.7.2 finishes iterating active agents and then flushes the message queue within the same physics iteration, before the physics step. Idle or defeated enemies owe no callback. The coordinator sorts by verified tick offset, enemy name (Heavy before Pursuer on ties), then execution ID. Health applies each decision, clamps lethal loss to remaining HP, and records later events in the batch as ignored. This boundary depends on the direct connections and the 4.7.2 navigation loop. Recheck it if either changes. [Engine physics loop](https://github.com/godotengine/godot/blob/4.7.2-stable/main/main.cpp#L4636-L4672) · [Avoidance dispatch](https://github.com/godotengine/godot/blob/4.7.2-stable/modules/navigation_2d/nav_map_2d.cpp#L489-L507) · [NavigationAgent2D signal](https://github.com/godotengine/godot/blob/4.7.2-stable/scene/2d/navigation/navigation_agent_2d.cpp#L654-L657)

For all nonlethal hits in one physics tick, the strongest hit supplies the body flash and HUD emphasis with its own durations. A hit in a later physics tick refreshes both effects. A nonlethal hit overrides dodge or weapon color for its duration while both FSMs continue. Death cancels actions, hides aim markers and starts a 0.35 s collapse. Surviving enemies clear navigation, warnings and contact geometry immediately and ease to neutral over 0.20 s. The centered death message and zero HP persist. F5 increments the encounter generation first, invalidates the batch and pending movement commands, kills active visual tweens, and restores the encounter. Deferred drains reject a mismatched generation or physics frame. [Player coordinator](../scenes/combat/combat_test_player.gd) · [Enemy movement](../scenes/combat/enemy_movement.gd) · [Enemy presentation](../scenes/combat/enemy_health.gd)

For implementation PRs, identify the affected documentation and use [documentation sync](../.agents/skills/documentation-sync/SKILL.md) on the same branch before review. Reconcile approved changes and keep edits focused on the PR.

After the owner confirms applicable runtime acceptance, use [pre-merge verification](../.agents/skills/pre-merge-verification/SKILL.md) on the specified open PR. It checks the live PR head, acceptance, metadata, documentation, and static integrity before the owner decides whether to merge.
