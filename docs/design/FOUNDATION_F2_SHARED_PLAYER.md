# Foundation F2 — Shared combat-capable player

F2 brings the evaluated arena player into the permanent session. F1 shipped the entry and session lifecycle in PR #32. The decisions below are owner-approved design for the next milestone. Gameplay implementation and owner runtime acceptance are pending.

## Decision register and scope

| Decision | Owner-approved selection | Requirement |
| --- | --- | --- |
| F2-A | Option B — Focused Separation | Both contexts instantiate one reusable player scene. Extract arena orchestration from the existing coordinator and keep one implementation of movement and combat. |
| F2-B | Option B — Context-Owned HUD | The player owns gameplay state. Each context presents that state through its own screen-space HUD. Encounter controls, labels and diagnostics belong to the arena. |

CF1 and CF9 establish the shared scene and modular components. CF2 and CF3 give the session root one player whose lifetime spans locations. CF12 governs which context receives input. The other CF decisions retain their existing scope and milestone order. [Foundation architecture](CORE_GAME_FOUNDATION_ARCHITECTURE.md) · [Gameplay](CORE_GAME_FOUNDATION_GAMEPLAY.md) · [F1–F10 plan](CORE_GAME_FOUNDATION_IMPLEMENTATION.md) · [Decision log](DECISION_LOG.md#core-foundation-decisions)

Preserve the evaluated parameters, timing, contact rules, input and feedback for all four styles. The original selector and survivability records describe an earlier default-weapon reset. INT12 supersedes that part of E12 and M66 for F5. Decision 17 assigns Heavy only to F10. [Melee baseline](COMBAT_PROTOTYPE_V0.1.md) · [Survivability](PR16_PLAYER_HEALTH_DAMAGE_DEATH.md) · [Impact feedback](PR17_COMBAT_IMPACT_FEEDBACK.md) · [Pistol and input](RANGED_MAGIC_COMBAT_INPUT.md) · [Encounter controls](COMBAT_ENCOUNTER_SELECTOR.md) · [Evaluation criteria](COMBAT_BALANCE_ENCOUNTER_EVALUATION.md)

## Shared player and combat inputs

On merged main, the arena defines the player inline at `ArenaObjects/Player`. The body owns collision, aim markers, movement and action FSMs, health, melee sweep, projectile simulation, effects, audio and a Diagnostics canvas. Its coordinator also looks up sibling Pursuer and Heavy nodes, selects encounters, resets enemies, tests completion and writes HUD controls directly. These last responsibilities move to the arena. [Arena scene and signal connections](../../scenes/combat/combat_test_arena.tscn) · [Player coordinator](../../scenes/combat/combat_test_player.gd)

The reusable player owns its body and collision, normalized screen-relative movement, independent mouse aim, dodge and invulnerability, motion trace, action timing, weapon selection, health, incoming damage and death. Reuse the existing melee, pistol, world-space hit feedback, player visuals and combat audio components. Enemy recoil and telegraphs stay with their targets. [Movement FSM](../../scenes/combat/player_movement_fsm.gd) · [Action FSM](../../scenes/combat/player_action_fsm.gd) · [Slide trace](../../scenes/combat/slide_trace.gd) · [Health](../../scenes/combat/player_health.gd) · [Weapon effects](../../scenes/combat/weapon_effects.gd) · [Audio](../../scenes/combat/combat_audio.gd)

Keep slots 1–4 for Dagger, one-handed sword, greatsword and physical pistol. Preserve commitment, melee buffering, held attack, pistol cadence and successful dodge interruption. Keep one pending style during commitment or dodge. The latest valid request wins, with the higher slot winning an exact tie. A switch under held primary requires a fresh press to attack with the new style. Entry and session UI gestures must have a single recipient under CF12. [Input arbitration and HUD](RANGED_MAGIC_COMBAT_INPUT.md#combat-input-and-hud) · [Pistol firing](../../scenes/combat/pistol_firing.gd)

## Combat targets, environment and physics order

The arena supplies explicit enemy references and its environmental collision footprints. The F2 permanent session supplies an empty target configuration with no arena cover. Both configurations support the same player tick, including melee misses and bullets expiring at range. The player must work without named enemy siblings, an arena parent or a global combat service.

| Merged dependency | Contract across extraction |
| --- | --- |
| [Enemy movement](../../scenes/combat/enemy_movement.gd) resolves the player through its arena-relative path and reads the player's motion trace. | Bind the actual player. Preserve player-first physics (currently priority −1), resolved slide legs, navigation maps, avoidance dispatch and the frame- and generation-tagged movement command. Attacks must see motion from the same tick. |
| [Enemy attacks](../../scenes/combat/enemy_attack.gd) resolve the player collision shape and Action FSM by path. Each attack reports contacts directly to the player. | Preserve consumed melee hitstop, clipped contact geometry and contact-time dodge protection. Keep direct avoidance callbacks and one deferred drain in the same physics iteration. Resolve by verified contact time, then enemy name and execution ID. Preserve lethal attribution and rejection of stale frames and generations. |
| [Pistol projectiles](../../scenes/combat/pistol_projectiles.gd) receive an enemy list and damage callback, but currently obtain solid footprints from the tree during configuration. | Supply the context's geometry at a valid lifecycle stage. Preserve the muzzle sweep, nearest eligible hit, solid precedence on exact ties, ordering across shots and the final clipped range sweep. In-flight shots survive style changes. Death and reset invalidate them. Pistol hitstop applies to the struck target's attack clock. |
| [Melee sweep](../../scenes/combat/melee_sweep.gd) queries the target collision mask over the moving body's resolved path during Active intervals. The query excludes its owning body. | Preserve sampled capsule geometry, matched enemy shapes and query order. Apply damage once per target per attack, only for the interval being resolved. Preserve offensive hitstop, trail timing, contact bursts and audio even when a tick spans phase boundaries. |

## Standalone arena and reset

A narrowly scoped arena controller or equivalent arena-owned code selects and activates enemies, owns the encounter generation, coordinates reset and enemy rest after player death, and determines completion from participating enemies. The arena owns its navigation, collision environment and development controls. Direct scene launch must work independently of the game root, world-state records and saves.

| Focused arena input | Accepted behavior |
| --- | --- |
| Startup, F7, F10, F9 | Startup selects Pursuer + Heavy. F7 selects Pursuer only, F10 Heavy only and F9 both. Every selection, including a repeat, resets to a fresh encounter with Dagger. |
| F5 | Reset the current configuration. Preserve the **active** style and F3 visibility, clear pending selection, restore full HP and spawn positions, and require a fresh attack press. |
| F3 | Toggle diagnostic text and combat geometry overlays. Health, style, encounter label, gameplay telegraphs and applicable death or completion messages remain visible independently. |

Reset takes precedence over combat input for the tick. The arena advances the generation first, invalidates outstanding contacts and movement commands, and coordinates both sides of the reset. Enemies regain spawn, HP and visuals. Excluded enemies are hidden and have no collision, avoidance, movement or attacks. Reselecting them restores participation. Defeating the last participating enemy shows completion.

The reusable player reset restores HP, spawn pose, movement, dodge and action state. It applies the caller's style rule, clears pending and held attack execution, projectiles, sweep and contact history, hitstop, damage flashes, collapse tween, effects and audio. Death ends player actions and pending damage from bullets. The arena rests surviving enemies, and a later reset clears terminal presentation. No prior interval, queued contact or projectile may damage the reset encounter.

## Permanent session lifecycle

The configured main scene is the permanent entry. F1 guards Start Session, constructs a candidate session off-tree and initializes its placeholder under `ActiveLocation`. Only successful preparation attaches the session and exposes End Session. A failed attempt frees the candidate, displays an error and re-enables Start. End Session tears down the location and frees the session before Start becomes available again. [Project settings](../../project.godot) · [Entry scene](../../scenes/game/permanent_game_entry.tscn) · [Entry script](../../scenes/game/permanent_game_entry.gd) · [Session scene](../../scenes/game/game_session_root.tscn) · [Session script](../../scenes/game/game_session_root.gd)

F2 extends each successful session with exactly one player owned by the session root independently of the replaceable location. A player host beside `ActiveLocation` is one possible layout. Future travel will retain that instance. Ending the session releases it, its HUD bindings and transient effects. Starting again creates a fresh player and location.

Prepare references and validate required resources while off-tree. Defer operations that require ready children, a world, tree groups or an attached HUD until those dependencies exist. A failed start must still leave the entry usable, with no partial player or active session. The placeholder currently draws a full-size ColorRect and centered label. Check draw order, spawn visibility and UI input when presenting the player alongside it. [F1 placeholder](../../scenes/game/f1_placeholder_location.tscn)

## HUD state contract

Expose current and maximum HP, active and optional pending style, alive/dead status, and the combat phase, dodge protection, damage feedback and contact outcomes needed by the existing displays. Each HUD reads the initial state when bound and reflects subsequent changes, including reset. Existing health, damage and death signals are a starting point. Either signals or read-only queries can expose the remaining state.

The permanent session presents basic HP and active/pending style. The arena preserves its fixed upper-left bar and numeric HP, damage emphasis, style and encounter labels, centered death message and completion display. F3 retains player and enemy diagnostics, including inactive enemies, last hit and hitstop, and the five most recent incoming contact decisions in order. Presentation consumes the player's resolved results. Neither HUD owns health, chooses the winning style or applies damage.

## Verification for the implementation PR

**Static review**

- Trace both entry paths to the same player scene. Confirm one instance per session outside the location, no global player, and no required arena, enemy or HUD paths in the player. Trace successful start, partial failure, end and another start.
- Check context configuration and signal connections before first input and physics. Trace reset priority, generation invalidation, camera and canvas placement, and HUD access through death and teardown. Compare Input Map actions, weapon resources, collision masks and physics order with the merged baseline.
- Inspect all three existing fixtures. They preload the coordinator and locate the inline player. Some access private encounter methods, enemy lists and HUD fields. Reconcile references in the later implementation while preserving their behavioral assertions for contact timing, weapon feedback, selector controls and pistol collision. Apply the metadata policy to any resource changes. [Player contact fixture](../../tests/combat/player_contact_acceptance.gd) · [Weapon feedback fixture](../../tests/combat/weapon_feedback_acceptance.gd) · [Pistol fixture](../../tests/combat/pistol_acceptance.gd) · [Metadata policy](../GODOT_METADATA.md)

**Owner Godot 4.7.2 runtime acceptance** — pending a separately authorized implementation. Record the tested revision, outcomes and exceptions.

- [ ] Run Project, start a session and confirm one visible player, the placeholder, full HP and a style display. Move, aim, dodge, swing all three melee styles and fire the pistol into empty space. Queue a switch during commitment and check the HUD and fresh-press behavior.
- [ ] End while combat effects are active and start again. Verify fresh state, one player and one HUD, working entry controls and no surviving bullets, audio or input. Arena development keys have no permanent-session effect.
- [ ] Launch the arena directly. Check combined startup, F7/F10/F9, repeated selection and reactivation. Each selection starts with Dagger. Excluded enemies have no influence. Defeat the active enemies in solo and combined encounters and check completion with F3 closed.
- [ ] Land melee and pistol hits, shoot toward cover, dodge through a strike, take damage and die. Compare hitstop, telegraphs, sound, trails, recoil, damage emphasis, HP and death presentation with the accepted baselines. Toggle F3 and inspect contact history and geometry.
- [ ] Use F5 during combat with a non-Dagger style, a pending switch and primary held. Repeat from death or completion, with F3 open and closed. Verify style and selection survive, HP and spawns reset, pending work clears and no stale hit or held attack fires. Then reselect the same encounter and verify Dagger.

## Exclusions and handoff

F2 excludes a comprehensive player refactor, combat redesign or rebalance, new weapons or enemies, permanent-world encounters, inventory, mining, gathering, interaction and storage UI or gameplay. World-state records, persistent IDs, saves, serialization, slots, authored starting region, home base and location transitions belong to later milestones. Generalized gameplay, lifecycle and UI frameworks are outside scope.

Prefer small context bindings around existing modules. The exact scene and node names, host layout, controller shape, method signatures and HUD notification mechanism remain implementation choices. This documentation PR changes no gameplay, fixtures, artwork, assets or metadata. Implementation requires independent review and owner merge of the specification, fresh-session authorization and separate approval for engine execution. Surface any conflict with the approved baseline to the owner before changing behavior.
