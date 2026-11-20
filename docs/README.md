# Factory ARPG documentation

Keep design decisions and implementation details versioned alongside the project so contributors can trace what the game should do and how the code delivers it.

- [Combat Prototype v0.1](design/COMBAT_PROTOTYPE_V0.1.md) is the frozen gameplay baseline for the prototype. Consult it before implementing related systems.
- [Decision log](design/DECISION_LOG.md) indexes approved gameplay decisions and links to the authoritative specification for each.
- [Godot metadata policy](GODOT_METADATA.md) describes how to handle resource metadata and run the read-only validator.

## Approved specifications

Frozen specifications describe approved behavior and its rationale. They guide implementation and acceptance checks. Proposed approaches, provisional tuning, and deferred features are labeled separately. Keep the approved baseline intact when implementation behavior differs.

When implementation suggests a design change, identify the affected specification and decision, describe the proposed deviation, and obtain owner approval before changing approved behavior. After approval, update the specification and decision log together and preserve the history of any superseded decisions.

## Implementation documentation

Implementation documentation describes how the current code works. Refactors that preserve approved behavior can update implementation documentation as needed while leaving the design baseline intact.

The [combat test arena](../scenes/combat/combat_test_arena.tscn) is a standalone scene. Open it in the Godot editor and press F6 to run it. The [player coordinator](../scenes/combat/combat_test_player.gd) samples screen-relative WASD with normalized diagonals and passes that intent to the Movement FSM each physics step. It also aims the facing marker independently of movement. Within 4 pixels of the player's center in world coordinates, the marker keeps its previous heading. The Player's exported `movement_speed` defaults to a provisional 220 pixels per second.

The [Movement FSM](../scenes/combat/player_movement_fsm.gd) starts Idle and switches to Moving while it receives a nonzero movement vector, including when a collision blocks travel. It owns player velocity and native 2D collision movement. Pursuer and Heavy are stationary.

### Universal dodge

Space requests a dodge in the same physics step as the input. The Movement FSM enters Dodging and locks a normalized direction from held WASD or, when movement input is zero, the current mouse-facing direction. Mouse aim continues to update during the dodge and retains the last valid heading within the 4-pixel dead zone.

The dodge starts at high speed and slows linearly toward zero. The Movement FSM averages the speed over each physics step and scales the final partial step to preserve the configured travel distance on unobstructed terrain. Native collision stays active and can stop or constrain travel.

The Player's `is_invulnerable()` query reports the early dodge window for future damage checks. It turns on at dodge start and expires during dodge movement. At the end of movement, the FSM returns to Idle or Moving and starts a separate dodge recovery timer. Normal WASD movement resumes on the next physics step. Space presses during execution or recovery are discarded, and dodge has no resource cost.

The MovementFSM inspector exposes provisional defaults of 0.24 seconds of movement, 120 pixels of unobstructed travel, invulnerability for the first 40% of the dodge (0.096 seconds before physics-step sampling), and 0.16 seconds of recovery. Invulnerability and recovery status update on physics ticks.

F3 toggles the diagnostic label, which starts hidden and refreshes each physics step while visible. It shows the Movement and Action FSM states, dodge status (Available, In progress, or Recovering), and whether invulnerability is active.

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

The [sweep detector](../scenes/combat/melee_sweep.gd) clips each recorded Active interval to the player's resolved slide path. It estimates time to each collision from travel and remainder and interpolates along each leg. Native capsule queries cover the intervening translation, blade rotation and bounded dagger correction. Each midpoint capsule carries at most one extra pixel of radius, so borderline grazes can register. Queries see targets at their current physics poses. Both arena targets are stationary. Continuous relative motion for future moving targets would require target motion history.

Living Pursuer and Heavy placeholders keep their solid collision layer and also occupy 2D layer 2, **Melee targets**. Each body's instance ID can register once per attack, including across multiple shapes or ticks. Repeated attacks get fresh IDs.

F3 toggles diagnostics and the translucent capsules queried during the latest physics tick. The attack count identifies the current or most recent attack. The contact list and count persist through Recovery and clear when a new attack starts. A tick crossing into Recovery can display its final Active slice until the next tick.

### Damage and hit feedback (pending merge)

The player routes each contact with its originating Active interval to the shared [enemy health script](../scenes/combat/enemy_health.gd). Pursuer starts at 75 HP and Heavy at 150 HP. The target loses at most its remaining HP. F3 retains the most recent HP loss, target, weapon and attack ID, alongside both enemies' health and the last applied hitstop.

| Weapon | Damage | Attack hitstop | Flash duration | Body color blended toward white |
| --- | ---: | ---: | ---: | ---: |
| Dagger | 10 | 25 ms | 70 ms | 35% |
| One-handed sword | 25 | 40 ms | 100 ms | 55% |
| Greatsword | 45 | 60 ms | 140 ms | 75% |

Each successful hit replaces the target's current flash. A lethal hit immediately clears the target's collision layer and mask. After the flash the whole placeholder dims to 48% brightness over 80 ms. Both defeated placeholders stay in the arena, and defeating the second displays the completion message even with F3 closed.

Contacts resolve after movement. The first successful hit from the attack still in progress schedules its hitstop for the next physics tick. Completed intervals still deal damage when a tick spans attacks. A finished attack cannot pause a later swing. During the paused portion of a tick the attack holds its phase and movement multiplier. The remaining time advances the usual phase loop, with sweep intervals measured from the real tick start. Movement and click-buffer expiry use physics time. A successful dodge clears the pause immediately.

F5 takes priority over gameplay input for that physics tick. It restores spawn positions, health, collision settings, colors, the starting dagger and Ready/Idle states. It clears attack and contact history, hitstop, dodge recovery, flashes and completion while preserving the F3 toggle. Held LMB needs a fresh press to restart.

For implementation PRs, identify the affected documentation and use [documentation sync](../.agents/skills/documentation-sync/SKILL.md) on the same branch before review. Reconcile approved changes and keep edits focused on the PR.

After the owner confirms applicable runtime acceptance, use [pre-merge verification](../.agents/skills/pre-merge-verification/SKILL.md) on the specified open PR. It checks the live PR head, acceptance, metadata, documentation, and static integrity before the owner decides whether to merge.
