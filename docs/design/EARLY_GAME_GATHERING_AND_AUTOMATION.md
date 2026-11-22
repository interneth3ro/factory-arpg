# Factory ARPG — Early-Game Gathering, Workshop, and Automation Design

**Status:** Approved design decisions consolidated for a documentation-only PR\
**Decision scope:** FM8–FM14 and EG1–EG21\
**Project:** `interneth3ro/factory-arpg` (Godot 4.7.2)\
**Last consolidated:** 2026-11-22\
**Implementation status:** Design only; no implementation authorized by this document.

> This specification records decisions approved during brainstorming. Illustrative item names, recipe quantities, pixel distances, capacities, and production rates are **not** approved balance values. EG22 (wireless pairing and operation) and subsequent wireless mechanics are explicitly out of scope.

## 1. Vision and design principles

Factory ARPG is an isometric post-apocalyptic fantasy action RPG and factory automation hybrid. Players explore handcrafted regions and dungeons, fight enemies, discover technology, collect resources, and build a persistent home-base factory.

**Adventure reveals possibilities. Automation makes those possibilities reproducible. Engineering gives the player control over the outcome.**

- Prioritize intuitive controls, responsive combat, straightforward construction, and manageable implementation complexity.
- Factory development supports exploration; it is not tower defense. Do not impose forced factory defense, recurring recapture chores, or troop-management systems.
- Use handcrafted, finite world scenes rather than infinite procedural terrain.
- Basic resources remain inexhaustible but throughput-limited; rare resources may be finite. Exhausted deposits remain visible, and installed machinery can be recovered.
- Remote production persists while scenes are unloaded, subject to the same constraints as loaded production.
- The home base is a dedicated persistent scene with a continuous connected buildable area, initially containing a smelter, crafting/assembly station, and storage.
- Favor physical, conveyor-first logistics with fixed machine ports, explicit splitters/mergers and round-robin distribution; conveyor construction supports drag-to-build, automatic corners, and switchable horizontal-first/vertical-first L-shaped routes.
- Basic wireless transportation eventually uses physical transmitter/receiver machines, dedicated pairs, finite buffers, throughput and backpressure. Detailed wireless mechanics are deferred.

## 2. Previously approved construction and material handling (FM8–FM14)

| ID | Approved option | Decision |
|---|---|---|
| FM8 | B | Preserve materials during compatible conveyor modifications; safely recover contents during removal. |
| FM9 | B | Dismantling recovers machines intact rather than converting them into raw construction materials. |
| FM10 | C | Hybrid machine transport: smaller machinery is portable; larger industrial machinery eventually requires specialized construction/transport capabilities. |
| FM11 | C | Committed local relocation safely cancels active production, returns unconsumed materials, and discards partial production progress. Canceling an uncommitted move leaves the original machine unchanged. |
| FM12 | B | Dismantling recovers into player inventory or accessible storage. Insufficient capacity blocks dismantling without loss. |
| FM13 | A | Recovered/dismantled machines reset recipes, operating settings, and connections when redeployed. Local relocation is distinct and preserves configuration. |
| FM14 | B | Home-base construction draws from player inventory and accessible local storage; remote construction uses physically available materials, not unrestricted global storage. |

These decisions remain in force alongside the early-game rules below. In particular, **local relocation** and **dismantle/redeploy** are distinct operations.

## 3. Approved early-game decisions (EG1–EG21)

