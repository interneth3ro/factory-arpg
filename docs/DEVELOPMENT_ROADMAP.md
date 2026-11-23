# Factory ARPG — Development Roadmap

**Status:** Phase sequence approved under CF30. Later content examples remain provisional.\
**Updated:** 2026-11-22\
**Repository:** `interneth3ro/factory-arpg`  
**Target path:** `docs/DEVELOPMENT_ROADMAP.md`  
**Engine:** Godot 4.7.2

> **Guiding principle:** Prototype the essential risks, then build the actual game. A prototype is justified by a major unanswered gameplay or technical question—not merely because a feature is new.

## 1. Purpose and boundaries

Factory ARPG is a post-apocalyptic fantasy isometric action RPG/factory game combining responsive combat, exploration, classes and builds, automation, technological reconstruction, and a developing home base.

This roadmap defines **when to stop isolated prototyping and begin building permanent game content**. It is a broad sequencing guide, not an implementation specification, feature freeze, delivery schedule, or authorization to change previously approved mechanics.

**Project separation:** This repository and its decisions are independent of *The Long Way Home*. Do not transfer that project's requirements, assets, or design assumptions.

**Authority:** `AGENTS.md`, `docs/README.md`, `docs/design/COMBAT_PROTOTYPE_V0.1.md`, `docs/design/DECISION_LOG.md`, and relevant feature specifications remain authoritative for implementation. If this roadmap conflicts with an approved decision, surface the conflict for owner resolution; do not silently override it.

## 2. Current baseline

As of 2026-11-20, PRs #13–#16 have established the combat foundation:

- Screen-relative movement, independent facing, dodge and invulnerability.
- Dagger, one-handed sword, and greatsword with distinct combat characteristics.
- Enemy health, pursuit/navigation, engagement spacing, attack phases and telegraphs.
- Pursuer and Heavy enemy archetypes.
- Player health, enemy damage, deterministic contact handling, damage diagnostics, death, and encounter reset.

PR #16 is merged and cleaned up. PR #18 documented the [combat impact and feedback milestone](design/PR17_COMBAT_IMPACT_FEEDBACK.md), originally labeled PR #17. PR #19 delivered M75–M90, passed independent review and all 12 owner runtime checks, and was manually merged. The owner confirmed cleanup for PRs #18 and #19.

## 3. Roadmap at a glance

| Phase | Focus | Exit gate |
| --- | --- | --- |
| 1. Completed combat foundation | Three melee styles and the physical pistol in the standalone arena | Owner evaluated melee (conditional pass) and all eight follow-up combat trials (pass) |
| 2. Permanent core game foundation | F1–F10 in the actual game | Explore, mine, store, save and resume safely with independent slots and a working regression arena |
| 3. Integrated factory gameplay | Extend the permanent opening from manual gathering to integrated processing and remote extraction | A useful output or upgrade feeds further exploration or combat |
| 4. Complete a vertical slice | A cohesive, representative segment of the intended game | A polished end-to-end experience demonstrates the game’s identity |
| 5. Expand the game | Content, progression depth, world and systems | Iterative production against approved scope and quality gates |

