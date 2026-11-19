# Factory ARPG documentation

Keep design decisions and implementation details versioned alongside the project so contributors can trace what the game should do and how the code delivers it.

- [Combat Prototype v0.1](design/COMBAT_PROTOTYPE_V0.1.md) is the frozen gameplay baseline for the prototype. Consult it before implementing related systems.
- [Decision log](design/DECISION_LOG.md) indexes approved gameplay decisions and links to the authoritative specification for each.
- [Godot metadata policy](GODOT_METADATA.md) describes how to handle resource metadata and run the read-only validator.

## Approved specifications

Frozen specifications describe approved behavior and its rationale. They guide implementation and acceptance checks. Proposed approaches, provisional tuning, and deferred features are labeled separately. Keep the approved baseline intact when implementation behavior differs.

When implementation suggests a design change, identify the affected specification and decision, describe the proposed deviation, and obtain owner approval before changing approved behavior. After approval, update the specification and decision log together and preserve the history of any superseded decisions.

## Implementation documentation

Implementation documentation describes how the current code works. Refactors that preserve approved behavior can update implementation documentation as needed while leaving the design baseline intact.

The [combat test arena](../scenes/combat/combat_test_arena.tscn) is a standalone scene. Open it in the Godot editor and press F6 to run it. The [player coordinator](../scenes/combat/combat_test_player.gd) samples screen-relative WASD with normalized diagonals and passes that intent to the Movement FSM each physics step. It also aims the facing marker independently of movement. Within 4 pixels of the player's center in world coordinates, the marker keeps its previous heading. The Player's exported `movement_speed` defaults to a provisional 220 pixels per second.

On the feature branch pending merge, the [Movement FSM](../scenes/combat/player_movement_fsm.gd) starts Idle and switches to Moving while it receives a nonzero movement vector, including when a collision blocks travel. It alone sets ordinary player velocity and calls native 2D collision movement. The [Action FSM](../scenes/combat/player_action_fsm.gd) tracks action availability and stays Ready independently of movement. F3 toggles a diagnostic label that reads both current states. The label starts hidden. Pursuer and Heavy are stationary, and the attack, dodge, weapon selection, and reset bindings are inactive.

For implementation PRs, identify the affected documentation and use [documentation sync](../.agents/skills/documentation-sync/SKILL.md) on the same branch before review. Reconcile approved changes and keep edits focused on the PR.

After the owner confirms applicable runtime acceptance, use [pre-merge verification](../.agents/skills/pre-merge-verification/SKILL.md) on the specified open PR. It checks the live PR head, acceptance, metadata, documentation, and static integrity before the owner decides whether to merge.
