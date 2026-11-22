# Core game foundation gameplay

Approved design for the first permanent playable region and home base. This is the portion of the [reconciled opening progression](EARLY_GAME_GATHERING_AND_AUTOMATION.md#7-revised-opening-progression-rc1-rc6rc8) that precedes integrated factory gameplay. The [architecture](CORE_GAME_FOUNDATION_ARCHITECTURE.md) defines session and save ownership. The [milestones](CORE_GAME_FOUNDATION_IMPLEMENTATION.md) specify when each interaction becomes playable.

## World and home base

**CF19–CF21.** Build a small, fully handcrafted starting region that the player can explore and revisit. Author its routes, transitions and the positions of its deposits. Regions load independently and have stable location identities. Future regions could connect seamlessly if later design requires it. Streaming, procedural world or deposit generation, starting-world enemies and finished environmental artwork are outside this foundation.

**CF22.** The permanent home base is a separate location reached through a paired passage. Reserve recognizable areas for dedicated raw-material intake, refined-material storage, component storage and future integrated services. Initially the player uses the shell for travel and physical general storage. Reserved space conveys layout without adding production, orders, reservations or automatic access. [Home-base storage roles and RC5](EARLY_GAME_GATHERING_AND_AUTOMATION.md#5-home-base-storage-and-manual-material-handling-hb2-rc4rc5-rc7)

## Interaction and targeting

**CF10, CF11.** Use a common way to identify a target, report its available interaction and dispatch the chosen action. Proximity makes nearby physical interactions, such as an entrance or container, discoverable. Cursor targeting expresses intent when an action needs a specific object. The specialized action checks its own eligibility and owns its effects. For example, the player can approach storage to access it, while the selected laser needs the indicated deposit, range and sight. An overlapping entrance, deposit or panel must not cause one input to activate two targets. Exact bindings, radii and tie-breaking rules remain open. [Input contexts](CORE_GAME_FOUNDATION_ARCHITECTURE.md#shared-player-and-input)

## Items, backpack and general storage

**CF13, CF14.** Reusable item definitions describe an item type and its capacity rules. An inventory owns the slots, item identities and quantities actually held. Moving a stack updates its inventories, never the shared definition. Compatible resources and ordinary components can stack. Weapons, armor, tools and machinery can have different handling under EG7. Enforce the applicable item limit and available slot count on every insertion, including automatic collection.

| Inventory rule | Approved initial value | Applies to |
| --- | --- | --- |
| Backpack capacity (CF15) | 24 slots | The player's carried inventory |
| Basic-resource stack limit (CF15) | 100 units per stack | Basic resources in compatible inventory slots |
| General storage (CF16) | One physical container with 48 slots | The initial container at home |

Each physical general-storage container owns an independent inventory. Access requires the player to use the container and move items deliberately. RC5 excludes its contents from production, research, construction supply, reservations, conveyors and other automatic logistics. Players must retrieve items manually to put them into an eligible inventory for future systems. Industrial containers and dedicated production stores have distinct roles and are deferred.

**CF17.** Support drag-and-drop, quick transfers and deliberate partial-stack transfers between backpack and open storage. For each operation, check item compatibility, stack room, free slots and available source quantity. Move only the accepted quantity and leave the rest at its source. A canceled, rejected or repeated operation must preserve item totals. For example, with a single compatible stack at 98 and all other slots full, a quick transfer of five basic units moves two and leaves three at the source. The same total must survive closing the panel, changing locations and saving/loading once those milestones are available.

## Manual mining

**CF24.** Integrate the handheld mining laser as a dedicated capability of the shared player. Preserve EG2–EG7 and EG18. The active tool determines primary-action behavior. Mining uses discrete extraction cycles with feedback on the targeted deposit. [Approved laser behavior and feedback](EARLY_GAME_GATHERING_AND_AUTOMATION.md#4-handheld-mining-laser-and-deposits-eg2eg6-eg18)

1. While stationary with the laser selected, aim directly at an eligible deposit in range and unobstructed line of sight and engage the primary action. Indicate valid hover, obstruction or range failure.
2. While primary is held and eligibility persists, retain that deposit even if the cursor moves away or crosses another deposit. Show the beam, impact, local cycle progress and attributable awards. Keep combat warnings readable.
3. Movement, dodge, release, changing tool or switching to combat, leaving range or losing sight interrupts extraction promptly. Selecting a different deposit requires fresh acquisition. Each deposit retains its own interrupted progress through travel and save/load (CF31).
4. Award whole resource units only from completed cycles. Basic iron, copper and other approved common-resource deposits have infinite lifetime yield and limited throughput. Mining them repeatedly never reduces a remaining reserve. Rare deposits may be finite. Manual priority over future extractors remains as specified by EG18. The foundation implements manual extraction alone.

**CF18.** Automatically collect as much completed output as the backpack can accept. If only part fits, credit it once, preserve the uncollected balance and safely pause when capacity is exhausted. After space becomes available, only the outstanding amount from that award may enter inventory. A full pack must neither consume output nor allow repeated claims. Interruption, unloading and saving during this boundary must preserve both item totals and deposit progress. How the game represents outstanding output is an implementation choice.

CF15–CF16 settle the three values in the table above that were open in the earlier EG7 planning record. Mining range, extraction rates, yields, world dimensions, other stack limits and other storage capacities remain provisional unless separately approved. Integrated smelting and component crafting, remote automated extractors, conveyors and industrial logistics, research and wireless transportation, advanced manufacturing and background factory simulation belong to later work. EG22 remains undecided.
