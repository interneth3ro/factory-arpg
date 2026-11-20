# Factory ARPG — Development-Only Encounter Selector

**Status:** Owner-approved design, implemented on the feature branch pending runtime acceptance and merge\
**Approved:** 2026-11-20\
**Repository:** `interneth3ro/factory-arpg` (`main`)\
**Engine:** Godot 4.7.2\
**Milestone:** Phase 1 — Combat Balance & Encounter Evaluation\
**Scope:** Existing standalone combat test arena only

## 1. Purpose and authority

Provide repeatable Pursuer-only, Heavy-only, and combined encounters for the approved 18-attempt Phase 1 combat evaluation. The arena at design approval had both enemy instances but no confirmed direct isolation selector. This is a development-only evaluation convenience, not a gameplay feature, balancing change, or generalized encounter-testing framework.

Consult the current live repository before implementation planning, especially `AGENTS.md`, `docs/DEVELOPMENT_ROADMAP.md`, `docs/design/COMBAT_PROTOTYPE_V0.1.md`, `docs/design/DECISION_LOG.md`, `docs/design/COMBAT_BALANCE_ENCOUNTER_EVALUATION.md`, `docs/design/PR16_PLAYER_HEALTH_DAMAGE_DEATH.md`, `docs/design/PR17_COMBAT_IMPACT_FEEDBACK.md`, `docs/README.md`, and `docs/GODOT_METADATA.md`. Existing approved A-series and M-series gameplay decisions remain authoritative. E1–E10 govern the evaluation; E11–E16 below govern this narrowly scoped test utility. If a design conflict arises, stop for owner approval rather than silently changing behavior.

## 2. Approved decision register

| ID | Approved option | Binding decision |
| --- | --- | --- |
| E11 | B — Development-only keyboard selector | Select Pursuer-only, Heavy-only, or combined encounters within the existing arena. |
| E12 | B — Selection triggers complete reset | Changing configuration immediately restores a fresh encounter; F5 resets the currently selected configuration. Default is combined. |
| E13 | B — Dedicated keys and persistent label | F7 selects Pursuer-only, F8 Heavy-only, F9 combined; show a small persistent active-configuration label independently of F3 diagnostics. Use the existing Input Map conventions. |
| E14 | B — Reversible inactive enemy state | Retain both enemy instances but exclude inactive enemies from every relevant gameplay subsystem; reactivation restores normal initial state. Inactive is distinct from defeated. |
| E15 | B — Focused automated regression and owner acceptance | Exercise production behavior with existing test conventions and complete owner runtime acceptance. No broad new test framework. |
| E16 | B — Retain as isolated development utility | Keep selector in the standalone arena for future regression use, not in production gameplay; no obligation to expand it. |

## 3. Configuration and controls

| Input | Result |
| --- | --- |
| F7 | Select Pursuer only and immediately reset to that fresh configuration. |
| F8 | Select Heavy only and immediately reset to that fresh configuration. |
| F9 | Select Pursuer + Heavy and immediately reset to that fresh configuration. |
| F5 | Reset the currently selected configuration without changing it. |
| F3 | Continue to toggle existing diagnostics independently of the selector label. |

The default on initial arena load is **Pursuer + Heavy**, preserving the existing arena behavior. Use distinct Godot Input Map actions rather than hard-coded key polling. Verify no binding conflicts in the live project before implementation. F6 is deliberately not used because it serves Godot's run-current-scene shortcut.

A small unobtrusive persistent label must identify the active configuration, e.g., `Encounter: Pursuer only`, `Encounter: Heavy only`, or `Encounter: Pursuer + Heavy`. The label must remain visible regardless of F3 diagnostic visibility, including after reset, death, or completion. Do not add menus or a generalized HUD framework.

## 4. Fresh encounter and reset contract

A configuration selection must produce a consistent fresh attempt, rather than modifying the enemies mid-fight while preserving damage or transient state. Restore:

- Player spawn position, full HP, normal movement/action state, starting dagger, and existing F5 reset guarantees.
- Active enemy spawn positions, maximum HP, initial engagement and attack state, collision, navigation, avoidance, and feedback state.
- Clear pending attacks, contacts, hitstop, trails, recoil, audio, death/completion presentation, and stale encounter events according to the existing reset architecture.
- The selected configuration must remain active across F5 resets; selecting another configuration resets immediately into that new selection.
- Preserve existing F3 diagnostic-toggle behavior unless a previously approved rule explicitly requires otherwise.

A selected weapon must be chosen again after reset using existing weapon keys; do not introduce weapon persistence or new selection semantics. Do not introduce a new reset manager unless the existing architecture demonstrates a concrete need.

## 5. Reversible inactive enemy contract

Both original enemy instances remain in the scene. An excluded enemy is **inactive**, not defeated and not merely invisible. Inactive enemies must:

