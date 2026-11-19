# Factory ARPG — Combat Prototype v0.1

**Status:** Frozen — Approved Design Baseline

- **Frozen:** 2026-11-19
- **Repository:** https://github.com/interneth3ro/factory-arpg
- **Engine:** Godot 4.7.2 · GDScript · Forward Plus
- **Purpose:** Authoritative design baseline for scoped combat-prototype implementation.

> Decisions A1–A16 and the established project constraints are approved. Proposed approaches and provisional tuning remain open for scoped planning and testing. Deferred functionality is outside v0.1.

## 1. Project identity and vision

Factory ARPG is a new, independent post-apocalyptic fantasy isometric action RPG/factory game. It is separate from *The Long Way Home*; reuse lessons and workflow conventions, not assumed code, assets, or requirements.

The long-term vision combines fast responsive combat, classes and builds, exploration of interconnected regions and dungeons, factory automation and technological reconstruction, and a developing home base. An ancient technological civilization's encounter with an unknown force caused an apocalypse and introduced magic. Some regions contain spatial, temporal, or material anomalies. The prototype does **not** implement these broader systems.

**Prototype objective:** Determine whether WASD movement, mouse aiming, melee attacks, and dodging feel enjoyable and predictable in native 2D Godot with an isometric visual presentation. Prioritize responsiveness, readable combat, distinctive weapon handling, and testability over polish or feature breadth. Inspiration: Path of Exile's fluidity, not its extreme monster density, rarity tiers, or visual clutter.

## 2. Approved decision register

| ID | Approved choice | Binding behavior |
|---|---|---|
| A1 | A — Screen-relative WASD | W/up, S/down, A/left, D/right on screen; normalized diagonal movement, independent of isometric artwork. |
| A2 | C — Movement priority, aim fallback | Dodge follows current WASD vector if held; otherwise mouse-facing direction. Direction locks when dodge begins. |
| A3 | B — Immediate burst with deceleration | High initial dodge velocity, smooth deceleration, consistent intended distance when unobstructed; solid collision applies. |
| A4 | B — Brief early invulnerability | I-frames begin when dodge actually starts and end before movement ends; protect against ordinary enemy damage, not solid obstacles. |
| A5 | B — Short dodge recovery | Brief interval after dodge movement before another dodge; ordinary movement and eligible attacks remain available; Space during recovery does not queue another dodge. No automatic Energy cost. |
| A6 | C — Hold-to-repeat and buffering | LMB attacks, hold repeats when allowed; late-recovery clicks may buffer one next attack, with short expiry; release stops repetition, not the attack already underway; dodge clears pending basic attacks. |
| A7 | C — Weapon-dependent aim commitment | Dagger: bounded correction during active swing; sword: lock at active start; greatsword: lock in late wind-up. Character facing may track mouse independently of locked attack arc. |
| A8 | B — Phase-dependent movement penalties | Weapon/attack wind-up, active and recovery phases apply distinct ordinary-movement modifiers; no automatic attack lunges; dodge burst speed unaffected. |
| A9 | C — Time-swept melee arcs | Hit region progresses through arc during active phase; account for angular travel between physics updates; at most one damage application per target per attack. |
| A10 | B — Lightweight weapon-scaled feedback | Brief hit flashes, small visual reactions, restrained hitstop; dagger light, sword moderate, greatsword heavier. Avoid whole-SceneTree pauses and initial screen shake. |
| A11 | C — Hybrid enemy telegraphs | Pursuer uses pose/color timing cues without persistent ground warning; Heavy has longer wind-up and subtle ground warning arc matching actual attack geometry. |
| A12 | C — Limited tracking then commitment | Enemy aims at current player position with bounded turning during early wind-up; locks direction in late wind-up; active strike cannot retarget. Heavy arc freezes at commitment. |
| A13 | B — Pursuit with engagement spacing | Archetype-specific preferred attack distance and tolerance to prevent jitter; pursuit, attack, recovery, re-engagement and disengagement; no tactical flanking. |
| A14 | B — Simple player health and controlled death | Fixed configurable health, visible bar, hit feedback, terminal death state, manual restart; no healing, armor, resistances, or general post-hit immunity in v0.1. |
| A15 | B — Enemy defeat state and manual reset | Configurable enemy health; terminal defeat cancels actions and collision; brief defeat feedback; completion message when all enemies defeated; no automatic respawn. |
| A16 | A — Native 2D with isometric presentation | Standard Node2D/CharacterBody2D/2D physics; angled appearance through artwork, geometry, and Y-sorting. No separate isometric simulation-coordinate transformation for combat. |

