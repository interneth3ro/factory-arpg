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

The [Movement FSM](../scenes/combat/player_movement_fsm.gd) starts Idle and switches to Moving while it receives a nonzero movement vector, including when a collision blocks travel. It owns player velocity and native 2D collision movement. Pursuer and Heavy are stationary. Encounter reset is inactive.

### Universal dodge

Space requests a dodge in the same physics step as the input. The Movement FSM enters Dodging and locks a normalized direction from held WASD or, when movement input is zero, the current mouse-facing direction. Mouse aim continues to update during the dodge and retains the last valid heading within the 4-pixel dead zone.

The dodge starts at high speed and slows linearly toward zero. The Movement FSM averages the speed over each physics step and scales the final partial step to preserve the configured travel distance on unobstructed terrain. Native collision stays active and can stop or constrain travel.

The Player's `is_invulnerable()` query reports the early dodge window for future damage checks. It turns on at dodge start and expires during dodge movement. At the end of movement, the FSM returns to Idle or Moving and starts a separate dodge recovery timer. Normal WASD movement resumes on the next physics step. Space presses during execution or recovery are discarded, and dodge has no resource cost.

The MovementFSM inspector exposes provisional defaults of 0.24 seconds of movement, 120 pixels of unobstructed travel, invulnerability for the first 40% of the dodge (0.096 seconds before physics-step sampling), and 0.16 seconds of recovery. Invulnerability and recovery status update on physics ticks.

F3 toggles the diagnostic label, which starts hidden and refreshes each physics step while visible. It shows the Movement and Action FSM states, dodge status (Available, In progress, or Recovering), and whether invulnerability is active.

### Melee attack timing (pending merge)

Press 1, 2 or 3 while Ready to select a weapon. The player starts with the dagger. Each [weapon definition](../scenes/combat/weapon_attack.gd) supplies three provisional durations for owner evaluation.

| Key | Weapon | Wind-up | Active | Recovery |
| --- | --- | ---: | ---: | ---: |
| 1 | [Dagger](../scenes/combat/dagger.tres) | 80 ms | 70 ms | 160 ms |
| 2 | [One-handed sword](../scenes/combat/one_handed_sword.tres) | 160 ms | 120 ms | 260 ms |
| 3 | [Greatsword](../scenes/combat/greatsword.tres) | 320 ms | 180 ms | 420 ms |

A fresh LMB press starts an attack. At the end of Recovery, the [Action FSM](../scenes/combat/player_action_fsm.gd) starts the next attack if LMB is held or a buffered press is still live. Releasing LMB lets the current attack finish. A new press during the final 150 ms of Recovery sets or refreshes a single pending click that expires after 100 ms of physics time. For example, a quick tap with 130 ms remaining expires before the next attack, while a tap with 60 ms remaining starts one more attack. The ActionFSM inspector exposes both buffer settings.

A successful dodge interrupts any phase and clears the buffer. Attack and selection presses during dodge movement are discarded. A fresh LMB press after movement ends can attack during dodge recovery, even if a simultaneous Space request fails. Holding LMB across a dodge requires a new press to restart. Weapon changes during an attack are ignored.

The player's body shows Ready in cyan, Wind-up in amber, Active in white, and Recovery in violet. F3 shows the current phase, weapon and cumulative attack count, including interrupted attacks. The color cue indicates timing only. Hit detection, damage, weapon commitment and attack movement modifiers are deferred.

For implementation PRs, identify the affected documentation and use [documentation sync](../.agents/skills/documentation-sync/SKILL.md) on the same branch before review. Reconcile approved changes and keep edits focused on the PR.

After the owner confirms applicable runtime acceptance, use [pre-merge verification](../.agents/skills/pre-merge-verification/SKILL.md) on the specified open PR. It checks the live PR head, acceptance, metadata, documentation, and static integrity before the owner decides whether to merge.