- Be hidden and nonblocking, with no solid or melee-target collision or damage eligibility.
- Not detect, pursue, retreat, navigate, participate in avoidance, attack, telegraph, or produce damage/contact events.
- Not contribute to encounter-completion requirements or prevent the active configuration from completing.
- Have no pending or stale attack contacts, hit feedback, trails, recoil, or audio that can leak into the new encounter.
- Not affect the active enemy's navigation or avoidance as a peer.

Reactivation must restore the enemy's original spawn position, HP, collision and navigation participation, normal attack/movement capabilities, and clean initial state. The current combat generation and chronological contact-resolution safeguards must remain effective across rapid configuration switches, including switches during attacks, dodge, hitstop, defeat, and death.

Use the smallest safe extension of existing enemy lifecycle/reset APIs. Avoid introducing a generalized enemy spawning system or replacing the existing encounter architecture.

## 6. Completion and diagnostics

Encounter completion is determined solely by the enemies active in the selected configuration. Defeating the sole active enemy completes an isolated encounter; combined mode retains the existing requirement to defeat both. The existing completion and death presentation should otherwise remain unchanged. Inactive enemies must never be treated as defeated for purposes of gameplay or diagnostic interpretation.

The persistent configuration label is separate from F3. Existing F3 diagnostics should remain available and truthful about active entities. Do not expand telemetry or require per-attempt logging infrastructure.

## 7. Behavior-based regression requirements

Use the existing combat regression conventions and actual production code. Test observable behavior and state transitions rather than comparing source text, scene files, resource hashes, line counts, or frozen copies.

Minimum focused coverage:

1. Initial combined mode behaves like the existing arena, with both enemies active.
2. F7/F8/F9 select the correct configuration and immediately produce a fresh player/enemy state.
3. F5 resets the selected configuration without changing it; player HP, spawn, starting dagger, attack/dodge state, and active enemy HP/spawns are restored.
4. Inactive enemies cannot collide, move, detect, attack, receive melee damage, produce contact events, influence navigation/avoidance, or block completion.
5. Pursuer-only and Heavy-only completion occurs on defeat of the selected enemy; combined completion still requires both.
6. Reactivation restores normal enemy behavior, collision, HP, position, navigation, and attack state.
7. Configuration switches during player/enemy wind-up or Active, dodge execution/recovery, hitstop, player death, and enemy defeat leave no stale damage, audio, visuals, or completion state.
8. F3 diagnostics and the persistent encounter label behave independently; existing combat controls and approved greatsword dodge interruption remain unchanged.

Keep regression coverage proportional to the change; extend existing fixtures or add one focused fixture if warranted. Existing tests and repository integrity checks remain separate. Running Godot, scenes, imports, or headless fixtures requires explicit owner authorization; documentation approval alone is not execution authorization.

## 8. Owner runtime acceptance

After implementation and authorized engine execution, the owner should verify all three selections, repeated F5 resets, accurate labels, isolated completion, and switching during combat/death. Check that inactive enemies have no visible or invisible influence and that combined-mode combat still feels and behaves as before. Record the exact tested PR head, outcomes, and any exceptions. No acceptance is assumed in advance.

## 9. Explicit exclusions and authorization boundaries

Do not change weapon damage, reach, timing, dodge rules, enemy health, attack geometry, telegraphs, AI tuning, or impact feedback. Do not add enemies, arenas, menus, spawning frameworks, generalized scenario data, telemetry, or permanent gameplay UI. Do not introduce mandatory extra combat milestones. The selector is retained only as a standalone arena development utility and may be retired when no longer useful.

This specification **does not authorize implementation**, branch creation, repository modifications, Godot execution, or merging. Authorization for a documentation-only Codex PR and, later, a separate implementation PR must be explicit.

## 10. Approved workflow

1. Review this standalone specification with the owner.
2. Once separately authorized, use a fresh Codex conversation for a documentation-only PR adding the specification, registering E11–E16 in `docs/design/DECISION_LOG.md`, and updating `docs/README.md` and any directly affected documentation links. Keep unrelated status and roadmap changes out of scope.
3. Independently review the exact documentation PR diff/head, complete applicable non-engine checks, obtain owner manual merge, then perform separately authorized post-merge cleanup.
4. Only after that may the owner separately authorize a focused implementation PR. Inspect live `main`, follow `AGENTS.md`, use a traditional feature branch in the primary checkout, preserve owner files, and open a Draft PR.
5. Independently review the implementation diff/head, perform owner-authorized behavior-based runtime acceptance, complete pre-merge verification, mark Ready after PASS, and await owner manual merge and separate cleanup.
6. Resume the approved E1–E10 combat evaluation, including 18 baseline attempts and targeted follow-ups. If Phase 1 passes, proceed to the minimal integrated gameplay loop rather than expanding combat prototyping.

**Guiding principle:** Prototype only major unanswered risks. Otherwise, move into production.