**CF30 supersession.** Earlier planning placed a separate integrated factory-loop prototype gate before permanent production. CF30 moves that validation into the permanent game after its core foundation. The combat evaluations retain their historical phase names and outcomes. [Core Foundation decisions](design/DECISION_LOG.md#core-foundation-decisions)

## 4. Phase 1 — Completed combat foundation

### Goal

Prove that the current combat mechanics feel responsive, legible, and enjoyable in a short encounter without expanding prematurely into full RPG combat systems.

### Completed evaluation

The owner completed all 18 baseline attempts and approved **Phase 1 — CONDITIONAL PASS**. EVAL-01 (greatsword timing against the Pursuer) is Minor, deferred, and non-blocking. The owner deferred further tuning unless integrated play reveals a responsiveness issue. [Evaluation results and owner disposition](design/PHASE_1_COMBAT_EVALUATION_RESULTS.md)

PR #26 delivered the shared combat-style input foundation for slots 1–4 in the standalone arena. PR #27 delivered Physical Pistol Combat. Magic implementation remains deferred indefinitely pending further design review. [Combat extension design](design/RANGED_MAGIC_COMBAT_INPUT.md)

The owner completed all eight trials of the **Phase 2 combat evaluation — PASS**. No immediate combat correction is required. This completes the combat foundation for reuse in the permanent game. [Phase 2 combat evaluation results](design/PHASE_2_COMBAT_EVALUATION_RESULTS.md)

### Exit gate

- All three weapons are distinguishable in use and feedback.
- Hits, misses, enemy wind-ups, damage, and death are understandable.
- Dodge and attack responsiveness are acceptable in real play.
- A short encounter with existing enemies is enjoyable enough to serve as a baseline.
- No known critical defects prevent reliable evaluation or continuation.

### Explicitly out of scope for this gate

Full class rosters, bosses, every weapon category, large skill trees, exhaustive enemy variety, and final art/audio polish. These can be built in production unless a particular risk requires isolated validation.

## 5. Phase 2 — Permanent core game foundation

Build the permanent session and reusable combat-capable player, then give them persistent world records and a small handcrafted region connected to a separate home base. Prove player location and position restore early. Add the backpack, physical general storage and manual mining before completing autosaves and independent playthrough slots. The starting world is free of enemies during this phase. The standalone arena remains the combat regression environment.

**Exit gate.** F10 demonstrates the full trip from gathering to home storage and back, including interrupted mining, conservation of items and safe resume. The owner verifies independent slots and accepted arena behavior. The ten milestones and their individual acceptance gates are defined in the [foundation implementation plan](design/CORE_GAME_FOUNDATION_IMPLEMENTATION.md).

## 6. Phase 3 — Integrated factory gameplay

Build on the accepted permanent foundation. Preserve the approved loop of exploration, combat, resources, automation, upgrades and further exploration. The [reconciled opening progression](design/EARLY_GAME_GATHERING_AND_AUTOMATION.md#7-revised-opening-progression-rc1-rc6rc8) governs the factory sequence.

1. Haul the two introductory materials home and deposit them into the chosen eligible storage. The base integrates smelting and standard component crafting through dedicated inventories. RC5 keeps general storage isolated.
2. Use integrated crafting to manufacture the first remote extractor, the first major automation milestone. Deploy it by a compatible deposit, collect its output and haul ore home.
3. Optionally extend local output capacity with a conveyor to nearby industrial storage. Preserve finite capacity and backpressure. Specialized physical manufacturing follows when a process warrants it.

**Exit gate.** The player can explain the benefit of automation, operate the loop without developer intervention and use its output for an observable gain in subsequent exploration or combat. Detailed factory implementation still requires scoped approval.

## 7. Phase 4 — Representative vertical slice

### Goal

Deliver one cohesive section that represents the intended experience rather than a disconnected feature demonstration.

### Illustrative content (not locked)

- A recognizable and functional home base.
- A small region with distinct destinations, enemies, resources, and discoveries.
- A working early factory with useful output.
- A meaningful objective or challenge that uses combat and technological progress.
- Introductory progression, save/load, readable UX, and coherent presentation.

A **20–40 minute experience** is an illustrative planning target, not a fixed content requirement. Quality and completeness matter more than duration.

### Exit gate

A fresh player can complete a coherent beginning-to-end segment that communicates the game's identity, supports meaningful decisions, and demonstrates production-quality integration of its core pillars.

## 8. Phase 5 — Expand the game

Scale approved foundations through iterative content and system development:

- Additional regions, biomes, and exploration objectives.
- More enemy archetypes, encounters, weapons, abilities, classes, and builds.
- Deeper manufacturing, logistics, technological reconstruction, and home-base growth.
- Story, worldbuilding, and long-term progression.
- Performance, usability, accessibility, balancing, and content-production improvements.

Do not treat these as mandatory standalone prototypes. Introduce focused spikes only where the risk justifies their cost.

## 9. Prototype-versus-production decision rule

Before starting a separate prototype, ask:

1. What important gameplay or technical uncertainty are we trying to resolve?
2. Can we answer it safely inside the actual game instead?
3. What is the smallest test and measurable success criterion?
4. Which work will be reused, integrated, or intentionally discarded?
5. What decision will the test enable, and when will it end?

If there is no clear uncertainty and exit criterion, **prefer production implementation**.

Examples:

| Feature | Default approach |
| --- | --- |
| Core melee and enemy behavior | Existing prototype foundation |
| Combat feel and balance | Use the completed melee and follow-up combat evaluations as the baseline |
| Minimal integrated automation loop | Validate in the permanent game after the foundation |
| Every class, weapon, and enemy | Build incrementally in production |
| Complete crafting and technology trees | Build incrementally in production |
| Advanced logistics | Prototype only a specific unresolved risk |
| Quests, story, regions, home-base content | Build in the actual game |
| Progression systems | Start small in production; validate risky mechanics as needed |

## 10. Milestone governance and workflow

- **No roadmap item authorizes implementation by itself.** Scope is approved through numbered design decisions, one at a time, with meaningful alternatives and tradeoffs.
- Maintain a cumulative decision record and standalone downloadable Markdown specification for each feature PR.
- Inspect the live repository before implementation prompts; attach the approved specification to the Codex request and require Codex to stop if it cannot access it.
- Use a traditional feature branch in the primary checkout, a Draft PR, independent review of the exact diff/head, owner Godot acceptance, repository pre-merge verification, owner manual merge, and separate post-merge cleanup.
- Do not launch Godot, import the project, run scenes, or execute headless engine tests without explicit owner authorization.
- Preserve owner files, assets, settings, evidence, and unrelated changes.
- Revisit this roadmap at each phase exit gate; record changes explicitly rather than allowing prototype scope to grow by default.

## 11. Immediate next steps

PR #31 established CF1–CF31. The owner accepted the F1 permanent entry and session lifecycle at `fbed32b8b24f5cedbbc1e5787a4d3a046bc9dc37` and manually merged PR #32. [Launch and lifecycle](README.md#permanent-game-entry-and-session-lifecycle)

F2 is the next implementation milestone. Its approved design shares the combat-capable player between the permanent session and standalone arena, with each context owning its HUD. Implementation awaits separate authorization. [F2 specification](design/FOUNDATION_F2_SHARED_PLAYER.md) · [F1–F10 plan](design/CORE_GAME_FOUNDATION_IMPLEMENTATION.md)

## 12. Roadmap maintenance

This is a living planning document. Update it when an exit gate is accepted, a phase boundary changes, or a material new risk emerges. Keep approved design decisions in the decision log; use this roadmap to explain **sequence, intent, and stopping conditions**, not to silently replace detailed specifications.
