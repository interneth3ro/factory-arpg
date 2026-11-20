# Factory ARPG — PR #17 Combat Impact and Feedback

**Status:** Owner-approved design decisions M75–M90; repository reconciliation completed for planning; **implementation not authorized**  
**Date:** 2026-11-20  
**Repository:** `interneth3ro/factory-arpg` (`main`)  
**Proposed repository path:** `docs/design/PR17_COMBAT_IMPACT_FEEDBACK.md`  
**Engine:** Godot 4.7.2

## 1. Purpose and authority

Improve the responsiveness, readability, and tactile character of existing melee combat while preserving the approved combat foundation. This is the final focused *presentation* pass proposed before combat balance/encounter evaluation under `docs/DEVELOPMENT_ROADMAP.md`. It is not authorization to expand combat systems or to implement a new progression mechanic.

The frozen A1–A16 baseline in `docs/design/COMBAT_PROTOTYPE_V0.1.md`, subsequent decisions in `docs/design/DECISION_LOG.md`, and `docs/design/PR16_PLAYER_HEALTH_DAMAGE_DEATH.md` remain authoritative. Where this document leaves implementation choices open, preserve existing gameplay. Where a conflict arises, stop and request owner approval; do not silently revise approved decisions.

## 2. Approved decision register

| ID | Approved option | Requirement |
|---|---|---|
| M75 | A — Combat Impact and Feedback | PR #17 milestone direction. |
| M76 | B — Complete Core Feedback Pass | Include weapon impacts, enemy hit reactions, swing trails, and swing/impact audio. |
| M77 | B — Directional Impact Bursts | Brief stylized effects aligned to incoming attacks; confirmed hits only. |
| M78 | B — Distinct Silhouettes and Timing | Dagger narrow/quick, sword crisp/medium, greatsword broad/heavy; shared neutral palette. |
| M79 | B — Contact-Position Impacts | Use best-supported geometric contact position and attack direction; presentation-only if extra approximation needed. |
| M80 | B — One Impact per Enemy Hit | One burst for each distinct successful enemy hit, no duplicate per attack/target. |
| M81 | B — Attack-Phase-Aware Cosmetic Reactions | Normal during pursuit/hold/recovery/cooldown; reduced during wind-up; minimal during active; defeat wins. No gameplay stagger. |
| M82 | B — Archetype Identity + Weapon Weight | Pursuer faster/more reactive, Heavy more restrained/weighty; configure shared behavior across weapon types. |
| M83 | B — Smooth Reaction Restart | Each new confirmed hit blends from current visual pose, with bounded movement and no additive drift. |
| M84 | B — Stylized Directional Swing Trails | Weapon-specific trails on hits and misses. |
| M85 | B — Active-Phase Trails with Brief Decay | Trail starts with active damage phase, fades briefly after; dodge interruption terminates promptly. |
| M86 | B — Geometry-Aligned Swing Trails | Match existing committed aim, attack reach, and angular coverage without rendering literal debug hitboxes. |
| M87 | B — Separate Swing and Impact Audio | Weapon-specific swing when active starts, impact when damage confirmed; no swing from an attack canceled before active. |
| M88 | C — Primary Impact with Restrained Secondary Hits | First confirmed hit plays full impact; subsequent hits may play quieter sounds with a small concurrency cap. Audio suppression never suppresses gameplay or visuals. |
| M89 | B — Curated Royalty-Free Audio Assets | Prefer CC0 or comparably permissive, verified assets, locally stored with provenance/license documentation. |
| M90 | B — Shared Lifecycle Rules with Independent Components | Common interruption, death, reset, and stale-event rules without requiring a central feedback manager. |

## 3. Functional requirements

### 3.1 Impact bursts

- Only a **successful application of enemy damage** spawns an impact burst; a miss, blocked/invalid contact, or duplicate collision query does not.
- Each distinct enemy successfully hit by one attack receives one burst, including when a sweep hits several enemies.
- Place the effect at the best-supported geometric contact location. Align it to the attack's actual committed/sweeping direction **at the hit**, not the player's later mouse direction. The dagger's approved bounded active aim correction must be respected.
- Use a shared neutral visual language with three silhouettes: dagger = small needle-sharp burst; sword = medium directional slash; greatsword = wider weighty burst with modestly longer decay.
- Keep effects brief, non-obscuring, and entirely cosmetic. A lethal hit can show its already-confirmed burst, but must not change defeat timing or visuals.

### 3.2 Enemy visual recoil

- Recoil applies to the **visual representation only**. It cannot move the CharacterBody2D root, alter navigation, collision shapes, velocity, attack clocks, contact resolution, or enemy attack commitment.
- During pursuit/hold/recovery/cooldown, show normal recoil; during wind-up, reduce it to preserve telegraph; during active, minimize it to preserve strike readability; during defeat, the existing defeat behavior has priority.
- Pursuer: quick and more noticeable; Heavy: slower-looking, smaller and more grounded. Dagger < sword < greatsword in apparent weight, subject to the enemy archetype and phase constraints.
- A later confirmed hit replaces/redirects the recoil from the **current visible pose**; smoothly blend rather than snapping to neutral. Bound offsets/angles so repeated hits never accumulate drift.
- Existing weapon-scaled white flashes and enemy attack poses/telegraphs remain intact. Avoid double-applying pose transforms or covering Heavy's ground warning.