| ID | Approved option | Decision |
|---|---|---|
| EG1 | C | Small integrated automation milestone: manual gathering and processing, a short home-base conveyor connection, then a modest automated extractor initially requiring manual output collection. |
| EG2 | B | Discrete manual extraction cycles; interrupted partial-cycle progress is retained on the deposit. |
| EG3 | A | Stationary mining; movement interrupts extraction without losing saved deposit progress. |
| EG4 | A | Direct cursor targeting of eligible deposits, subject to range and unobstructed line of sight. |
| EG5 | B | Lock mining target while primary input is held; cursor movement alone does not switch deposits. |
| EG6 | B | Contextual world-space mining feedback rather than a persistent detailed mining HUD. |
| EG7 | C | Hybrid slot-based inventory with item-handling distinctions and automatic mining collection. |
| EG8 | B | Two-material opening workshop chain with processing and component assembly. |
| EG9 | B | Guided manual-to-automated workshop transition. |
| EG10 | B | Continuous production of one selected machine recipe whenever operating conditions permit. |
| EG11 | C | Strict recipe-based conveyor acceptance; flexible manual insertion of machine-supported materials. |
| EG12 | B | Finish an active production cycle before switching recipes; idle machines switch immediately. |
| EG13 | C | Shared machine buffers with active-recipe input-capacity protection. |
| EG14 | B | Physical conveyor delivery and backpressure with clear blockage feedback and recovery. |
| EG15 | B | Contextual conveyor inspection and item retrieval. |
| EG16 | B | Adjacent extractor placement with a visible direct connection to a compatible deposit. |
| EG17 | B | Shared deposit throughput, equal allocation among active automated extractors, redistribution of unused capacity. |
| EG18 | C | Manual mining receives temporary priority within the same deposit throughput limit. |
| EG19 | B | Moderate fixed extractor output buffer with safe backpressure and unattended operation. |
| EG20 | B | Player-carried remote resources with convenient home-base bulk unloading. |
| EG21 | C | Hybrid wireless research unlock: foundational transportation visible through normal research, with exploration contributions and advanced discoveries. |

## 4. Handheld mining laser and deposits (EG2–EG6, EG18)

### Targeting and operation

- The selected mining laser uses the primary action and direct cursor targeting. A deposit must be eligible, in range, and visible along an unobstructed line of sight to begin mining.
- Mining requires the player to remain stationary. Movement, dodge, releasing the primary input, switching tools/combat actions, leaving range, or losing line of sight promptly interrupts mining.
- Once mining starts, the deposit remains locked while the primary action is held and conditions remain valid. Moving the cursor elsewhere neither switches targets nor independently interrupts mining. A new deposit requires a fresh acquisition action.
- Mining uses discrete extraction cycles; completed cycles award resources. Partial progress from an interrupted cycle remains associated with the deposit.
- Completed resources enter the player's inventory automatically when capacity permits; insufficient space safely pauses collection/extraction without loss.

### Feedback

- Subtly highlight eligible hovered deposits and communicate out-of-range or obstructed targeting.
- Show an active beam, restrained impact effects, and a small contextual progress indicator near the deposit.
- Show completed-cycle resource awards without overwhelming the screen with repeated notifications.
- Distinguish finite remaining reserves from inexhaustible basic resources.
- Keep combat telegraphs and hazards more visually prominent than mining effects.

### Throughput interaction

- The handheld laser shares the deposit's total throughput with automated extractors, but receives temporary priority while valid mining is active, up to the laser's own capacity.
- Automated extractors divide the remainder according to EG17. Manual priority ends immediately when mining ends; hovering or merely equipping the laser reserves nothing.
- Changes in throughput alter cycle progression rather than awarding fractional inventory items. Retained progress must not be discarded because automated extraction is present.

**Unapproved tuning:** An approximately **120-world-pixel** mining range was proposed solely as a starting point for testing. Measure range against a valid mineable point on deposit geometry rather than automatically using the deposit center; collision geometry, line-of-sight details, and exact range need runtime validation.

## 5. Inventory, recovery, and collection (EG7, FM10–FM14)

- Use familiar slot-based inventory with stackable raw resources and ordinary components.
- Weapons, armor, tools, portable machines, and large industrial machinery have appropriate distinct handling rules. Exact slot counts, stack sizes, and machine-carrying capacity are undecided.
- Completed manual mining cycles collect automatically when capacity allows. Do not silently discard or drop resources when full.
- All retrieval and recovery operations preserve items: failed transfers leave source items intact, with no loss or duplication.
- Home-base construction can access inventory and eligible local storage; remote construction cannot access global storage without physical logistics.
- Dismantling and local relocation obey FM8–FM13, including safe material recovery and the distinction between preserved configuration on relocation and reset configuration on redeployment.

