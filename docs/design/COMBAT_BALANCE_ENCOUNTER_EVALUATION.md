# Factory ARPG — Combat Balance & Encounter Evaluation

**Status:** Owner-approved evaluation design; documentation-only planning artifact\
**Approved:** 2026-11-20\
**Repository:** `interneth3ro/factory-arpg` (`main`)\
**Engine:** Godot 4.7.2\
**Milestone:** Phase 1 combat exit evaluation\
**Implementation authorization:** None

## 1. Purpose and authority

Determine whether the existing melee combat is readable, responsive, enjoyable, fair enough for a short encounter, and reliable enough to close Phase 1 and proceed to the minimal integrated gameplay loop. Do **not** aim for final-game weapon balance or create additional mandatory combat milestones.

Authoritative references, to be consulted against live `main` before documentation PR preparation or implementation recommendations:

- [AGENTS.md](../../AGENTS.md)
- [docs/DEVELOPMENT_ROADMAP.md](../DEVELOPMENT_ROADMAP.md)
- [docs/design/COMBAT_PROTOTYPE_V0.1.md](COMBAT_PROTOTYPE_V0.1.md)
- [docs/design/DECISION_LOG.md](DECISION_LOG.md)
- [docs/design/PR16_PLAYER_HEALTH_DAMAGE_DEATH.md](PR16_PLAYER_HEALTH_DAMAGE_DEATH.md)
- [docs/design/PR17_COMBAT_IMPACT_FEEDBACK.md](PR17_COMBAT_IMPACT_FEEDBACK.md)
- [docs/README.md](../README.md)
- [docs/GODOT_METADATA.md](../GODOT_METADATA.md)

The frozen combat baseline and approved A/M-series decisions retain authority. The decisions below govern **evaluation methodology**, not changes to existing combat behavior. Any adjustment conflicting with an approved decision requires explicit owner approval. Historical PR #17 is the impact-feedback milestone label; implementation occurred in PR #19, which the owner reports merged and cleaned up after 12/12 runtime acceptance. PR #18 carried the approved feedback specification and has also been merged and cleaned up.

## 2. Approved evaluation decisions

| Evaluation decision | Approved option | Binding evaluation approach |
|---|---|---|
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