### 3.3 Swing trails

- Appear for attacks that reach their active phase, including misses; do not appear during wind-up.
- Show a short, restrained, weapon-specific directional sweep during the actual active interval, followed by a brief cosmetic fade during recovery.
- Derive geometry from the actual weapon reach, sweep angle, and time-varying blade angle. The trail must not imply materially greater range than the gameplay attack. A visually emphasized outer arc is acceptable; do not draw the full debugging sector as the default artwork.
- Follow actual aim commitment, including the dagger's bounded correction. Do not assume every weapon's aim remains fixed during active.
- Respect hitstop: a paused attack must not continue advancing its apparent swing independently of gameplay. A dodge interruption promptly cancels the current trail; no ghost swing from canceled or previous attacks.
- Trails never participate in damage queries or modify hit geometry.

### 3.4 Audio

- Six functional roles: dagger/sword/greatsword **swing** and **confirmed impact**. A role may use one or more curated recordings, subject to scope.
- Swing sound starts when the attack actually enters active, including when a single physics tick crosses multiple phase boundaries. Do not emit for wind-up-only canceled attacks.
- Confirmed damage produces impact sound. For a multi-target attack, the first confirmed hit is full strength; later confirmed hits may produce lower-volume secondary sounds under a small concurrency limit. Define the exact policy deterministically and document it; do not let playback change hit order.
- Audio playback must not cause or change hitstop, attack clocks, damage, or movement. Preserve intelligibility during rapid dagger attacks and near-simultaneous targets.
- Choose assets with verified redistribution rights. Prefer CC0; otherwise check license terms and attribution obligations before bundling. Keep source URLs, creator/license details, retrieval date, and processing notes in repository documentation. Do not claim an unverified asset is safe to ship.
- Store approved processed sounds locally; no remote runtime fetching, new audio middleware, or unapproved third-party plugin.

## 4. Lifecycle and event precedence (M90)

| Event | Required outcome |
|---|---|
| Attack enters active | Begin appropriate swing trail and swing sound once per attack execution. |
| Confirmed hit | Spawn one contact-position burst and refresh target recoil; schedule primary/secondary impact sound according to M88. |
| Normal active → recovery | Stop producing new trail motion and fade briefly; confirmed effects may expire naturally. |
| Dodge interrupts attack | Immediately invalidate the interrupted attack's future presentation events and promptly terminate its trail. Existing verified damage is not undone. |
| Enemy lethal damage | Existing enemy defeat/collision behavior wins; no continued recoil, but an already-confirmed impact burst may finish. |
| Player death | Stop ongoing player attack presentation; prevent subsequent new combat feedback. Already-spawned brief effects may finish during collapse, but never survive reset. |
| F5 reset | Clear all previous-generation trails, impact effects, recoil, and active combat audio immediately. Reset per-attack sound bookkeeping. |
| Stale/duplicate event | Reject events belonging to invalid attack execution or prior encounter generation; never replay audio/effects after reset. |

Use existing state and encounter-generation identity rather than a second gameplay state machine. The first-hit audio policy must remain stable if several contacts are processed in the same physics tick.

## 5. Repository reconciliation — read-only findings

Reviewed current `main` via GitHub file reads on 2026-11-20: `AGENTS.md`, `docs/README.md`, `docs/design/COMBAT_PROTOTYPE_V0.1.md`, `docs/design/DECISION_LOG.md`, `docs/design/PR16_PLAYER_HEALTH_DAMAGE_DEATH.md`, `docs/GODOT_METADATA.md`, `docs/DEVELOPMENT_ROADMAP.md`, and selected scripts below. This was **not** an exhaustive tree/diff inspection and no Godot runtime was launched.

- `scenes/combat/player_action_fsm.gd`: `ActiveInterval` carries attack ID, weapon, tick-relative start/duration, active elapsed, direction and correction, and computes `blade_angle(at)`. The FSM can span phase boundaries inside a physics tick. This is important for precise swing sound/trail start and dagger correction.
- `scenes/combat/melee_sweep.gd`: `contacted(target, interval)` currently reports **no contact point or timestamp**. It queries swept capsule poses, deduplicates by target instance ID per attack, and emits a hit event. **M79 requires a design-conscious extension or presentation-only best-supported approximation.** Do not pretend the query supplies an exact contact coordinate; do not alter its damage semantics.
- `scenes/combat/combat_test_player.gd`: `_apply_contact` calls `enemy.receive_hit`, then requests hitstop for successful damage. It has `encounter_generation`, F5 reset, dodge interruption, and death handling. Presentation hooks must be triggered only after damage is confirmed and guarded against reset.
- `scenes/combat/enemy_health.gd`: `_update_body` already owns the visual `Polygon2D` pose, tint, and attack-phase presentation; hit flashes use a tween and defeat uses collision/movement shutdown. New recoil must compose with this existing pose logic rather than fight it.
- `scenes/combat/enemy_attack.gd`: attack phases, warning presentation and hitstop coupling are established. Do not obscure attack cues or disturb their clocks.
- `scenes/combat/weapon_attack.gd`: weapon resources define reach, sweep, active duration, correction and existing feedback values. Keep these as authoritative gameplay data.
- `docs/DEVELOPMENT_ROADMAP.md` still describes M75/PR #17 as pending because it was authored earlier. Updating its **status text only** during documentation sync is appropriate; do not rewrite its phase gates. `docs/README.md` currently indexes earlier specs and should link the PR #17 spec once committed.

