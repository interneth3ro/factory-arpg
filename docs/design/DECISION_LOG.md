# Design decision log

The [Combat Prototype v0.1 decision register](COMBAT_PROTOTYPE_V0.1.md#2-approved-decision-register) is authoritative. Entries below follow the approved decision sequence.

| ID | Decision | Approved selection | Summary | Specification |
|---|---|---|---|---|
| A1 | Movement axes | A — Screen-relative WASD | WASD follows screen axes, with normalized diagonals independent of the artwork. | [Controls and movement](COMBAT_PROTOTYPE_V0.1.md#3-controls-and-movement) |
| A2 | Dodge direction | C — Movement priority, aim fallback | Use held WASD or fall back to mouse-facing. Lock direction at dodge start. | [Dodge](COMBAT_PROTOTYPE_V0.1.md#4-dodge-specification) |
| A3 | Dodge motion | B — Immediate burst with deceleration | Start at high speed and decelerate smoothly. Solid collision applies and unobstructed distance is consistent. | [Dodge](COMBAT_PROTOTYPE_V0.1.md#4-dodge-specification) |
| A4 | Dodge protection | B — Brief early invulnerability | Protect against ordinary enemy damage from dodge start until before dodge movement ends. | [Dodge](COMBAT_PROTOTYPE_V0.1.md#4-dodge-specification) |
| A5 | Dodge recovery | B — Short dodge recovery | Briefly prevent another dodge while allowing normal movement and eligible attacks. Recovery presses do not queue and dodging has no automatic Energy cost. | [Dodge](COMBAT_PROTOTYPE_V0.1.md#4-dodge-specification) |
| A6 | Basic attack input | C — Hold-to-repeat and buffering | Holding LMB repeats eligible attacks. A late click can buffer one short-lived attack. Releasing stops repeats and dodging clears pending attacks. | [Basic melee](COMBAT_PROTOTYPE_V0.1.md#5-basic-melee-and-weapon-behavior) |
| A7 | Attack direction | C — Weapon-dependent aim commitment | Dagger allows bounded active correction. Sword locks at active start and greatsword locks in late wind-up. Facing can continue to follow the mouse. | [Weapon behavior](COMBAT_PROTOTYPE_V0.1.md#5-basic-melee-and-weapon-behavior) |
| A8 | Movement during attacks | B — Phase-dependent movement penalties | Attack phases modify ordinary movement. Dodge speed is independent and attacks have no automatic lunge. | [Attack phases](COMBAT_PROTOTYPE_V0.1.md#5-basic-melee-and-weapon-behavior) |
| A9 | Melee collision | C — Time-swept melee arcs | Sweep across the active arc between physics steps and damage each target at most once per attack. | [Hit detection](COMBAT_PROTOTYPE_V0.1.md#5-basic-melee-and-weapon-behavior) |
| A10 | Impact feedback | B — Lightweight weapon-scaled feedback | Scale flashes, visual reactions, and restrained hitstop to weapon weight. Exclude whole-SceneTree pauses and initial screen shake. | [Impact feedback](COMBAT_PROTOTYPE_V0.1.md#5-basic-melee-and-weapon-behavior) |
| A11 | Enemy warnings | C — Hybrid enemy telegraphs | Pursuer telegraphs with pose and color. Heavy has a longer wind-up and an arc that matches its strike geometry. | [Enemy behavior](COMBAT_PROTOTYPE_V0.1.md#6-enemies-and-encounter-behavior) |
| A12 | Enemy attack aim | C — Limited tracking then commitment | Enemies turn within limits during early wind-up, then lock their strike and Heavy’s warning arc at commitment. | [Enemy aim](COMBAT_PROTOTYPE_V0.1.md#6-enemies-and-encounter-behavior) |
| A13 | Enemy positioning | B — Pursuit with engagement spacing | Use archetype-specific preferred distances and tolerances for stable engagement, recovery, and re-engagement. | [Engagement spacing](COMBAT_PROTOTYPE_V0.1.md#6-enemies-and-encounter-behavior) |
| A14 | Player health and death | B — Simple player health and controlled death | Use configurable fixed health, a visible bar, hit feedback, terminal death, and manual restart. | [Player health and reset](COMBAT_PROTOTYPE_V0.1.md#7-player-health-death-and-repeatable-reset) |
| A15 | Enemy defeat and reset | B — Enemy defeat state and manual reset | Defeat ends actions and collision, gives brief feedback, and contributes to encounter completion. Enemies return through manual reset. | [Enemy defeat](COMBAT_PROTOTYPE_V0.1.md#6-enemies-and-encounter-behavior), [encounter reset](COMBAT_PROTOTYPE_V0.1.md#7-player-health-death-and-repeatable-reset) |
| A16 | World coordinates | A — Native 2D with isometric presentation | Use standard 2D nodes and physics. Artwork, geometry, and Y-sorting provide the isometric presentation. | [Approved decision A16](COMBAT_PROTOTYPE_V0.1.md#2-approved-decision-register) |

## Damage milestone decisions

These approved implementation decisions apply to the [stationary combat placeholders](COMBAT_PROTOTYPE_V0.1.md#6-enemies-and-encounter-behavior).

| ID | Approved selection |
| --- | --- |
| M8 | Active melee contacts apply damage once per target per attack. Zero health causes terminal defeat until reset. |
| M9 | Dagger, sword and greatsword deal 10, 25 and 45 damage. Pursuer and Heavy start with 75 and 150 HP. Values are provisional. |
| M10 | Successful damage pauses player attack progression for 25, 40 or 60 ms according to weapon weight. |
| M11 | Successful damage flashes the target, with intensity and duration increasing by weapon weight. |
| M12 | Defeated placeholders stay visible, dimmed and nonblocking until manual reset. |

## Enemy locomotion decisions

The owner approved these milestone choices for the existing Pursuer and Heavy under the [frozen encounter specification](COMBAT_PROTOTYPE_V0.1.md#6-enemies-and-encounter-behavior). The branch implementation and provisional distances, speeds and timings are recorded in [enemy pursuit and navigation](../README.md#enemy-pursuit-and-navigation-pending-merge).

| ID | Approved selection |
| --- | --- |
| M13 | Start inactive. Detect the player within the archetype's detection radius with clear sight. |
| M14 | The Pursuer detects within 240 px and disengages beyond 380 px. The Heavy detects within 190 px and disengages beyond 320 px. Reacquisition requires fresh detection. |
| M15 | Set provisional maximum speeds to 240 px/s for the Pursuer and 130 px/s for the Heavy. |
| M16 | The Pursuer stops approaching at 55 px and resumes beyond 75 px. The Heavy stops at 90 px and resumes beyond 115 px. |
| M17 | Use native NavigationAgent2D waypoints and CharacterBody2D collision movement for both enemies. |
| M18 | Maintain engagement spacing through controlled retreat. Hold again once acceptable spacing returns. |
| M19 | The Pursuer begins retreat below 35 px from the player. The Heavy begins retreat below 65 px. |
| M20 | Validate a small deterministic set of retreat destinations on the enemy's mesh. Hold when none improves separation meaningfully. |
| M21 | Check navigation targets every 0.15 s for the Pursuer and every 0.25 s for the Heavy. Update immediately on significant state changes or target invalidation. Follow current waypoints between updates. |
| M22 | Build walkable geometry from the physical arena with separate clearance for the 14 px and 25 px bodies. |
| M23 | Follow useful partial paths to the reachable endpoint, wait and retry while engaged. |
| M24 | Accelerate and decelerate with physics time. Give the Heavy more gradual changes in movement. |
| M25 | Combine solid enemy-to-enemy collision with native local avoidance. Defeat removes both until reset. |
| M26 | Use a native 2D physics sight check for acquisition. Environmental walls and solid obstacles block detection. After acquisition, temporary loss of sight preserves engagement. |

## Recording future decisions

Append decisions in approval order with a stable ID, descriptive title, approved selection, brief summary, and a link to the authoritative specification. Record dates only when supplied. When a decision changes, retain the earlier entry and link it to the approved replacement.