E1–E10 identify the approved evaluation decisions in the [decision log](DECISION_LOG.md#combat-balance-and-encounter-evaluation-decisions). The A/M-series identifiers retain their existing meanings.

## 3. Scope and exclusions

### In scope

- Dagger, one-handed sword, and greatsword: effectiveness, reach, timing, responsiveness, movement tradeoffs, attack commitment, aim behavior, and impact feedback.
- Dodge and attack interactions: protection, buffering, interruption, recovery, and hitstop feel.
- Pursuer and Heavy: movement pressure, telegraphs, commitment, attack reach, dodge counterplay, and recovery opportunities.
- Isolated and combined encounter pacing, player survivability, target prioritization, and enjoyment.
- Existing diagnostics and behavioral regression evidence when relevant to an observed defect.

### Out of scope

New enemy types, bosses, classes, skills, weapon families, AI coordination systems, general healing, progression, extensive telemetry, dedicated evaluation frameworks, final art/audio polish, and changes solely to make weapon statistics numerically equal. A focused correction is possible only after a documented finding and explicit owner approval.

## 4. Existing parameter review — read-only

Before runtime testing, inspect the live implementation and approved documents; record actual values, locations, and whether a value is provisional. Do not silently treat documentation values as verified runtime configuration.

| Category | Parameters and questions |
|---|---|
| Weapons | Damage, reach, arc, wind-up/Active/recovery, movement multipliers, aim-lock timing, buffer/hold-repeat, dodge-cancel eligibility, hitstop. |
| Dodge | Initial speed/distance, duration, protected interval, recovery, directional sampling, interruption and buffering. |
| Pursuer | Speed, acceleration, detection, spacing, attack initiation, wind-up/Active/recovery, cooldown, lunge, damage, telegraph. |
| Heavy | Same categories; stationary attack, wider reach and ground warning, stronger damage and longer recovery. |
| Encounter | Starting positions, obstacles, enemy activation, isolation feasibility, F5 reset, weapon selection, HUD/F3 diagnostics. |
| Reliability | Existing behavior-based fixture coverage and any known limitations that could affect evaluation. |

**Reference values from approved repository documentation, not a substitute for source verification:** weapon damage 10/25/45; enemy HP 75/150; hitstop 25/40/60 ms; player HP 100; enemy damage 15/30; Pursuer attack phases 0.35/0.15/0.45 s and Heavy 0.75/0.25/0.85 s. These are provisional balancing inputs, not newly frozen targets.

The parameter review should produce a brief baseline table and *hypotheses to observe*, not preemptive balance changes.

## 5. Encounter matrix and baseline attempts

| Scenario | Dagger | One-handed sword | Greatsword | Main emphasis |
|---|---|---|---|---|
| Pursuer only | P-D ×2 | P-S ×2 | P-G ×2 | Fast pressure, tracking, movement, dodge timing. |
| Heavy only | H-D ×2 | H-S ×2 | H-G ×2 | Telegraph readability, reach, commitment, punish windows. |
| Pursuer + Heavy | B-D ×2 | B-S ×2 | B-G ×2 | Combined counterplay, positioning, target choice, survivability. |

**Total baseline:** 18 attempts. A blocked configuration is marked **BLOCKED / NOT RUN**, never fabricated as a failed playtest. Order may be adapted to owner convenience; record any substantial learning or setup differences.

### Attempt setup

1. Start from a fresh encounter state: player at full HP, selected weapon, relevant enemies alive at their initial state and HP, with no leftover attack/dodge/hitstop/feedback state.
2. Use existing F5 reset and normal controls where sufficient. Verify that resetting actually restores the intended scenario; F5 alone does not prove enemy isolation.
3. For isolated scenarios, avoid comparing a fresh single-enemy attempt to one where the other enemy was defeated first after consuming HP or changing positions. If reliable isolation is unavailable, record the limitation and **do not** count the attempt as a controlled isolated baseline.
4. Use normal player tactics; do not require scripted perfect inputs or a fixed win rate. Observe environmental obstruction and enemy reacquisition when naturally encountered.
5. Record result promptly, including any noteworthy anomaly. Two baseline attempts per combination; targeted follow-ups only for meaningful uncertainty, contradictory observations, or suspected defects.

### Isolation decision boundary

Inspect the live arena/controls before suggesting changes. If no repeatable existing method isolates the enemies, present the owner with the smallest feasible development-only option, its exact scope, and whether it would require a separate focused maintenance PR. **Do not create scenes, controls, branches, or code without approval.** Do not launch Godot or run headless tests without explicit owner authorization.

For E5, the owner approved the [standalone arena selector design (E11–E16, amended by Decision 17)](COMBAT_ENCOUNTER_SELECTOR.md#2-approved-decision-register). Use the [arena controls](../README.md#encounter-selection) after runtime acceptance of the implementation.

## 6. Observation rubric

Capture these concise fields per attempt:

- **Identification:** scenario code, attempt 1 or 2, date/build or `main` head reference when available, any setup deviation.
- **Outcome:** completed / player defeated / aborted / blocked; approximate remaining HP if completed, or HP when aborted.
- **Notable events:** unexpected hits or misses, ambiguous telegraph, awkward interruption, dodge protection surprise, hitstop/audio/trail anomaly, stuck state, reset issue.
- **Weapon feel:** responsiveness, distinctiveness, reach/arc usability, commitment versus reward.
- **Enemy fairness:** telegraph clarity, avoidability, positioning pressure, recoverable counterattack opportunities.
- **Overall:** enjoyable / mixed / frustrating, with one specific reason; optional concise free-text notes.

Avoid treating subjective labels as numerical benchmarks. No mandatory encounter timer, attack count, hit rate, win-rate threshold, or new instrumentation. If existing F3 diagnostics clarify a concern, record what they show without requiring capture for every attempt.

### Interpretation principles

- **Dagger:** quick response, frequent attack opportunities and bounded active aim correction are strengths; lower per-hit damage is expected.
- **Sword:** versatile middle ground, predictable Active-start aim lock and balanced commitment.
- **Greatsword:** Assess whether stronger damage and longer reach reward the earlier aim commitment. An available dodge should interrupt the attack in any phase, including late wind-up. Record a failed interruption as a potential finding. A repeat dodge during the dodge’s own execution or recovery is expected to be unavailable.
- **Pursuer:** sustained pressure should still allow informed positioning and defensive responses.
- **Heavy:** readable wind-up/ground warning and meaningful punish opportunities should offset high damage and reach.
- **Combined:** overlapping attacks may be challenging without being coordinated or taking turns; repeated effectively unavoidable damage despite reasonable responses is a concern.

A single failure or slow completion is not automatic evidence of imbalance. A clear fairness or reliability defect may warrant investigation even on first observation.

## 7. Targeted follow-up rules

Follow up only when a baseline exposes an unresolved question, significant contradiction, or possible defect. Record the question, the smallest repeatable reproduction, what changed or remained constant, and the conclusion. Stop once evidence is sufficient for a decision; do not impose an arbitrary large sample count. Where a finding may involve production-code behavior, prefer existing behavior-based regression fixtures and direct runtime observation. Keep repository integrity checks separate from gameplay regression tests; do not introduce source-copy/hash/line-count assertions as behavioral tests.

## 8. Findings severity and decision outcomes

| Severity | Meaning | Required handling |
|---|---|---|
| **Critical** | Unreliable input or lifecycle, consistently unavoidable/unfair damage, broken encounter state, or weapon unable to reasonably complete intended scenarios. | Blocks Phase 1; obtain approval for a focused fix and retest affected behavior. |
| **Significant** | Repeatable frustration, materially weak weapon identity, poor pacing, or excessive pressure that reduces enjoyment without fundamentally breaking combat. | Explicit owner judgment: focused adjustment now or documented acceptance/deferral. |
| **Minor** | Small tuning differences, occasional non-blocking awkwardness, or polish opportunities. | Record and normally defer to integrated loop or production. |

Severity depends on demonstrated impact, not just occurrence count. Distinguish intended commitment and player mistakes from mechanical unfairness. No finding authorizes a code change automatically.

### Phase 1 result

The categories below define the original evaluation rubric. The owner approved **Phase 1 — CONDITIONAL PASS** and deferred EVAL-01 as Minor and non-blocking. [Completed results and exit decision](PHASE_1_COMBAT_EVALUATION_RESULTS.md#phase-1-exit-decision)

- **PASS:** All roadmap exit criteria are adequately met; no critical blocker and any significant concerns have been explicitly resolved or accepted by the owner. Proceed to Phase 2 without requiring a combat implementation PR.
- **CONDITIONAL:** No unresolved critical blocker, but one or more significant findings await explicit owner judgment or targeted work.
- **BLOCKED:** At least one critical finding prevents reliable, fair, or meaningful evaluation/continuation.

A PASS does not assert final balance, zero defects, or final polish.

## 9. Phase 1 exit checklist

- [ ] All three weapons are distinguishable in gameplay and feedback.
- [ ] Hits, misses, wind-ups, damage, and death are understandable.
- [ ] Dodge and attack responsiveness are acceptable during real play.
- [ ] Existing-enemy short encounters are enjoyable enough to form a baseline.
- [ ] No known critical defect prevents reliable evaluation or continuation.
- [ ] Significant findings have explicit owner disposition; deferred minor items are recorded.
- [ ] Owner explicitly approves Phase 1 outcome and next step.

## 10. Copyable results record

```markdown
### Attempt: [P-D / P-S / P-G / H-D / H-S / H-G / B-D / B-S / B-G] — [1 / 2 / follow-up]
- Build / date:
- Setup / deviations:
- Outcome: completed / defeated / aborted / blocked
- Remaining HP (approximate, if completed):
- Notable hits, misses, interruptions, or diagnostics:
- Weapon feel (responsiveness, identity, commitment):
- Enemy fairness (telegraph, pressure, counterplay):
- Enjoyment: enjoyable / mixed / frustrating — why:
- Potential finding / severity (if any):
- Follow-up required? question and reason:
```

### Findings summary template

```markdown
| ID | Scenario(s) | Observation and evidence | Severity | Disposition | Owner approval |
|---|---|---|---|---|---|
| F-01 | ... | ... | Critical / Significant / Minor | Fix / Accept / Defer / Investigate | Pending / Approved |

Phase 1 recommendation: PASS / CONDITIONAL / BLOCKED
Roadmap exit-criteria rationale:
Unresolved critical findings:
Significant findings and explicit owner dispositions:
Deferred minor improvements:
Recommended next action:
Owner final decision and date:
```

## 11. Documentation and execution workflow

1. Owner approves E1–E10 (completed in design discussion). Consolidate this standalone specification.
2. Prepare a **documentation-only** Codex PR in a fresh conversation and traditional feature branch based on live `main`. Commit the specification, append the approved evaluation decisions to `docs/design/DECISION_LOG.md` using the repository's numbering convention, update `docs/README.md`, and reconcile stale roadmap/implementation-status references without altering roadmap phase gates.
3. Independently review the exact documentation PR diff and head, complete applicable non-engine verification, then wait for owner manual merge. Run post-merge cleanup only in a separate authorized Codex conversation.
4. After documentation merge/cleanup, inspect live gameplay parameters and arena isolation capability. Obtain separate approval before any isolation implementation or Godot execution.
5. Conduct owner-led playtesting, capture 18 baseline attempts where feasible, and run targeted follow-ups only as needed.
6. Produce concise findings and a recommended PASS / CONDITIONAL / BLOCKED outcome. Obtain explicit owner acceptance of the Phase 1 exit decision.
7. If a correction is justified, separately scope and authorize the smallest implementation change, then review its exact PR diff/head, obtain runtime acceptance, complete pre-merge verification, and await manual merge and separate cleanup.
8. If Phase 1 passes, proceed to Phase 2: Exploration → Combat → Resources → Automation → Upgrades → Further Exploration. Do not invent additional mandatory prototype milestones.

### Operational safeguards

Preserve unrelated owner files, settings, assets, metadata, and evidence. Use the primary checkout and traditional branches, not worktrees. Never launch/import Godot, execute scenes or headless fixtures, or perform engine probes without explicit owner authorization. Never merge automatically. Keep changes focused; honor the repository's documentation-sync, pre-merge verification, post-merge cleanup, and metadata policies when applicable.

## 12. Completion boundary

This document approves a **method for evaluating combat**, not new mechanics, balance values, an implementation PR, or a requirement for additional tooling. Phase 1 is complete when the owner accepts the exit judgment based on evidence. The default next development goal is the minimal integrated gameplay loop.
