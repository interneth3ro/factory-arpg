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

The owner approved these milestone choices for the existing Pursuer and Heavy under the [frozen encounter specification](COMBAT_PROTOTYPE_V0.1.md#6-enemies-and-encounter-behavior). See [enemy pursuit and navigation](../README.md#enemy-pursuit-and-navigation) for implementation and provisional tuning.

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

## Enemy attack decisions

The owner approved Option B for each milestone decision below. Numerical values are provisional. These decisions supplement the frozen [enemy encounter](COMBAT_PROTOTYPE_V0.1.md#6-enemies-and-encounter-behavior) and [player health and reset](COMBAT_PROTOTYPE_V0.1.md#7-player-health-death-and-repeatable-reset) specifications. See [enemy attacks and telegraphs](../README.md#enemy-attacks-and-telegraphs) for implementation and acceptance status.

| ID | Approved selection | Behavior |
| --- | --- | --- |
| M27 | Two focused PRs | PR #15 delivers enemy attacks through geometric contact. PR #16 handles player health, damage, dodge immunity resolution, death and reset integration. |
| M28 | Distance and line of sight | Initiation requires readiness, range and clear environmental sight. Range or sight loss after initiation allows the strike to finish. |
| M29 | Independent initiation ranges | Pursuer initiates within 65 px and Heavy within 105 px, independently of their navigation thresholds. |
| M30 | Balanced, readable phases | Pursuer wind-up, active and recovery last 0.35, 0.15 and 0.45 s. Heavy uses 0.75, 0.25 and 0.85 s. |
| M31 | Balanced commitment | Track for the first 60% of wind-up. Lock aim and the Heavy warning at 0.21 s for Pursuer and 0.45 s for Heavy. |
| M32 | Archetype-specific tracking | Pursuer turns up to 360°/s and Heavy up to 180°/s before commitment. |
| M33 | Archetype-specific movement | Both stand still in wind-up and recovery. Only Pursuer moves during the strike. Resume navigation after recovery. |
| M34 | Committed lunge | Pursuer attempts 35 px over its active phase at approximately 233 px/s along its committed direction, subject to native collision. |
| M35 | Directional sectors | Center each sector on the committed heading. Pursuer's sector follows its resolved position and Heavy's stays stationary. |
| M36 | Balanced coverage | Pursuer reaches 60 px over 70° and Heavy reaches 115 px over 110°. Test the player's collision shape. |
| M37 | Progressive telegraph and commitment cue | Both use procedural pose, intensifying color, a lock cue and a strike flash. Heavy also shows its threatened ground region. |
| M38 | Short cooldown | After recovery, ordinary navigation resumes. Further attacks wait 0.30 s for Pursuer and 0.50 s for Heavy. |
| M39 | Interruption and defeat | Nonlethal hits preserve execution. Defeat immediately cancels the attack, contact geometry and attack movement. |
| M40 | Swept detection | Cover relative player and enemy travel between physics samples, using collision-resolved movement. |
| M41 | Detailed diagnostics | F3 shows phase time, readiness, cooldown, directions, geometry, lunge progress and contact. Gameplay telegraphs remain visible with F3 closed. |
| M42 | Separate attack controller | Movement retains navigation, avoidance, collision and sole authority to move the body. |
| M43 | Finish before disengaging | Crossing the disengagement radius during execution defers reevaluation until recovery ends. |
| M44 | Geometric contact during dodge | Register contact regardless of dodge state. PR #16 resolves invulnerability. |
| M45 | One contact per target per execution | The first contact consumes the opportunity even during invulnerability. Clear history on new execution, defeat and reset. |
| M46 | Collision-limited lunge | Obstruction can shorten or stop travel. Keep timing and direction, with no catch-up motion or detour. |
| M47 | Controlled handoff | Clear ordinary motion and confirm standstill before wind-up. Reevaluate navigation and accelerate from rest at release. |
| M48 | Complete attack reset | F5 clears executions, clocks, aim, contacts, movement ownership, poses, warnings and transient diagnostics. |
| M49 | Initial engagement delay | Count 0.25 s for Pursuer and 0.40 s for Heavy from acquisition during navigation. Restart only on fresh acquisition. |
| M50 | Environment-clipped danger | Solid environment blocks strikes. Heavy shows the reachable region, including around corners. Enemy bodies affect movement only. |
| M51 | Independent attacks | Both archetypes can telegraph and strike simultaneously with separate timing, effects and contact histories. |
| M52 | Pause attack progression | Effective hitstop freezes aim, phase clocks, lunge, recovery, cooldown and telegraph progress. Resume the same execution. |
| M53 | Recovery follow-through | Pursuer leans forward and fades quickly. Heavy drops its warning and shows a stronger follow-through. Return to neutral over each recovery. |
| M54 | Layered feedback | Defeat takes priority, followed by hit feedback, attack telegraph, recovery and neutral. Hit flashes preserve pose, direction and warning geometry. |
| M55 | Fully validated non-damaging attacks | Deliver the complete attack, collision, presentation and diagnostic behavior with static checks and owner runtime acceptance. |
| M56 | Lightweight hitstop notification | The player Action FSM owns hitstop and reports effective paused time to enemy attacks. Player movement and dodge keep their existing clocks. |

## Player survivability decisions

The owner approved Option B for each decision on 2026-11-20. The supplied [PR #16 design specification](PR16_PLAYER_HEALTH_DAMAGE_DEATH.md) is authoritative for M57–M74.

| ID | Approved behavior |
| --- | --- |
| M57 | Start at 100 HP. Pursuer deals 15 and Heavy deals 30. All three values are configurable. |
| M58 | Evaluate dodge immunity at geometric contact and consume the attack opportunity even on a block. |
| M59 | Apply distinct eligible attacks independently, including both in one tick. Clamp HP to zero. |
| M60 | Use a 0.12 s Pursuer flash and stronger 0.20 s Heavy flash. Nonlethal damage preserves actions. |
| M61 | Keep a fixed upper-left red health bar and numeric HP visible through death and F3 toggles. |
| M62 | Disable gameplay immediately at zero, collapse over about 0.35 s and show the restart message. |
| M63 | Cancel surviving enemy attacks and navigation immediately, then settle their artwork over about 0.20 s. |
| M64 | Prioritize death, then damage flash, dodge and ordinary movement or attack visuals. |
| M65 | Give player health its own component and keep dodge timing in the Movement FSM. |
| M66 | F5 atomically restores the encounter from any phase, preserves F3 and requires a fresh attack press. |
| M67 | Resolve in contact-time order with stable ties. Identify the first lethal event and ignore later damage. |
| M68 | Add visual impact emphasis for 0.04 s or 0.07 s according to archetype. Gameplay clocks continue. |
| M69 | Retain the five most recent resolver outcomes in F3, including the lethal source and actual HP loss. |
| M70 | Collect only this tick's contacts and resolve after its enemy attack callbacks finish. |
| M71 | Report earliest verified swept contact. Bound geometry approximations and favor protection at ambiguous expiry. |
| M72 | Expose actual tick-relative dodge protection from the existing FSM and retain its current-state query. |
| M73 | Advance encounter generation on reset and reject stale contacts and callbacks. |
| M74 | Deliver the entire milestone together, with independent review and owner acceptance against PRs #13–#15. |

## Combat impact and feedback decisions

The owner-approved [PR #17 decision register](PR17_COMBAT_IMPACT_FEEDBACK.md#2-approved-decision-register) defines M75–M90. The specification also gives the lifecycle rules and identifies provisional tuning for owner acceptance.

| ID | Approved selection | Behavior |
| --- | --- | --- |
| M75 | A — Combat impact and feedback | Focus PR #17 on melee combat presentation. |
| M76 | B — Complete core feedback pass | Cover weapon impacts, enemy reactions, swing trails, and swing and impact audio. |
| M77 | B — Directional impact bursts | Show a brief burst aligned to the incoming attack when damage is confirmed. |
| M78 | B — Distinct silhouettes and timing | Give the dagger a narrow, quick burst, the sword a crisp medium slash and the greatsword a broad, heavier burst. Share a neutral palette. |
| M79 | B — Contact-position impacts | Place the burst at the best-supported geometric contact point using the swing direction at contact. Any placement approximation is cosmetic. |
| M80 | B — One impact per enemy hit | Emit one burst per distinct enemy damaged by a swing, including multi-target hits. |
| M81 | B — Attack-phase-aware cosmetic reactions | Show normal recoil during pursuit, hold, recovery and cooldown. Reduce it during wind-up and minimize it during active strikes. Defeat takes priority. |
| M82 | B — Archetype identity and weapon weight | Scale recoil by weapon weight. The Pursuer reacts quickly and the Heavy moves less. |
| M83 | B — Smooth reaction restart | Redirect recoil from the current visible pose and bound the displacement to prevent drift. |
| M84 | B — Stylized directional swing trails | Give each weapon a distinct trail on hits and misses. |
| M85 | B — Active-phase trails with brief decay | Start trails at active entry, respect hitstop, fade in recovery and end promptly on dodge interruption. |
| M86 | B — Geometry-aligned swing trails | Follow the weapon's reach, arc and actual blade direction, including dagger correction. |
| M87 | B — Separate swing and impact audio | Play the weapon's swing sound at active entry and its impact sound on confirmed damage. |
| M88 | C — Primary impact with restrained secondary hits | Play the first confirmed hit at full strength. Quieter secondary sounds may play under a small concurrency cap. All hits still receive visual feedback. |
| M89 | B — Curated royalty-free audio assets | Store recordings locally, verify redistribution rights and document provenance, license and processing. Prefer CC0 or comparably permissive assets. |
| M90 | B — Shared lifecycle rules with independent components | Coordinate feedback across interruption, death and reset. Reject stale and duplicate events using existing execution and encounter identities. |

## Combat balance and encounter evaluation decisions

The owner approved E1–E10 on 2026-11-20 for the Phase 1 evaluation. The [evaluation specification](COMBAT_BALANCE_ENCOUNTER_EVALUATION.md#2-approved-evaluation-decisions) defines the method. Existing A/M-series decisions govern gameplay.

| ID | Approved selection | Evaluation method |
| --- | --- | --- |
| E1 | C — Hybrid | Review gameplay parameters and conduct structured owner playtesting. |
| E2 | C — Layered encounters | Pursuer only, Heavy only, and Pursuer + Heavy, with each of three weapons. |
| E3 | B — Lightweight structured evaluation | Capture outcomes, approximate HP, notable anomalies, and concise qualitative observations; no mandatory telemetry. |
| E4 | B — Two baseline attempts plus targeted follow-ups | Nine combinations × two attempts = 18 baseline attempts, unless blocked. Repeat only to resolve uncertainty. |
| E5 | B — Minimal isolation if needed | Inspect existing arena first; consider only a narrowly scoped development-only configuration if isolation cannot be achieved reliably. Separate authorization required. |
| E6 | B — Distinct strengths with comparable viability | Preserve weapon identity and practical effectiveness; do not enforce identical DPS, completion times, or remaining HP. |
| E7 | B — Individual fairness plus combined counterplay | Readable individual attacks and meaningful responses to overlapping threats; no required enemy turn-taking. |
| E8 | B — Responsive controls with intentional commitment | Preserve approved attack/dodge semantics and weapon-specific weight; assess predictability and perceived control. |
| E9 | B — Severity-based acceptance | Critical blockers; Significant findings require explicit owner judgment; Minor findings may be deferred. |
| E10 | B — Lightweight specification and results | Standalone Markdown methodology, simple results record, concise final findings and Phase 1 recommendation. |

## Development-only encounter selector decisions

The owner approved E11–E16 on 2026-11-20 to support the nine combinations and 18 baseline attempts in the [Phase 1 evaluation](COMBAT_BALANCE_ENCOUNTER_EVALUATION.md#5-encounter-matrix-and-baseline-attempts). The [selector specification](COMBAT_ENCOUNTER_SELECTOR.md#2-approved-decision-register) defines the design. Implementation requires separate owner approval.

| ID | Approved selection | Behavior |
| --- | --- | --- |
| E11 | B — Development-only keyboard selector | Select Pursuer only, Heavy only, or both enemies in the existing standalone arena. |
| E12 | B — Selection triggers complete reset | Start with both enemies. Every selection starts a fresh encounter, and F5 restarts the current selection with the starting dagger. |
| E13 | B — Dedicated keys and persistent label | F7 selects Pursuer only, F8 Heavy only, and F9 both. Use Input Map actions and keep a small configuration label visible independently of F3. |
| E14 | B — Reversible inactive enemy state | Keep both instances. Exclude inactive enemies from combat, collision, navigation, avoidance, feedback, and completion. Defeat remains a distinct state. Reactivation restores the enemy's initial state. |
| E15 | B — Focused automated regression and owner acceptance | Exercise production behavior using existing test conventions. The owner verifies controls, isolation, completion, and lifecycle transitions at the tested implementation head. |
| E16 | B — Retain as isolated development utility | Keep the selector in the standalone arena for future regression checks. Its scope ends at that arena. |

## Recording future decisions

Append decisions in approval order with a stable ID, descriptive title, approved selection, brief summary, and a link to the authoritative specification. Record dates only when supplied. When a decision changes, retain the earlier entry and link it to the approved replacement.