## 3. Controls and movement

**Approved:** Screen-relative WASD, normalized diagonals, independent mouse-directed aiming; no traditional click-to-move. Universal dodge provisionally assigned Space. Controller support is a future goal, not v0.1.

**Proposed initial test bindings:** LMB basic attack; Space dodge; keys 1/2/3 select dagger/sword/greatsword; F3 toggles diagnostics; F5 resets encounter. These are provisional bindings beyond already approved movement/attack/dodge controls. Switching weapons only while not attacking/dodging is a proposed initial restriction; avoid a weapon-switch cancellation system now.

**Movement behavior:** Immediate, predictable response. During attacks, the Action FSM supplies a phase-specific movement multiplier; Movement FSM owns actual velocity and collision. When an attack ends or is interrupted, its modifier must clear promptly. No automatic movement toward melee targets.

## 4. Dodge specification

- Direction selection at **dodge start**: normalized held WASD vector, else current mouse-facing direction. Lock trajectory for full dodge; mouse/WASD changes cannot steer it mid-dodge.
- Immediate high-speed burst, smoothly decelerating toward completion; unobstructed distance should be consistent and tunable. Solid collision remains in effect.
- Brief early invulnerability starts with actual dodge execution, not a buffered request; expires before dodge movement finishes. Applies to ordinary enemy melee/projectile damage; does not bypass world collision.
- A short dodge-specific recovery interval begins after dodge movement. Movement and permitted attacks remain responsive; no repeated dodge until recovery ends. Space pressed during recovery is not queued.
- Dodge has priority over routine attacks. Powerful attacks may have brief noncancelable commitment windows; dodge inputs in those windows may be buffered and must expire rather than fire unexpectedly late. **The exact buffered-direction sampling policy is not yet fixed.**
- Dodge does not automatically consume the future shared Energy ability resource. Class/equipment modifications are future scope.
- Exact dodge distance, speed curve, total duration, i-frame duration, recovery and buffer lifetimes are **provisional tuning values**, not frozen numbers.

## 5. Basic melee and weapon behavior

**Basic attack input:** LMB click initiates an attack when eligible; hold repeats at the earliest allowed transition. Releasing LMB prevents additional repetitions but does not cancel the current strike. A late-recovery click may buffer **one** next basic attack, with short expiry. Dodge cancels eligible attacks and clears pending basic attack inputs. Avoid unwanted attack execution after dodge.

**Attack phases:** Wind-up → Active → Recovery. Attack presentation and damage must align with the active hit region. Cancellation windows, commitment points, movement modifiers, reach, arc, sweep direction and timings are attack/weapon data, preferably custom Godot `Resource` definitions.

| Property | Dagger | One-handed sword | Greatsword |
|---|---|---|---|
| Tempo | Fast | Moderate | Slower, committed |
| Reach | Short | Medium | Longer |
| Arc | Narrow | Balanced | Broad |
| Mobility | High | Medium | More restricted |
| Aim commitment | Small bounded active corrections | Locks at active start | Locks during late wind-up |
| Dodge cancel | Generally permissive | Generally permissive | Brief noncancelable commitment possible |
| Impact | Light | Moderate | Stronger |

During wind-up, attacks can follow the mouse until their weapon-specific lock point. Character facing may remain responsive without redirecting a committed attack hit region. Subtle aim assistance may favor nearby enemies within a narrow cone but must not cause lunge, dramatic rotation, or silently enlarge hit reach/arc. Exact assistance angles remain undecided.

**Time-swept hit detection:** Attack geometry progresses over time through the active arc, not a one-frame full-cone hit or a static continuous damage zone. Check the region traversed between successive physics steps to avoid tunneling; each target can be damaged at most once per attack instance. Keep targeting, geometric collision, damage, and presentation separate. Provide optional debug sweep visualization. No complex skeletal/weapon physics required.