**Reconciliation checkpoints before Codex implementation prompt:** inspect the complete live `main` tree and exact scene hierarchy; identify audio conventions and existing assets; decide how to derive contact placement without altering hit results; confirm how a multi-interval tick triggers one swing sound per attack; confirm how visual recoil composes with enemy telegraphs and existing flash; verify per-generation cleanup for tweens and audio. Any substantive conflict returns to the owner for approval.

## 6. Explicitly out of scope

- No new weapons, enemies, attacks, classes, abilities, progression, consumables, recovery mechanics, or encounter coordination.
- No stagger, knockback, gameplay displacement, attack cancellation from hits, or damage/health rebalance.
- No camera shake, full-screen effects, elaborate particle frameworks, or bespoke defeat-animation overhaul.
- No change to dodge invulnerability, input buffering, attack commitment, attack reach, collision geometry, hitstop, enemy telegraphs, navigation, death, or reset semantics.
- No general-purpose combat audio middleware or central presentation framework absent demonstrated necessity and owner approval.

## 7. Owner runtime acceptance checklist (proposed)

1. Dagger, sword and greatsword show clearly different trails on misses and distinct contact bursts on hits.
2. Swing trails start at actual active entry, including boundary-crossing ticks, and never appear for attacks canceled in wind-up.
3. Trail orientation/reach track committed aim and the dagger's bounded active correction; no visual reach mismatch of gameplay significance.
4. A single sweep hitting multiple enemies produces one burst per damaged enemy, without duplicate bursts across query substeps or ticks.
5. Impact positions track plausible contact edges on both enemy sizes and from multiple approach angles.
6. Pursuer and Heavy show distinct weapon-weighted recoil; wind-up/active telegraphs remain legible and attack execution uninterrupted.
7. Fast repeated hits smoothly redirect recoil without pose snapping, offset drift, or unintended enemy displacement.
8. Swing and impact audio are distinguishable for each weapon; misses produce swing only; multi-target sounds remain controlled and clear.
9. Offensive hitstop does not cause visual desynchronization or unintended repeated audio; dodge interrupts trails promptly.
10. Enemy lethal hits, player death/collapse and surviving-enemy rest retain existing precedence and behavior.
11. F5 at every attack/enemy/death phase removes old-generation feedback and audio; repeated F5 never leaves stale effects.
12. Regression: player movement/dodge, three weapon damage profiles, enemy pursuit/spacing, enemy attack telegraphs, chronological contact resolution, health HUD, F3 diagnostics, and arena completion remain correct.

All runtime tests require **explicit owner authorization** before Codex or other tools launch/import/execute Godot. The owner performs runtime acceptance before pre-merge verification.

## 8. Implementation workflow and documentation

1. Owner reviews and accepts this standalone specification; resolve any identified conflicts before coding.
2. Inspect current live repository fully and prepare a **separate, complete Codex Desktop implementation prompt** explicitly attaching this specification. Codex must stop if it cannot access the attachment.
3. Codex uses a traditional feature branch in the primary checkout from synchronized clean `main`, not a worktree; creates a Draft PR; never merges.
4. Preserve all owner assets, local settings, unrelated changes, historical evidence, `.uid` and `.import` metadata. Follow `AGENTS.md` and `docs/GODOT_METADATA.md`.
5. On the feature branch, add this specification to `docs/design/`, register M75–M90 in `docs/design/DECISION_LOG.md`, link it in `docs/README.md`, and update the roadmap's now-stale milestone status. Follow documentation-sync skill.
6. Independently review the **exact live PR diff and head SHA** and resolve issues on the same branch. Owner completes runtime acceptance. Run repository pre-merge verification; mark Ready only after PASS. Owner merges manually. Cleanup happens in a separate Codex conversation.

## 9. Remaining tuning choices (not silently approved values)

Exact effect pixel sizes, durations, opacity, color values, visual layers, recoil offsets/angles/blend curves, audio loudness, secondary-hit concurrency limit, and specific source recordings remain implementation-tuning details. They must honor the approved behavior and be exposed/documented sufficiently for owner acceptance. If any tuning choice changes gameplay meaning or conflicts with approved behavior, seek owner approval rather than treating it as routine tuning.
