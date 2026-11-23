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
| M66 | F5 atomically restores the encounter from any phase, preserves F3 and requires a fresh attack press. For the extension, [INT12](RANGED_MAGIC_COMBAT_INPUT.md#combat-input-and-hud) amends the original default-weapon reset. |
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

The owner approved E11–E16 on 2026-11-20 to support the nine combinations and 18 baseline attempts in the [Phase 1 evaluation](COMBAT_BALANCE_ENCOUNTER_EVALUATION.md#5-encounter-matrix-and-baseline-attempts). The [selector specification](COMBAT_ENCOUNTER_SELECTOR.md#2-approved-decision-register) defines the design. PR #22 delivered the selector with the Decision 17 amendment below.

| ID | Approved selection | Behavior |
| --- | --- | --- |
| E11 | B — Development-only keyboard selector | Select Pursuer only, Heavy only, or both enemies in the existing standalone arena. |
| E12 | B — Selection triggers complete reset | Start with both enemies. Every selection starts a fresh encounter, and F5 restarts the current selection with the starting dagger. For the extension, [INT12](RANGED_MAGIC_COMBAT_INPUT.md#combat-input-and-hud) supersedes the starting-dagger rule on F5. |
| E13 | B — Dedicated keys and persistent label | F7 selects Pursuer only, F8 Heavy only, and F9 both. Use Input Map actions and keep a small configuration label visible independently of F3. |
| E14 | B — Reversible inactive enemy state | Keep both instances. Exclude inactive enemies from combat, collision, navigation, avoidance, feedback, and completion. Defeat remains a distinct state. Reactivation restores the enemy's initial state. |
| E15 | B — Focused automated regression and owner acceptance | Exercise production behavior using existing test conventions. The owner verifies controls, isolation, completion, and lifecycle transitions at the tested implementation head. |
| E16 | B — Retain as isolated development utility | Keep the selector in the standalone arena for future regression checks. Its scope ends at that arena. |
| Decision 17 | A — Heavy-only selector on F10 | Supersedes E13's Heavy-only binding after owner playtesting identified the editor's F8 Stop shortcut. Use F10 for Heavy only in the focused running arena. See the [current controls](COMBAT_ENCOUNTER_SELECTOR.md#3-configuration-and-controls). |

## Phase 1 combat evaluation closure

The owner approved **Phase 1 — CONDITIONAL PASS** after completing the E1–E10 baseline in the standalone arena. EVAL-01 began as a provisional Significant finding about greatsword timing against the Pursuer. After clarifying how dodge supported repositioning between swings, the owner deferred EVAL-01 as **Minor and non-blocking**. The original ratings and exit decision stand. No combat parameter changes were authorized. Phase 2 planning is next. [Evaluation results and owner decision](PHASE_1_COMBAT_EVALUATION_RESULTS.md)

## Ranged, magic and combat input decisions

The owner approved 36 original decisions for the next combat extension, followed by 24 implementation-readiness decisions. The feature specification defines the behavioral contract, initial tuning and [acceptance checks](RANGED_MAGIC_COMBAT_INPUT.md#behavioral-acceptance).

**Implementation priority.** After PR #26 delivered shared input for slots 1–4, the owner authorized physical pistol combat. P1 Option A assigns input and encounter ordering to the player coordinator, cadence and commitment to a dedicated pistol controller, and bullet flight and contacts to an independent projectile simulation. Magic implementation, including a fifth slot, is deferred indefinitely pending design review. Its previously approved decisions remain recorded as provisional design work. The owner may revise or replace the underlying approach before deciding whether to implement it.

### Physical firearm

The [pistol specification](RANGED_MAGIC_COMBAT_INPUT.md#pistol) defines shot resolution and the provisional balance values.

| ID | Decision | Approved selection |
| --- | --- | --- |
| R1 | Archetype | Physical firearm. |
| R2 | Weapon | Simple semi-automatic pistol. |
| R3 | Delivery | Traveling bullets with swept collision. |
| R4 | Handling | Aim freely with the mouse while moving. Firing briefly slows movement. Dodge interrupts firing commitment. |
| R5 | Ammunition | Unlimited, with no magazine or reload. |
| R6 | Contact | Stop at the first enemy or solid obstacle. Deal damage at most once per bullet. No penetration or ricochet. |
| R7 | Trigger | Fire immediately when ready. Holding attack repeats at controlled intervals. |
| R8 | Cadence | Three shots per second, approximately 333 ms apart. |
| R9 | Bullet speed | 1,000 px/s. |
| R10 | Travel limit | 600 px. |
| R11 | Damage | 15 per bullet. |
| R12 | Firing slowdown | Move at 80% (176 px/s) for 120 ms after each shot. Subsequent shots refresh the window. Dodge interrupts it. |

### Magic

The [magic field specification](RANGED_MAGIC_COMBAT_INPUT.md#magic-field) defines casting, placement and the pulse schedule.

| ID | Decision | Approved selection |
| --- | --- | --- |
| MGC1 | Archetype | Ground-targeted area spell. |
| MGC2 | Targeting | Place the spell by direction at a fixed distance. |
| MGC3 | Effect | Persistent area damage field. |
| MGC4 | Damage timing | Field-wide pulses damage each eligible enemy at most once per pulse. |
| MGC5 | Lifetime | Four pulses over three seconds at field ages 0.75, 1.50, 2.25 and 3.00 s. Resolve the final pulse before expiration. |
| MGC6 | Radius | 85 px. |
| MGC7 | Damage | 15 per pulse, up to 60 per enemy per field. |
| MGC8 | Cast time | 450 ms. |
| MGC9 | Cast movement and interruption | Move at 60% (132 px/s) while casting. Dodge cancels an unfinished cast without creating a field. |
| MGC10 | Aim commitment | Aim can change throughout the cast and locks at completion. |
| MGC11 | Field center | Place it 220 px from the player's position at completion, along the final aim direction. |
| MGC12 | Recast | Allow a recast after completion. Keep the previous field on its clock while casting. Only successful completion replaces it. Canceling leaves it intact. Maximum one player-created field. |

### Input integration

The [combat input and HUD specification](RANGED_MAGIC_COMBAT_INPUT.md#combat-input-and-hud) defines shared inputs and the changes to switching and F5.

| ID | Decision | Approved selection |
| --- | --- | --- |
| INT1 | Style slots | One set of slots for the three melee weapons, pistol and magic field. |
| INT2 | Switching | Switch immediately when permitted. Buffer requests during committed actions. |
| INT3 | Dodge | Preserve pending selection through dodge. Switching cannot interrupt the dodge. |
| INT4 | Pending choice | Keep at most one pending selection. The latest valid request wins. |
| INT5 | Attack control | One universal primary attack input. |
| INT6 | Per-style trigger | Preserve melee input behavior. Holding repeats pistol shots at three per second. Magic requires a fresh press per cast. |
| INT7 | Keyboard slots | 1 Dagger, 2 Sword, 3 Greatsword, 4 Pistol, 5 Magic Field. |
| INT8 | Aim interface | All styles consume a shared normalized direction, from mouse now and compatible with a future controller stick. |
| INT9 | Aim fallback | Retain the last valid direction on neutral or invalid input. Before the first valid sample use a consistent initial facing. |
| INT10 | Held attack across a switch | Allow switching while held. Require release and a fresh press to attack with the newly active style. |
| INT11 | HUD | Display the active style and any pending selection. |
| INT12 | F5 reset | Preserve active style. Clear pending selection, unfinished casting and active player-created fields. |

### Implementation readiness

These decisions refine the approved [pistol](RANGED_MAGIC_COMBAT_INPUT.md#pistol), [magic field](RANGED_MAGIC_COMBAT_INPUT.md#magic-field), [combat input](RANGED_MAGIC_COMBAT_INPUT.md#combat-input-and-hud) and [encounter integration](RANGED_MAGIC_COMBAT_INPUT.md#integration-with-existing-combat) rules.

| ID | Decision | Approved selection |
| --- | --- | --- |
| IR1 | Muzzle origin | Offset the muzzle forward along aim. Check the initial segment from the player's combat origin to the muzzle. |
| IR2 | Muzzle offset | Start with a provisional 20 px offset. |
| IR3 | Bullet geometry | Sweep a circle along the entire path, including the initial segment. |
| IR4 | Bullet radius | Start with a provisional 4 px collision radius. |
| IR5 | Range origin | Allow 600 px of center travel from the muzzle. The initial checked segment costs zero range. |
| IR6 | Tied bullet contacts | At exactly equal earliest contact distances, the solid stops the bullet and blocks enemy damage. |
| IR7 | Range boundary | Resolve the final clipped sweep before expiration. Contacts up to and including the maximum center travel qualify. |
| IR8 | Blocked field placement | Complete the cast on the accessible side of the first blocking solid wall. |
| IR9 | Pulse eligibility | Require both radius eligibility and unobstructed sight from the field center. |
| IR10 | Radius boundary | Overlap or exact contact between the field circle and the enemy's damage-receiving shape qualifies. |
| IR11 | Partial visibility | At least one point on or within the damage-receiving shape must be both in radius and unobstructed from the field center. |
| IR12 | Center clearance | Keep only the center clear by a small collision-safe margin. Visual wall overlap is allowed. Visibility still governs damage. The exact margin is unspecified. |
| IR13 | Localized hitstop | Projectile movement, casting and field pulse clocks continue during hitstop. |
| IR14 | Dodge at cast completion | A successful dodge wins the exact tie. Cancel the cast and preserve any existing field on its schedule. |
| IR15 | Pulse at replacement | Resolve the old field's tied pulse first, including its final pulse. Start the replacement at age zero with no immediate damage. |
| IR16 | Pistol switching commitment | Each shot buffers switching for its 120 ms slowdown. A successful dodge interrupts immediately. The approximately 333 ms firing interval is separate. |
| IR17 | Held fire after dodge | Dodge ends the held sequence. Resuming fire requires release and a fresh press, subject to cadence. |
| IR18 | Active slot selection | Selecting the active style clears a pending switch. With nothing pending it has no effect. |
| IR19 | Simultaneous slots | The highest-numbered valid slot wins an exact tie. Otherwise the latest valid request wins. |
| IR20 | Bullet after switching | In-flight bullets retain their collision, damage, direction and range after a style change. |
| IR21 | Field after switching | The active field retains its pulse schedule, damage and expiration after a style change. |
| IR22 | Player death | Immediately remove player-created bullets and fields and prevent pending damage from affecting the terminal encounter. F5 still clears effects and stale damage on reset. |
| IR23 | Pistol impact | Confirmed hits produce a small contact spark, brief enemy flash and restrained localized hitstop. Reuse existing feedback where practical. Exclude heavy recoil and knockback. |
| IR24 | Magic impact | Show each field pulse and briefly flash only damaged enemies. Field damage causes neither hitstop nor recoil. |

## Phase 2 combat evaluation decisions

The owner approved the following decisions for the four-style combat evaluation. [Trial results and owner disposition](PHASE_2_COMBAT_EVALUATION_RESULTS.md)

| ID | Decision | Approved selection |
| --- | --- | --- |
| EVAL2-1 | Evaluation depth | A — Quick validation using eight focused trials. |
| EVAL2-2 | Minor findings | B — Record and defer minor issues. A minor finding alone does not require corrective implementation. |
| EVAL2-3 | Final evaluation plan | A — Approve the eight-trial owner-led runtime evaluation. |
| EVAL2-4 | Final disposition | A — Phase 2 PASS. Eight of eight trials passed with zero findings. |
| EVAL2-5 | Documentation scope | A — Record the evaluation in a focused four-file documentation-only PR. |

## Construction and material handling

The table preserves the original construction approvals. FM8–FM13 remain in force. For FM14, apply the [revised storage eligibility and provisional reservation rules](EARLY_GAME_GATHERING_AND_AUTOMATION.md#3-construction-recovery-and-inventory-fm8fm14-eg7-rc3-rc5).

| ID | Decision | Approved selection |
| --- | --- | --- |
| FM8 | Conveyor changes | B — Preserve items during compatible edits and recover them safely on removal. |
| FM9 | Dismantling | B — Recover the intact machine. |
| FM10 | Machine transport | C — Carry smaller machines. Larger industrial machines eventually require specialized transport or construction capabilities. |
| FM11 | Local relocation | C — Committing a move cancels production, returns unconsumed materials and discards partial progress. Canceling the move before commitment leaves the machine as it was. |
| FM12 | Recovery destination | B — Recover into inventory or accessible storage. Insufficient space blocks dismantling without loss. |
| FM13 | Machine configuration | A — Local moves preserve configuration. Redeploying a dismantled machine resets its recipe, settings and connections. |
| FM14 | Construction supplies | B — Build at home from inventory and accessible local storage. Remote construction requires physically available materials. |

## Early-game gathering, workshop, and automation

These entries preserve the original EG approvals. The [supersession map](#early-game-reconciliation) identifies which rules still apply. The [reconciled specification](EARLY_GAME_GATHERING_AND_AUTOMATION.md) governs current design.

| ID | Decision | Approved selection |
| --- | --- | --- |
| EG1 | First automation milestone | C — Gather and process by hand, connect two workshop stations by conveyor, then deploy an extractor and collect its output manually. |
| EG2 | Manual extraction | B — Award resources on completed cycles. The deposit retains interrupted progress. |
| EG3 | Mining movement | A — Mine while stationary. Movement interrupts mining and preserves deposit progress. |
| EG4 | Laser targeting | A — Target an eligible deposit directly with the cursor, within range and with clear line of sight. |
| EG5 | Target lock | B — Holding the primary action keeps the valid target locked even when the cursor moves away. |
| EG6 | Mining feedback | B — Show targeting, progress and extraction feedback in the world near the deposit. |
| EG7 | Inventory and collection | C — Use slots with handling rules by item type. Collect mined resources automatically when capacity permits. |
| EG8 | Opening workshop | B — Process two basic materials at the smelter and assemble components at the crafting station. |
| EG9 | Teaching sequence | B — Have the player carry a batch between stations before a short conveyor takes over that transfer. |
| EG10 | Continuous production | B — Repeat the selected recipe whenever inputs, output space and operating conditions allow. |
| EG11 | Input compatibility | C — Accept conveyor inputs required by the active recipe. Allow manual insertion of other materials the machine supports. |
| EG12 | Recipe switching | B — Switch immediately when idle. During an active cycle, finish it and deposit its output before switching. |
| EG13 | Buffer allocation | C — Use shared buffers and protect input space for the active recipe's ingredients. |
| EG14 | Blocked delivery | B — Keep blocked items on the conveyor, propagate backpressure and show the cause so the player can clear it. |
| EG15 | Conveyor interaction | B — Inspect a segment and retrieve an item in place. If inventory is full, the item stays on the belt. |
| EG16 | Extractor placement | B — Place the extractor beside a compatible deposit with a visible, unobstructed direct connection. |
| EG17 | Deposit throughput | B — Divide throughput equally among active extractors and redistribute shares they cannot use. |
| EG18 | Manual mining priority | C — Give active manual mining first claim up to the laser's capacity. Extractors share the remaining deposit throughput. |
| EG19 | Extractor output | B — Use a moderate fixed buffer. Pause when full and resume when space opens, including during unattended production. |
| EG20 | Remote hauling | B — Carry output home and bulk-deposit eligible resources into accessible storage up to capacity. |
| EG21 | Wireless research | C — Make basic transportation a visible goal reachable through normal research and workshop production. Exploration can contribute discoveries and reveal advanced capabilities. |

EG22 remains undecided. Pairing and operational details are deferred. [Wireless research boundary](EARLY_GAME_GATHERING_AND_AUTOMATION.md#10-wireless-research-boundary-eg21-only)

## Home-base decisions

The [integrated production rules](EARLY_GAME_GATHERING_AND_AUTOMATION.md#6-integrated-smelting-crafting-and-production-goals-hb1hb11) cover orders, priorities, and final assembly.

| ID | Selection | Approved direction |
|---|---|---|
| HB1 | C | Integrated basic smelting/component crafting; specialized manufacturing remains physical. |
| HB2 | C | Dedicated raw/refined/component storage and automatic eligible downstream access. |
| HB3 | B | Round-robin smelting instructions; finite and continuous orders. |
| HB4 | B | Partially funded finite orders automatically reserve eligible incoming inputs; continuous orders do not reserve. |
| HB5 | C | Progressive smelting speed, batch and parallel-channel upgrades. |
| HB6 | C | Finite/continuous integrated component orders; equipment goals prepare components, not final weapons/armor. |
| HB7 | B | Recursive preparation of eligible intermediate components, with specialized needs reported. |
| HB8 | B | Player-initiated final equipment crafting with configurable bounded randomness; advanced experimentation deferred. |
| HB9 | C | Player-ordered goal priorities for material allocation, independent of round-robin processing time. |
| HB10 | B | Persistent goal reservations and Ready for Assembly status until player crafts, changes or cancels. |
| HB11 | C | Integrated standardized crafting expands with research; specialized processes require physical machinery. |
| HB12 | C | Physical conveyor connections and convenient storage interfaces for specialized manufacturing. |
| HB13 | C | Future goal-aware routing direction; detailed advanced logistics mechanics deferred and not initially unlocked. |

## Reconciliation decisions

These decisions revise the [opening progression](EARLY_GAME_GATHERING_AND_AUTOMATION.md#7-revised-opening-progression-rc1-rc6rc8) and its material-handling rules.

| ID | Selection | Approved direction |
|---|---|---|
| RC1 | B | First automated extractor replaces smelter-to-crafter conveyor as major opening automation milestone. |
| RC2 | B | Preserve EG10–EG13's general safety/compatibility principles; defer specialized-machine-specific rules. |
| RC3 | C | Provisional reservation protection with explicit player override for construction/manual crafting; may be superseded in future cross-system design. |
| RC4 | A | Player deposits into chosen dedicated storage, no automatic sorting at start; future sorting research possible. |
| RC5 | Owner clarification | General-purpose home-base storage is entirely isolated from production, construction, reservations and conveyor access at start. |
| RC6 | B | Extractor manually collectable; optional early conveyor to nearby industrial storage. |
| RC7 | B | Separate conveyor-capable industrial storage containers, manufactured at base and deployed at remote ore deposits; no initial wireless link. |
| RC8 | B | Integrated crafting manufactures complete basic deployable equipment using deterministic recipes. |
| RC9 | B | Remote extractor/conveyor/storage obey physical backpressure and finite capacity in loaded and unloaded areas. |

## Early-game reconciliation

The [reconciled early-game specification](EARLY_GAME_GATHERING_AND_AUTOMATION.md) governs the opening progression. The original FM and EG selections above remain part of the decision history.

| Earlier decision | Current scope |
|---|---|
| EG1, EG9 | HB1–HB2 and RC1 supersede the original opening milestone and teaching sequence. The player uses integrated base services and deploys a remote extractor. The first optional conveyor carries extractor output to nearby industrial storage (RC6–RC7). |
| EG8 | The two-material introduction remains. HB1–HB2 replace separate stations and ingot transfers with integrated smelting and component crafting. |
| EG10–EG13 | HB3–HB11 govern integrated production. RC2 retains compatibility, material safety, predictable transitions, finite capacity and backpressure. The original single-recipe, switching and buffer rules no longer prescribe machine behavior. Specialized-machine details remain provisional under HB11–HB13. |
| EG20 | The player still hauls output home. RC4–RC5 narrow bulk deposit to compatible items in one player-chosen inventory. General-purpose storage stays isolated. |
| FM14 | RC5 excludes general storage from automatic construction access. Remote construction still requires physically available supplies. RC3 provisionally protects reservations and requires explicit player approval to reallocate reserved materials. |

FM8–FM13, EG2–EG7, EG14–EG19 and EG21 remain in force. RC6–RC9 extend the extraction and conveyor rules to optional industrial storage, including backpressure in unloaded scenes. EG22 and detailed wireless operation remain undecided.

## Core Foundation decisions

These approvals define the permanent game foundation. CF15–CF16 settle the initial backpack, basic-resource stack and general-storage capacities left open under EG7. CF30 revises the production sequence in the roadmap. The FM, EG, HB and RC supersessions above still govern factory gameplay.

| ID | Approved selection | Rationale | Specification |
| --- | --- | --- | --- |
| CF1 | Reusable combat-capable player | Carry the evaluated controls and combat behavior into the permanent game and keep one regression baseline. | [Architecture](CORE_GAME_FOUNDATION_ARCHITECTURE.md#shared-player-and-input) |
| CF2 | Persistent game root with swappable locations | Give the session a lifetime that spans visits to the world and home base. | [Architecture](CORE_GAME_FOUNDATION_ARCHITECTURE.md#session-locations-and-state) |
| CF3 | One persistent player instance | Travel preserves the player's identity and avoids duplicate actors. | [Architecture](CORE_GAME_FOUNDATION_ARCHITECTURE.md#session-locations-and-state) |
| CF4 | Scene-independent authoritative world state | Unloading a location must preserve its gameplay facts. | [Architecture](CORE_GAME_FOUNDATION_ARCHITECTURE.md#session-locations-and-state) |
| CF5 | Stable object IDs and explicit registration | A fresh scene instance must bind to the right existing record without overwriting another object. | [Architecture](CORE_GAME_FOUNDATION_ARCHITECTURE.md#session-locations-and-state) |
| CF6 | Versioned structured save data | Restore related records coherently and identify incompatible data before adopting it. | [Architecture](CORE_GAME_FOUNDATION_ARCHITECTURE.md#saving-and-playthrough-isolation) |
| CF7 | Hybrid manual save and autosave | Support deliberate checkpoints as well as automatic progress protection. | [Architecture](CORE_GAME_FOUNDATION_ARCHITECTURE.md#saving-and-playthrough-isolation) |
| CF8 | Multiple independent playthrough slots | A player can start or resume one run without affecting another. | [Architecture](CORE_GAME_FOUNDATION_ARCHITECTURE.md#saving-and-playthrough-isolation) |
| CF9 | Shared player scene with modular gameplay components | Reuse movement, actions and health while allowing specialized capabilities to evolve independently. | [Architecture](CORE_GAME_FOUNDATION_ARCHITECTURE.md#shared-player-and-input) |
| CF10 | Unified interaction framework with specialized actions | Share target discovery and dispatch while each action enforces its own rules. | [Gameplay](CORE_GAME_FOUNDATION_GAMEPLAY.md#interaction-and-targeting) |
| CF11 | Hybrid proximity and cursor targeting | Nearby objects remain discoverable and aimed actions can identify the intended target. | [Gameplay](CORE_GAME_FOUNDATION_GAMEPLAY.md#interaction-and-targeting) |
| CF12 | Layered input contexts with priority | A UI gesture or tool action must have one eligible recipient. | [Architecture](CORE_GAME_FOUNDATION_ARCHITECTURE.md#shared-player-and-input) |
| CF13 | Data-driven items and independent inventory state | Share type rules while keeping ownership and quantities local to each inventory. | [Gameplay](CORE_GAME_FOUNDATION_GAMEPLAY.md#items-backpack-and-general-storage) |
| CF14 | Slots with item-specific capacity rules | Represent stackable resources and equipment with different handling needs. | [Gameplay](CORE_GAME_FOUNDATION_GAMEPLAY.md#items-backpack-and-general-storage) |
| CF15 | 24 backpack slots and 100 units per basic-resource stack | Establish the initial carrying capacity for gathering and transfer checks. | [Gameplay](CORE_GAME_FOUNDATION_GAMEPLAY.md#items-backpack-and-general-storage) |
| CF16 | Independent physical general storage, initially one 48-slot container | Provide local storage relief while preserving RC5 isolation. | [Gameplay](CORE_GAME_FOUNDATION_GAMEPLAY.md#items-backpack-and-general-storage) |
| CF17 | Drag-and-drop, quick transfers and partial stacks | Support routine hauling and precise quantity choices within capacity. | [Gameplay](CORE_GAME_FOUNDATION_GAMEPLAY.md#items-backpack-and-general-storage) |
| CF18 | Capacity-aware partial resource collection | Accept what fits and preserve the uncollected balance without loss or duplication. | [Gameplay](CORE_GAME_FOUNDATION_GAMEPLAY.md#manual-mining) |
| CF19 | Fully handcrafted starting world and manually placed deposits | Give exploration and resource sites deliberate, repeatable placement. | [Gameplay](CORE_GAME_FOUNDATION_GAMEPLAY.md#world-and-home-base) |
| CF20 | Small explorable starting region | Make the first trip between resource sites and home playable within foundation scope. | [Gameplay](CORE_GAME_FOUNDATION_GAMEPLAY.md#world-and-home-base) |
| CF21 | Independent regions with possible future seamless connections | Keep locations independently loadable while leaving later world presentation open. | [Gameplay](CORE_GAME_FOUNDATION_GAMEPLAY.md#world-and-home-base) |
| CF22 | Permanent home-base shell with reserved functional areas | Give storage and future integrated services a lasting physical home. | [Gameplay](CORE_GAME_FOUNDATION_GAMEPLAY.md#world-and-home-base) |
| CF23 | Paired transition anchors and saved-position restoration | Travel needs predictable arrivals, while resuming must recover the player's actual saved place safely. | [Architecture](CORE_GAME_FOUNDATION_ARCHITECTURE.md#travel-and-restoration) |
| CF24 | Dedicated mining capability on the shared player | Use the accepted movement and input behavior for deliberate laser extraction. | [Gameplay](CORE_GAME_FOUNDATION_GAMEPLAY.md#manual-mining) |
| CF25 | Dependency-driven vertical implementation | Prove each playable capability on the systems it will actually use. | [Implementation](CORE_GAME_FOUNDATION_IMPLEMENTATION.md#sequence-and-authority) |
| CF26 | Layered acceptance with persistence and regression gates | Combine state checks with owner playtesting and protect previously accepted behavior. | [Implementation](CORE_GAME_FOUNDATION_IMPLEMENTATION.md#sequence-and-authority) |
| CF27 | Modular specification package | Give ownership, gameplay and delivery criteria distinct references that can be reviewed together. | [Implementation](CORE_GAME_FOUNDATION_IMPLEMENTATION.md#sequence-and-authority) |
| CF28 | Ten focused milestones in F1–F10 order | Expose integration failures early and give each delivery an observable result. | [Implementation](CORE_GAME_FOUNDATION_IMPLEMENTATION.md#sequence-and-authority) |
| CF29 | Focused readiness review and closure | Resolve dependencies and acceptance gaps before proceeding to the next scope. | [Implementation](CORE_GAME_FOUNDATION_IMPLEMENTATION.md#sequence-and-authority) |
| CF30 | Permanent foundation before integrated factory gameplay | Build the opening on lasting systems and supersede the separate factory-loop prototype prerequisite. | [Implementation](CORE_GAME_FOUNDATION_IMPLEMENTATION.md#sequence-and-authority) |
| CF31 | Deposit-owned persistent manual mining progress | Interrupted work must survive switching targets, scene unloads and save/load. | [Architecture](CORE_GAME_FOUNDATION_ARCHITECTURE.md#deposit-progress) |

## Foundation F2 decisions

| ID | Owner-approved selection | Scope |
| --- | --- | --- |
| F2-A | Option B — Focused Separation | Share the existing combat-capable player between the permanent session and standalone arena. The arena owns encounter orchestration. [F2 specification](FOUNDATION_F2_SHARED_PLAYER.md#decision-register-and-scope) |
| F2-B | Option B — Context-Owned HUD | The player owns gameplay state. Each context owns the screen-space presentation of that state. [HUD state contract](FOUNDATION_F2_SHARED_PLAYER.md#hud-state-contract) |

## Foundation F3 decisions

| ID | Owner-approved selection | Scope |
| --- | --- | --- |
| F3-A | Option B — Typed Records with Central Registry | Each permanent session owns its typed, validated records. Records outlive their runtime instances. [Record ownership](FOUNDATION_F3_WORLD_STATE.md#f3-a--typed-records-with-central-registry) |
| F3-B | Option B — Location-Scoped Persistent Object IDs | An authored location ID and object ID identify a location-owned record within its playthrough. Reserve session scope for entities such as future player state. [Identity](FOUNDATION_F3_WORLD_STATE.md#f3-b--location-scoped-persistent-object-ids) |
| F3-C | Option B — Explicit Location-Managed Registration | The location coordinator prepares and validates the complete set before binding. Only the current binding may request changes or unbind. Unload preserves records for the next instance. [Registration lifecycle](FOUNDATION_F3_WORLD_STATE.md#f3-c--explicit-location-managed-registration) |
| F3-D | Option B — Versioned Envelope and Independently Versioned Typed Records | Encode scoped identities, types, versions and persistent values. Validate the entire candidate before adoption. Failed decode preserves valid state. [Serialization contract](FOUNDATION_F3_WORLD_STATE.md#f3-d--versioned-envelope-and-independently-versioned-typed-records) |
| F3-E | Option B — Visible Development-Only Persistent State Marker | An inspectable placeholder marker demonstrates registration, mutation, preservation through unload, restoration on rebind and fresh-session isolation. [Marker exercise](FOUNDATION_F3_WORLD_STATE.md#f3-e--visible-development-only-persistent-state-marker) |

## Recording future decisions

Append decisions in approval order with a stable ID, descriptive title, approved selection, brief summary, and a link to the authoritative specification. Record dates only when supplied. When a decision changes, retain the earlier entry and link it to the approved replacement.