**Impact feedback:** brief target flash, modest reaction, and subtle weapon-scaled hitstop. Keep input and unrelated simulation responsive; do not pause the entire SceneTree. Ordinary visual hit reactions do not automatically stagger/intercept enemy attacks. Greatsword knockback may be evaluated if necessary; no initial screen shake. Exact feedback durations and strengths remain tunable.

## 6. Enemies and encounter behavior

**Two prototype archetypes only:**

- **Pursuer:** Aggressive, faster approach, close melee spacing, short readable wind-up and recovery; telegraph through pose/color cues, no persistent ground warning.
- **Heavy:** Slower approach, somewhat greater preferred engagement distance, longer readable wind-up and recovery, subtle threatened-region ground arc.

Both detect, pursue, position within a tolerance band, prepare attacks, commit, strike, recover, and resume pursuit or disengage when the player gets sufficiently far away. They stop ordinary pursuit during attack execution. Start attacks only when validly in range; moving away during wind-up does not automatically cancel an already initiated attack. No predictive targeting, coordinated packs, flanking, elaborate pathfinding, or monster rarity tiers.

**Enemy aim:** bounded turning toward player's *current* position in early wind-up; direction freezes at a configurable commitment point before active frames. Pursuer has a short commitment interval; Heavy has a clearer longer one. Heavy's warning arc follows aim early and freezes at commitment. Warning zones communicate the actual prospective attack area; they never independently cause damage. Actual hit geometry and active timing determine damage. Attacks cannot snap around to follow the player during active frames.

**Health and defeat:** Both enemy types have configurable fixed health. At zero, terminate attack, movement, telegraph and queued actions; enter terminal defeat; stop blocking player movement and stop receiving damage. Show brief defeat feedback, then hide/remove as appropriate. All enemies defeated triggers a simple completion indication. No automatic enemy respawn.

## 7. Player health, death and repeatable reset

- Configurable fixed maximum health and per-archetype attack damage; simple always-visible health bar and damage flash.
- Apply damage only after hit validation and defense checks. During dodge i-frames, ordinary enemy hits do not reduce health. Each enemy attack instance must not repeatedly damage the same player through continued overlap.
- At zero health, enter terminal death, clear buffered input and stop movement/attacks/dodge. Manual reset is available; do not instantly restart on death.
- Reset restores player and enemy positions, health and FSMs, clears transient attacks, invulnerability and input buffers, and restores a consistent initial encounter. Use one reset path for death and completed encounters.
- Do not introduce healing, armor, resistances, leveling, loot, experience penalties or general post-hit invulnerability yet.

## 8. Godot technical architecture — proposed implementation approach

**Approved architectural direction:** Prefer modular, Godot-style node-based finite state machines rather than a monolithic controller. Keep movement, targeting, attack execution, hit detection, and presentation distinct. Avoid a speculative large framework.

**Proposed coordinated player FSMs:**

- Movement FSM: Idle, Moving, Dodging, Disabled (or equivalent).
- Action FSM: Ready, Wind-up, Active, Recovery, Disabled (or equivalent).
- Small player coordinator: collects input intent, arbitrates interruptions, supplies movement modifiers, and manages dodge/attack buffer interaction. The FSMs should not arbitrarily mutate each other's internals.
- Death overrides everything. Dodge overrides eligible routine attacks; commitment windows can defer eligible buffered dodge requests. Attack phases govern normal action execution while movement remains independently responsive.
- Movement FSM alone owns final player velocity and collision. Action FSM owns attack phase, directional commitment, and attack state. Hit detection, damage validation, and presentation are separate responsibilities.
- Enemy behavior should also use small, modular FSMs, with no elaborate global AI managers.
- Data-driven attack and weapon definitions using Godot Resources; do not create a general class/skill/ability framework for this prototype.

The exact node names, paths, signals, Resource schemas and scene decomposition are **not frozen**; inspect the repository and refine them per focused PR. The proposed architecture should be evaluated incrementally, not fully scaffolded upfront.

## 9. Arena and diagnostics — proposed details

A fixed small combat test arena with native 2D collision, isometric-looking ground/environment, boundaries, a few obstacles, and known player/Pursuer/Heavy starting positions. Placeholder art is sufficient. Do not build world streaming, procedural environments or a level-management framework.