## 6. First workshop chain and teaching sequence (EG1, EG8–EG9)

### Two-material introductory chain

The player manually gathers two basic resources, processes them at the starting smelter, and manufactures components at the crafting/assembly station. An **illustrative, unapproved** example is:

- Iron Ore → Iron Ingot → Metal Plate
- Copper Ore → Copper Ingot → Conductive Wire
- Metal Plate + Conductive Wire → Basic Mechanism

Names, ingredient quantities, recipes, and times remain provisional.

### Opening progression

1. Discover and inspect the starting smelter, crafting/assembly station, and storage.
2. Gather two basic resources manually and process an initial batch in the smelter.
3. Manually carry processed materials to the crafting station and make useful initial components.
4. Build a short conveyor from the smelter output port to the crafting station input port.
5. Run another compatible batch and visibly observe automated material transfer.
6. Manufacture and deploy the first modest automated extractor; initially collect its output manually.

The first conveyor must replace a real manual transfer. Keep the opening route simple and single-material when needed; do not require splitters, mergers, filters, or complicated routing to complete the introductory milestone. Teach through usable machines and visible goals rather than lengthy forced tutorials.

## 7. Machine recipes, buffers, and production (EG10–EG13)

### Continuous operation

- Each machine has one active recipe. It automatically repeats production while required inputs, output capacity, and operating conditions are available.
- The machine pauses on missing inputs, blocked output, or other unmet operating requirements; it resumes when conditions permit.
- Manual insertion and removal remain possible when conveyors are attached.
- Machine interfaces should expose the active recipe, inputs, outputs, progress, and understandable operating/blockage states.

### Input compatibility

- Conveyor-delivered materials are accepted only if required by the **currently active recipe**; incompatible items remain on the conveyor and obey backpressure.
- Players may manually insert other materials supported by the machine. Such materials remain stored, unconsumed by unrelated recipes, and manually retrievable.

### Recipe switching

- A requested change during an active cycle becomes pending. The machine completes only that current cycle, safely deposits its output, then activates the new recipe.
- If no cycle is active, the change takes effect immediately.
- A blocked completed output delays the pending switch until it can be deposited; nothing is deleted.
- Previously stored inputs and outputs remain in their buffers across recipe changes.

### Buffer allocation

- Inputs and outputs use shared capacity. The active recipe receives automatic protection of sufficient input space for its required ingredients, initially targeting one complete cycle.
- Ingredients already present count toward that protection. Players need not configure reservations manually.
- Recipe changes update protection without deleting or ejecting contents. If existing contents prevent the required protected capacity, retain them and clearly report the blocked condition.
- Output buffers use shared capacity without automatic per-recipe reservations; full outputs impose backpressure.

Exact machine buffer sizes, reserved-space calculations in edge cases, and production timing are not approved numbers.

## 8. First conveyor and direct interaction (EG14–EG15)

- The first conveyor connects a smelter output port to a compatible crafting-station input port and physically moves completed items.
- Incompatible items stop at the destination and remain on the conveyor; blocked deliveries create backpressure upstream. No automatic bypass, teleportation, deletion, or implicit diversion occurs.
- Contextual feedback identifies the blocked item and cause. Recovery can involve changing the recipe, retrieving the item, or changing the route.
- Players use standard contextual interaction on a conveyor segment to inspect its contents, direction/status, and blockages, and retrieve an item without dismantling the belt.
- Retrieval is capacity-checked and atomic: the item moves completely to inventory or remains on the conveyor. Empty segments remain inspectable.
- Whether opening inspection temporarily holds a moving item is **provisional**, not a finalized timing/concurrency rule.

## 9. First automated extractor and deposit capacity (EG16–EG19)

### Placement and operation

- The first extractor is placed on valid ground adjacent to a compatible deposit rather than covering the deposit itself.
- Placement requires a clear footprint, a deposit within extraction reach, and an unobstructed direct connection. The connection forms automatically and is visibly represented.
- The extractor autonomously advances discrete extraction cycles and places completed resources in an internal output buffer.
- A full buffer pauses production safely; freeing capacity automatically resumes it without losing materials or partial-cycle progress.
- The extractor can later feed conveyors and wireless logistics without replacement.

