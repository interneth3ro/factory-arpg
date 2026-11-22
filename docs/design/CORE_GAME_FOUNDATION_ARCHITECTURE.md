# Core game foundation architecture

Approved design for the permanent game in Godot 4.7.2. The standalone combat arena is the existing playable baseline. The architecture below is the target for F1–F10. See the [gameplay rules](CORE_GAME_FOUNDATION_GAMEPLAY.md) and [implementation and acceptance plan](CORE_GAME_FOUNDATION_IMPLEMENTATION.md).

## Session, locations and state

| Responsibility | Owner and lifetime | Example across a trip home |
| --- | --- | --- |
| Runtime scenes (CF2, CF3) | The permanent game entry starts a session. Its game root owns one player and the active location. A transition replaces the location and places the same player in the destination. Ending the session releases its runtime instances. | The starting region can unload. Its deposit presentation disappears. The player arrives at the home-base entrance with the same backpack. |
| Authoritative gameplay state (CF4, CF5) | Each playthrough owns the mutable facts about its world and player. Persistent objects have stable IDs. Loaded locations explicitly register their objects against those records and reflect accepted state changes. Unloading removes temporary bindings and preserves the records. | Returning to the region shows the original deposit's progress. Reopening a physical container reads the contents belonging to that container. |
| Serialized save data (CF6, CF8) | A slot stores a versioned, structured representation of the playthrough at a consistent point. It can reconstruct authoritative state in a later session. Node references, transient input, and live scene instances have no place in this data. | Reloading restores location, position, backpack, container contents and deposit progress from the selected slot. |

Two different persistent objects must never register as the same object. Registration must detect ambiguous or duplicate identities before a binding can overwrite state. Revisiting a known object reuses its record. Spawning a fresh scene, changing a node path or traversing objects in another order must preserve identity. An unloaded location needs no running factory simulation for this foundation.

## Shared player and input

**CF1, CF9.** The permanent game and the independently launchable combat arena instantiate the same reusable combat-capable player scene. Keep movement, combat actions, health and later mining responsibilities modular. Arena encounter selection, enemy setup, diagnostics and reset belong to the arena context. Launching the arena must work without a permanent-game session or save. During normal game travel the session retains the player (CF3). Component boundaries may follow the existing movement, action and health code. The exact node tree and service layout are implementation choices.

**CF12.** Resolve input in priority order among the contexts eligible for that event. A focused inventory or storage control consumes its click before world actions can use it. In the world, the active capability and eligible target determine what the primary action means. A mining press on a deposit cannot also fire the pistol. Interaction prompts must agree with the action that will receive input. Crossing contexts must retire incompatible held or pending actions so closing a panel cannot replay its click. Within combat, retain the approved movement, dodge, commitment and fresh-press rules. [Combat baseline](COMBAT_PROTOTYPE_V0.1.md) · [Shared input and style switching](RANGED_MAGIC_COMBAT_INPUT.md#combat-input-and-hud) · [Player health and reset](PR16_PLAYER_HEALTH_DAMAGE_DEATH.md)

## Travel and restoration

**CF23.** Author both ends of a passage as paired transition anchors. On ordinary travel, resolve the destination and its arrival anchor, switch locations and place the session's player at that anchor. A failed resolution must leave a usable player and location. A save records the player's actual location identity and position together. Loading it restores that position when valid, including a position away from an entrance. If the location or position cannot safely be restored, handle the failure explicitly or use a verified safe placement. Never strand the player in collision or silently substitute an unrelated location. Exact validation and recovery methods remain open.

## Saving and playthrough isolation

**CF6–CF8.** Each independent playthrough slot supports both manual saves and autosaves. Both capture coherent player and world records under the same versioned contract. A save taken around a transfer, travel or mining completion must restore one consistent outcome. Validate data and version on load before adopting the recovered state. An unsupported version or failed read/write must be visible and must preserve the previous valid save. File format, write strategy, version migration policy, autosave triggers and interval remain implementation or tuning decisions.

Starting, saving or loading one slot must preserve every other slot. Immutable item definitions may be shared. Player position, inventory stacks, container contents and deposit progress belong exclusively to the selected playthrough, even when two slots use the same authored object IDs.

## Deposit progress

**CF31.** Key interrupted manual-cycle progress to the deposit's stable identity within its playthrough. The laser drives the active cycle and the scene displays it. Restoring a location or a save must distinguish a partial cycle from output already credited. Restoring the same completed state cannot issue a second award. [Mining and capacity rules](CORE_GAME_FOUNDATION_GAMEPLAY.md#manual-mining)