Show current movement/action states, selected weapon, attack phase, dodge readiness and invulnerability status. Optional toggles: active attack sweep, aim assistance cone, enemy warning region, and collision geometry. Provide simple health UI, encounter completion indication and manual reset.

**Tunable parameters:** base move speed; weapon-specific per-phase movement multipliers; attack wind-up/active/recovery durations; attack reach, arc and sweep; directional correction and lock points; input buffer expiry; dodge speed curve, distance, duration, i-frames and recovery; enemy detection/disengagement ranges, spacing tolerance, turning speed, attack timings and damage; health values and feedback durations. No illustrative percentages or milliseconds from design discussions are final balancing requirements.

## 10. Observable acceptance criteria

The owner should be able to verify the following through **explicitly authorized** Godot runtime tests, as relevant PRs land:

1. WASD responds promptly and diagonal movement is normalized; collision with obstacles is reliable.
2. Mouse-facing remains independent of movement; attack targeting follows intended direction.
3. Dodge uses WASD or aim fallback correctly, locks direction, bursts immediately and decelerates.
4. Dodge i-frames block ordinary damage only during the early window; recovery prevents instant repeated dodges without locking normal movement/attacks.
5. LMB hold repeats basic attacks; release stops future repetitions; a single short-lived buffer works and expires predictably.
6. Dodge cancellation respects brief commitment windows and clears unwanted pending basic attacks.
7. Dagger, sword and greatsword feel visibly different in tempo, reach, arc, mobility, direction locking and impact.
8. Active melee sweeps track the presented region, register collision reliably between physics frames and damage a target no more than once per attack.
9. Pursuer and Heavy visibly telegraph; Heavy warning freezes at commitment and matches actual danger geometry.
10. Enemy tracking ceases at commitment; active strikes do not snap toward the moving player.
11. Pursuit and engagement spacing do not oscillate at range boundaries; disengagement/re-engagement are understandable.
12. Damage, dodge immunity, health, death, defeat, and encounter completion work consistently.
13. Manual reset reliably restores the starting encounter and clears all transient combat states.
14. Diagnostic displays accurately reflect underlying state; no stuck states, unexpected delayed inputs, or collision ghosts.

Acceptance is primarily experiential and observable; do not claim numerical tuning or combat feel is validated without owner testing.

## 11. Explicitly out of scope for v0.1

Factory automation, extraction and logistics; classes and skill trees; attributes and leveling; equipment/inventory progression; loot rarity; firearms and magic; story/dialogue; world streaming and persistence; regional respawn; finished character artwork; full animation production; controller implementation; large-scale AI; procedural dungeons; complex stagger/poise; combo chains; elaborate effects; advanced tactical enemy behavior. No raids on factories or tower defense in the broader game vision.

## 12. Development workflow and provisional PR sequence

**Proposed subsequent focused work units (names/numbering provisional):**

1. Combat test arena, input map and placeholder foundation.
2. Player movement and mouse aiming.
3. Coordinated movement/action FSM foundations.
4. Dodge, cancellation and invulnerability.
5. Data-driven melee weapons and time-swept hit detection.
6. Pursuer and Heavy AI, telegraphs and defeat.
7. Combat feedback, health UI, diagnostics, reset and initial tuning.

Keep PRs small, independently reviewable and correctly sequenced. Begin from clean synchronized `main`, create a conventional feature branch in the primary checkout, implement through Codex Desktop, perform static validation and documentation-sync, push and open a **draft** PR. Owner reviews and merges; a separate Codex conversation performs authorized post-merge cleanup. **No Git worktrees or Codex Worktree mode without explicit owner authorization. Do not automatically merge. Do not launch Godot, run headless imports, execute scenes, or perform performance tests without explicit owner authorization.** Follow the [Godot metadata policy](../GODOT_METADATA.md), preserve owner files and existing UID identities, and use the read-only metadata validator. Never fabricate metadata to satisfy checks.

## 13. Documentation governance

Follow the [documentation conventions](../README.md) for changes to this baseline. The [decision log](DECISION_LOG.md) indexes approved choices and records their history.

**Freeze boundary:** The 16 decisions above and their associated behavior are approved. Proposed control additions, exact node organization, parameter values, attack/dodge timings, hitstop implementation details, and test-arena arrangement may be refined through scoped planning and hands-on testing without misrepresenting them as additional frozen decisions.