### Shared throughput

- Every deposit has a maximum extraction throughput. Basic deposits have inexhaustible lifetime yield but limited rate; finite deposits also track remaining resources.
- Multiple automated extractors may connect to one deposit. Each has its own maximum production rate.
- Active extractors share deposit throughput equally, with unused shares redistributed to extractors capable of using them. Inactive or output-blocked extractors do not claim capacity.
- The sum of manual and automated extraction never exceeds deposit capacity; EG18 grants active manual mining temporary first allocation.
- Deposit and extractor inspection should communicate throughput limits, utilization, and relevant operating constraints.

### Output collection and unattended operation

- The basic extractor has a **moderate fixed** output buffer, sized through testing to support useful unattended production while leaving later logistics meaningful.
- **Collect Available** transfers as much output as the player's inventory can accommodate; leftovers remain in the extractor.
- Production obeys the same throughput, capacity, and pause rules in loaded and unloaded scenes. Being away cannot bypass limits or create extra resources.
- A full remote extractor is a normal paused state, not an emergency demanding intrusive alerts or mandatory maintenance.

**Unapproved tuning:** Extractor rates, deposit capacities, buffer sizes, reach, and unattended-duration targets remain provisional. Prior examples such as 20/30/60 ore per minute or 40-item buffers were illustrative only.

## 10. Early remote collection and home-base unloading (EG20)

- Before wireless logistics, players physically visit remote extractors, collect available resources into inventory, and carry them home.
- At the home base, **Deposit Resources** bulk-transfers eligible raw materials and ordinary components into accessible storage, subject to capacity.
- Equipped items, tools, portable machines, and player-protected items are excluded from automatic bulk depositing.
- Items that do not fit remain in inventory; nothing is dropped, lost, or duplicated.
- Remote storage is physically local; it cannot access home-base inventory through an implicit global link.
- Early resource and crafting requirements should avoid excessive repeated hauling trips.

## 11. Wireless research boundary (EG21 only)

- **Approved:** Basic wireless resource transportation is a visible, achievable goal in the technology tree, unlockable through normal research and workshop production.
- Exploration discoveries may contribute to foundational understanding and reveal specialized or advanced wireless technologies, without making one obscure artifact a mandatory bottleneck for basic transportation.
- Existing overarching direction: physical transmitter/receiver machinery, initially dedicated pairs, finite throughput and buffers, and backpressure; advanced network capabilities come later.
- **Not decided here:** Pairing interaction, endpoint relocation/removal behavior, transmission timing, energy requirements, range, network routing, connection UI, and other wireless operational rules.
- **EG22 is not approved and must not be inferred from illustrative diagrams or earlier brainstorming suggestions.**

## 12. Open questions and provisional details

The following are not approved implementation requirements:

- Exact mining range (120 world pixels was an illustrative starting point), target geometry, collision/LOS tolerances, and visual-effect timings.
- Inventory size, stack limits, portable-machine capacity, and precise protected-item UX.
- Final resource/component names, recipes, ingredient ratios, machine rates, and production times.
- Machine input/output capacities, precise reservation edge cases, and item-buffer transaction timing.
- Conveyor speed, per-segment item occupancy, interaction pauses, and detailed blockage/retrieval UX.
- Extractor footprint, connection reach, output capacity, throughput numbers, and balancing of unattended collection intervals.
- Exact loaded/unloaded production simulation architecture and numerical integration behavior.
- Wireless pairing, operation, endpoint management, and subsequent wireless-network decisions (beginning with EG22).

## 13. Documentation and implementation boundary

This document is intended for a **documentation-only specification PR**. It does not authorize gameplay implementation, new assets, Codex work, or other repository changes. After the specification is reviewed and merged, implementation must be separately authorized from synchronized `main`, following the project's normal PR, independent review, and Godot runtime-acceptance workflow.
