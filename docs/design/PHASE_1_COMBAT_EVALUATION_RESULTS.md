# Phase 1 combat evaluation results

**Owner decision — Phase 1 CONDITIONAL PASS.** The owner completed the baseline evaluation in Godot using the standalone combat arena. All nine weapon–encounter combinations were viable in these tests. Phase 2 planning can proceed without further combat tuning.

## Baseline attempts

The owner played each combination twice under the approved evaluation method, using the development-only encounter selector. Combined means the Pursuer and Heavy were both active. [Evaluation method (E1–E10)](COMBAT_BALANCE_ENCOUNTER_EVALUATION.md#2-approved-evaluation-decisions) · [Selector decisions (E11–E16 and Decision 17)](COMBAT_ENCOUNTER_SELECTOR.md#2-approved-decision-register)

| Encounter | Weapon | Attempt 1 remaining HP | Attempt 1 feel | Attempt 2 remaining HP | Attempt 2 feel |
| --- | --- | ---: | --- | ---: | --- |
| Pursuer only | Dagger | 85 | Good | 55 | Good |
| Pursuer only | Sword | 70 | Good | 40 | Good |
| Pursuer only | Greatsword | 55 | Mixed | 85 | Mixed |
| Heavy only | Dagger | 40 | Good | 100 | Good |
| Heavy only | Sword | 100 | Good | 100 | Good |
| Heavy only | Greatsword | 100 | Good | 100 | Good |
| Combined | Dagger | 70 | Good | 85 | Good |
| Combined | Sword | 100 | Good | 100 | Good |
| Combined | Greatsword | 100 | Good | 70 | Good |

The owner completed **18/18** baseline attempts, with **18/18 victories**. Combat feel was **Good on 16/18**, **Mixed on 2/18**, and **Poor on 0/18**. The owner reported no gameplay anomalies, critical combat defects, or unavoidable-damage problems.

Remaining HP describes how each attempt ended. With two attempts per combination, victory and full-health finishes alone cannot establish relative weapon power or enemy difficulty.

## EVAL-01 — Greatsword responsiveness

**Original observation (Significant, provisional).** In both Pursuer-only attempts, the owner rated the greatsword Mixed. Two successful hits defeated the Pursuer and the damage felt satisfactory. The swing initially felt slow when trying to connect with the moving target. The concern was the timing and commitment needed to land the hit.

The greatsword won both attempts in each encounter. Only the Pursuer-only pair felt Mixed. The owner rated both Heavy-only attempts Good and both combined attempts Good, including when the Pursuer was present alongside the Heavy.

**Owner clarification.** The owner rarely dodged in the first greatsword-versus-Pursuer fight. Using dodge more deliberately gave the weapon a rhythm the owner found acceptable at this stage.

> **Big swing → dodge to reposition → big swing → dodge to reposition.**

**Final disposition — Minor, deferred, non-blocking.** The two original Mixed ratings stand. The owner authorized no combat parameter changes and saw no immediate need to tune greatsword damage, wind-up, active time, recovery, or dodge mechanics. Revisit EVAL-01 only if later integrated gameplay shows a meaningful responsiveness problem.

## Phase 1 exit decision

The owner approved **Phase 1 — CONDITIONAL PASS** on the strength of the complete baseline, viability across all nine combinations, predominantly Good ratings, and absence of critical blockers. The later reduction of EVAL-01 to Minor closes the severity question. The approved historical exit decision remains **CONDITIONAL PASS**.

Phase 2 planning is next. The approved loop is **Exploration → Combat → Resources → Automation → Upgrades → Further exploration**. Detailed mechanics and implementation require separate approval. [Development roadmap](../DEVELOPMENT_ROADMAP.md#11-immediate-next-steps)
