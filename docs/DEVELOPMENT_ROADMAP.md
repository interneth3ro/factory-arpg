# Factory ARPG — Development Roadmap

**Status:** Planning reference — proposed roadmap, subject to owner approval and revision  
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
| 1. Finish combat prototype | Readable, satisfying, testable melee combat | **CONDITIONAL PASS** — owner evaluation complete |
| 2. Validate integrated factory loop | Exploration → Combat → Resources → Automation → Upgrades → Further exploration | The two defining gameplay pillars reinforce one another |
| 3. Begin actual game production | Permanent opening region, home base, systems and content | A playable opening exists with persistent progression |
| 4. Complete a vertical slice | A cohesive, representative segment of the intended game | A polished end-to-end experience demonstrates the game’s identity |
| 5. Expand the game | Content, progression depth, world and systems | Iterative production against approved scope and quality gates |

**Production transition:** The default switches from isolated prototypes to permanent game development **after Phase 2's integrated-loop gate**. This is a proposed transition policy, not a fixed date. Earlier integration into the permanent starting region remains a viable owner-approved alternative.

## 4. Phase 1 — Finish the combat prototype

### Goal

Prove that the current combat mechanics feel responsive, legible, and enjoyable in a short encounter without expanding prematurely into full RPG combat systems.

### Completed evaluation

The owner completed all 18 baseline attempts and approved **Phase 1 — CONDITIONAL PASS**. EVAL-01 (greatsword timing against the Pursuer) is Minor, deferred, and non-blocking. Further combat tuning is unnecessary before Phase 2 planning. [Evaluation results and owner disposition](design/PHASE_1_COMBAT_EVALUATION_RESULTS.md)

PR #26 delivered the shared combat-style input foundation for slots 1–4 in the standalone arena. PR #27 delivered Physical Pistol Combat. Magic implementation remains deferred indefinitely pending further design review. [Combat extension design](design/RANGED_MAGIC_COMBAT_INPUT.md)

The owner completed all eight trials of the **Phase 2 combat evaluation — PASS**. No immediate combat correction is required. Broader gameplay planning may proceed. The roadmap's integrated factory-loop exit gate remains open. [Phase 2 combat evaluation results](design/PHASE_2_COMBAT_EVALUATION_RESULTS.md)

### Exit gate

- All three weapons are distinguishable in use and feedback.
- Hits, misses, enemy wind-ups, damage, and death are understandable.
- Dodge and attack responsiveness are acceptable in real play.
- A short encounter with existing enemies is enjoyable enough to serve as a baseline.
- No known critical defects prevent reliable evaluation or continuation.

### Explicitly out of scope for this gate

Full class rosters, bosses, every weapon category, large skill trees, exhaustive enemy variety, and final art/audio polish. These can be built in production unless a particular risk requires isolated validation.

## 5. Phase 2 — Validate the integrated factory loop

### Goal

Test Factory ARPG's central proposition: **combat and exploration provide reasons to automate, while automation meaningfully changes what the player can do next**.

### Minimal playable loop

1. Explore a small area and confront an obstacle or enemy.
2. Discover or acquire a resource.
3. Haul the resource home for integrated smelting and standardized component crafting.
4. Produce a useful upgrade or capability.
5. Return to exploration and experience a meaningful difference.

### Suggested minimal scope (provisional)

- One resource type, with additional resources only if the test cannot be meaningful otherwise.
- Test the remote extractor as the first major automation milestone. The player can collect its output and haul it home. A conveyor to nearby industrial storage is optional.
- Basic placement, interaction, production status, and recovery of mistakes.
- One upgrade with an observable gameplay consequence.
- A compact exploration/combat objective that closes the loop.

Prototype only the base services needed to demonstrate the upgrade. The full home-base order, reservation, and upgrade systems can be introduced progressively in production. Avoid complete logistics networks, research trees, recipe catalogs, or broad base-building systems at this stage.

### Exit gate

- The player understands why to gather resources and automate.
- Production operates reliably and can be understood without developer intervention.
- The upgrade has an observable effect on subsequent exploration or combat.
- The loop is interesting enough to justify expanding into permanent game content.
- Major architectural risks affecting production are identified and addressed or explicitly accepted.

**Integration choice:** This may be tested in a contained prototype area or built directly into the future opening region if the owner prefers to reduce disposable work. Decide before implementation.

## 6. Phase 3 — Begin actual game production

### Goal

Move from proving systems to building the real opening experience. **Production begins here; the game need not be feature-complete.**

### Initial production targets

- Permanent opening environment and small explorable region.
- First home base or shelter with room for early expansion.
- Reusable combat, resource, and production foundations adapted from prototypes.
- Introduce permanent recipes and a small set of upgrades as the player progresses from integrated smelting and component crafting to remote extraction. See the [approved opening progression](design/EARLY_GAME_GATHERING_AND_AUTOMATION.md#7-revised-opening-progression-rc1-rc6rc8).
- Introductory objectives connecting exploration, fighting, and reconstruction.
- Basic progression choices and persistent save/load behavior.
- Maintainable content and testing workflows appropriate for ongoing production.

### Exit gate

A player can start a new game, follow an introductory objective, explore, fight, automate a useful product, make meaningful progress, save, and resume. The experience uses permanent content rather than relying on a standalone test arena.

**Policy shift:** From this phase onward, build features in the actual game by default. Use isolated experiments only for a specific high-risk uncertainty, and plan their integration or retirement.

## 7. Phase 4 — Complete a vertical slice

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
| Combat feel and balance | Use the completed Phase 1 evaluation as the baseline |
| Minimal integrated automation loop | Essential focused validation |
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

1. Begin Phase 2 planning. Scope the minimal integrated loop and decide whether to use a separate test space or the permanent opening region. Implementation requires separate owner approval.
2. At Phase 2 exit, explicitly approve the production transition and begin building the actual game.

## 12. Roadmap maintenance

This is a living planning document. Update it when an exit gate is accepted, a phase boundary changes, or a material new risk emerges. Keep approved design decisions in the decision log; use this roadmap to explain **sequence, intent, and stopping conditions**, not to silently replace detailed specifications.
