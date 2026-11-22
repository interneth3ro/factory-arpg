# Factory ARPG — Early-Game Gathering, Integrated Home Base, and Automation Design

**Status:** Approved design decisions\
**Decision scope:** FM8–FM14, EG1–EG21, HB1–HB13, RC1–RC9\
**Project:** `interneth3ro/factory-arpg` (Godot 4.7.2)\
**Reconciled:** 2026-11-22\
**Implementation status:** Design only. This specification does not authorize implementation.

> This is the current intended design, not an additive appendix to the old workshop plan. The [decision log](DECISION_LOG.md#early-game-reconciliation) preserves the original approvals and traces their revisions. Illustrative recipes, quantities, capacities, rates, and distances are **not** approved balance values. Advanced manufacturing and logistics remain provisional. EG22 is not approved.

## 1. Vision and governing architecture

Factory ARPG is an isometric post-apocalyptic fantasy action RPG. Players explore handcrafted regions and dungeons, fight enemies, discover technology, and develop a persistent home-base factory. **Adventure reveals possibilities. Automation makes those possibilities reproducible. Engineering gives the player control over the outcome.**

- Prioritize responsive combat, intuitive controls, legible systems, practical construction, and manageable implementation complexity; no tower-defense obligation, forced factory defense, recurring recapture chores, or troop management.
- Use handcrafted finite world scenes. Basic resources are inexhaustible but throughput-limited; rare resources may be finite. Exhausted deposits remain visible and machinery recoverable.
- Remote production persists while scenes are unloaded under the same throughput, capacity, and material-conservation constraints as loaded areas.
- The home base is a persistent scene and connected buildable area, with **integrated smelting and standardized component crafting**, not an obligatory separate smelter-to-crafter conveyor chain.
- The home base has distinct raw-material intake, refined-material, and component storage; integrated services can access eligible downstream storage automatically. Separate **general storage** is completely isolated from production and automatic construction access at the start.
- Physical conveyor logistics remain important for remote extractors and later specialized manufacturing. The opening conveyor is optional extractor-to-industrial-storage infrastructure, not a required smelter-to-crafter link.
- Integrated crafting can manufacture complete **basic deployable industrial equipment**, including early extractors, industrial containers, and conveyor segments. Advanced industrial manufacturing mechanics are deliberately deferred.
- Equipment preparation and final RPG equipment engineering are separate: the base may prepare and reserve components, but **never automatically final-crafts a weapon or armor item**.
- Basic wireless transportation is a future visible research direction, not an early-game transport mechanism. EG22 and detailed wireless operation remain undecided.

## 2. Reconciliation authority and historical decisions

The following supersessions apply to the original early-game specification. They preserve the historical approvals without making obsolete workshop behavior normative:

| Original decision | Current authority | Effect |
|---|---|---|
| EG1 | HB1–HB2, RC1 | First major automation milestone is the remote extractor, not a smelter-to-crafter conveyor. |
| EG8 | HB1–HB2, RC1 | Preserve a two-material introduction but process through integrated base services. |
| EG9 | HB2, RC1 | No manual ingot transfer or conveyor between integrated smelting and crafting. |
| EG10–EG13 | HB3–HB11, RC2 | Original single-recipe machine/buffer specifics do not govern integrated production or bind future specialized machinery. Preserve broad compatibility, safety, predictable transitions, finite capacity and backpressure principles. |
| EG20 | RC4–RC5 | Player deposits into a chosen dedicated storage; no initial automatic sorting. General storage is isolated. |
| FM14 | RC3, RC5 | Construction draws from player inventory and **eligible** connected local storage, never isolated general storage. Reservation override details are provisional. |

**Still operative:** FM8–FM13; EG2–EG7; EG14–EG19; EG21, except where their descriptions refer to the obsolete first-workshop conveyor. RC9 extends EG19's backpressure behavior to connected industrial storage.

## 3. Construction, recovery, and inventory (FM8–FM14, EG7, RC3, RC5)

- Compatible conveyor edits preserve contents; removal recovers contents safely (FM8). Dismantling recovers intact machines (FM9). Smaller machinery can be portable; larger industrial machinery eventually requires specialized transport or construction capabilities (FM10).
- Committed local relocation safely cancels production, returns unconsumed materials and discards partial progress; canceling an uncommitted move leaves the machine unchanged (FM11).
- Dismantling requires enough player-inventory or eligible storage capacity and must not destroy items (FM12). Dismantled/redeployed machinery resets recipe, settings, and connections; local relocation preserves configuration (FM13).
- Home-base construction can use carried items and eligible accessible **production-connected** local storage; remote construction requires physically available materials. Isolated general storage is not automatically eligible (FM14, RC5).
- Use hybrid slot-based inventory with stackable resources and ordinary components, with differentiated handling for weapons, armor, tools, portable machines, and large machinery. Exact slot and stack counts are open.
- Manual mining awards enter inventory automatically when space permits. Full inventory pauses safely; recovery, retrieval, and transfer operations must not lose or duplicate materials.
- **Provisional RC3:** Automatic production respects reservations; direct construction/crafting ordinarily uses unreserved materials. If reserved materials are needed, present an explicit player-approved reallocation with clear consequences. Protect ready-for-assembly commitments and preserve state if a transaction fails. Future cross-system design may supersede the detailed interaction.

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

## 5. Home-base storage and manual material handling (HB2, RC4–RC5, RC7)

| Storage | Initial role | Automatic access |
|---|---|---|
| Raw-material intake | Player-deposited ore and other smelting feedstock | Integrated smelting |
| Refined-material storage | Smelting output and refined inputs | Integrated crafting |
| Component storage | Standard and prepared components | Eligible integrated production goals |
| General-purpose storage | Inventory relief, spare materials, loot and safekeeping | **None**: no smelting, crafting, research, reservations, construction or conveyor access |
| Industrial storage container | Deployable local factory storage, including remote extraction sites | Physical conveyor input/output; not a global link to home base |

- Players select the appropriate storage and may bulk-deposit compatible items into that chosen inventory. **No automatic category sorting or central deposit routing at the start.** Bulk deposit leaves equipped items, tools, portable machines, and player-protected items in inventory.
- General storage is deliberately independent. Materials there must be manually retrieved and moved into eligible production storage before integrated services can use them. A future limited research-enabled connection is only a possibility, not an approved feature.
- Transfers obey capacity, preserve items, and leave non-fitting items at their source. General storage is not a hidden construction or research material source.
- Dedicated inventories have visible physical identities; integrated smelting can deposit refined output into refined storage and integrated crafting can draw from it without a player carrying ingots between facilities.

## 6. Integrated smelting, crafting, and production goals (HB1–HB11)

### Integrated smelting

- Smelting operates as a home-base service with dedicated raw input and refined output storage (HB1–HB2).
- Players may create **finite** processing instructions (e.g., process a specified amount) or **continuous** instructions (process while eligible unreserved inputs and output space exist).
- One initial processing channel schedules eligible instructions **round-robin**; missing input or blocked output is skipped without deleting instructions. Finite quantities count down; continuous instructions persist (HB3).
- Finite instructions reserve available raw inputs and automatically reserve later deposits up to outstanding requirements; they may be created before fully funded. Continuous instructions reserve nothing and use only unreserved inputs. Reducing/canceling an order releases unused reservations (HB4).
- Upgrades may improve processing speed, batch capacity, and parallel channels; smaller batches remain possible. Active cycles finish under their starting parameters when upgrades occur. Multiple channels share inputs/outputs and observe fair scheduling (HB5). Exact rates and upgrade tiers are open.

### Integrated component crafting

- Supports finite and continuous basic/standard component orders; finite orders reserve ingredients and continuous orders use unreserved inputs (HB6).
- Research and base upgrades may expand the set of **standardized** components supported, separately from speed, batch and parallel-capacity upgrades. Recipes requiring genuinely specialized processes remain physical-manufacturing candidates (HB11).
- Integrated crafting can also produce **complete basic deployable industrial equipment**, such as extractors, industrial storage containers, and conveyor segments, through deterministic recipes (RC8). This does not define the fabrication method for advanced industrial machinery.

### Goal-directed preparation and reservations

- A selected equipment design can recursively identify required refined materials, intermediate parts and standard components. The base queues eligible integrated work and identifies missing specialized requirements, without claiming automatic control of advanced machines (HB7).
- Multiple goals have **player-ordered material-allocation priorities**. Higher-priority goals receive available materials first; changing priority may reallocate unconsumed reservations with clear feedback, but does not interrupt active production cycles. Smelting processing time remains governed by HB3 round-robin scheduling (HB9).
- Prepared components remain in ordinary component storage **reserved for the goal**. When all requirements are present, the goal becomes **Ready for Assembly**; ready reservations persist across priority changes until the player crafts, modifies, or cancels the goal (HB10).
- Canceling a goal releases unused reservations while preserving manufactured components. Partially funded goals wait for new eligible deposits. Exact multi-goal allocation edge cases remain open.
- The player deliberately initiates **final weapon/armor crafting**, selecting blueprint, materials and available engineering methods; these influence visible bounded random outcome ranges. Preparation alone never produces the final RPG equipment (HB6–HB8). Exact RNG, item statistics and advanced experimentation are not finalized.

## 7. Revised opening progression (RC1, RC6–RC8)

1. Discover the home base's dedicated storage and integrated processing interfaces.
2. Mine two introductory resource types manually with the handheld mining laser; deposit each into the appropriate raw-material intake.
3. Configure smelting instructions and use integrated crafting to produce standard components. Example only: Iron Ore → Iron Ingot → Metal Plate; Copper Ore → Copper Ingot → Conductive Wire; both → Basic Mechanism.
4. Manufacture the first **extractor** through integrated crafting; transport and deploy it beside a compatible ore deposit in the world.
5. Observe unattended ore production into the extractor's finite output buffer; manually collect and haul ore back to the home base, depositing it into raw-material storage.
6. Optionally craft and deploy **industrial storage containers** and conveyor segments to extend local extractor output capacity. The extractor works without these additions.
7. Introduce specialized physical manufacturing when it offers a meaningful process. No initial smelter-to-crafter conveyor is required.

The **first major automation milestone is the extractor**. Integrated processing teaches automated transformation beforehand. Keep opening goals useful and avoid excessive hauling or forced tutorials.

## 8. Physical conveyors and industrial storage (EG14–EG15, RC6–RC9)

- Build conveyors by dragging between fixed ports, with automatic corners and a choice of horizontal-first or vertical-first L-shaped routes. Explicit splitters and mergers support branching, with round-robin distribution at splits.
- Physical conveyors move items between compatible ports and industrial containers; incompatible or blocked destinations cause visible backpressure, not deletion, bypass or teleportation.
- Inspect any segment, even an empty one, to see its direction, contents, and the cause of a blockage. Retrieving an item transfers it in full to inventory if it fits. Otherwise it stays on the belt. Whether inspection pauses moving items is provisional.
- The first optional conveyor connects a remote extractor to nearby industrial storage. Industrial storage is **not** the isolated home-base general storage and has no implicit link to base production.
- Extractor output may move into connected storage while capacity and physical throughput permit. If its internal buffer fills because downstream transport or storage cannot accept more, extraction pauses and resumes when capacity frees (RC9).
- Loaded and unloaded operation must conserve materials and respect extraction rate, conveyor transfer capacity, finite storage, and backpressure. Unloaded simulation may be aggregated rather than per-item if observable behavior is equivalent.
- Detailed port filtering, route algorithms, advanced goal-aware routing and specialized machine buffering are **deferred** (RC2, HB13).

## 9. Automated extractors and deposit capacity (EG16–EG19, RC9)

### Placement and operation

- The first extractor is placed on valid ground adjacent to a compatible deposit rather than covering the deposit itself.
- Placement requires a clear footprint, a deposit within extraction reach, and an unobstructed direct connection. The connection forms automatically and is visibly represented.
- The extractor autonomously advances discrete extraction cycles and places completed resources in an internal output buffer.
- A full buffer pauses production safely; freeing capacity automatically resumes it without losing materials or partial-cycle progress.
- The same extractor can feed an optional early conveyor to nearby industrial storage and can support wireless logistics once researched.

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
- A full remote extractor or connected industrial storage is a normal paused state, not an emergency demanding intrusive alerts or mandatory maintenance.

**Unapproved tuning:** Extractor rates, deposit capacities, buffer sizes, reach, and unattended-duration targets remain provisional. Prior examples such as 20/30/60 ore per minute or 40-item buffers were illustrative only.

## 10. Wireless research boundary (EG21 only)

- **Approved:** Basic wireless resource transportation is a visible, achievable goal in the technology tree, unlockable through normal research and workshop production.
- Exploration discoveries may contribute to foundational understanding and reveal specialized or advanced wireless technologies, without making one obscure artifact a mandatory bottleneck for basic transportation.
- Existing overarching direction: physical transmitter/receiver machinery, initially dedicated pairs, finite throughput and buffers, and backpressure; advanced network capabilities come later.
- **Not decided here:** Pairing interaction, endpoint relocation/removal behavior, transmission timing, energy requirements, range, network routing, connection UI, and other wireless operational rules.
- **EG22 is not approved and must not be inferred from illustrative diagrams or earlier brainstorming suggestions.**

## 11. Specialized manufacturing and future logistics boundary (HB11–HB13, RC2–RC3)

- The direction in HB11–HB13 is approved. Detailed advanced manufacturing and logistics mechanics remain provisional.
- Integrated standardized manufacturing expands with research, but some processes require dedicated physical machines and material transportation. Classify by required process rather than rarity (HB11).
- Specialized machines use physical conveyor connections and convenient storage interfaces; their detailed behavior is **not** specified here (HB12).
- Automatic **goal-aware routing** is a future capability direction, not an opening-game requirement or a finalized routing algorithm. The player initially builds and configures physical infrastructure; later research may enable coordination (HB13).
- Do not infer exact port filtering, machine discovery, buffer structures, reservation tracking in transit, cancellation handling, or factory-wide priority algorithms from the conceptual direction.
- Preserve material safety and clear feedback; revisit cross-system rules during dedicated advanced-manufacturing design.

## 12. Open questions, provisional details and authority limits

- Exact resource names, recipes, crafting costs, smelting/crafting throughput, batch sizes, channel counts, storage capacity, extractor output capacity, conveyor speed and physical dimensions.
- Mining range (approximately 120 world pixels was only a proposed test starting point), valid target geometry, LOS/collision tolerance, and VFX timing.
- Inventory size, stack rules, protected-item UI, deployable-equipment transport constraints, and industrial container dimensions.
- Detailed reservation contention, partial funding, reallocation UX, goal cancellation during active production, and atomicity edge cases.
- Eligible construction inventories beyond the isolation of general storage; detailed RC3 override flow is provisional.
- Specialized machinery recipes, production cycles, buffers, routing and advanced engineering; no detailed advanced-manufacturing implementation is authorized by HB11–HB13.
- Loaded/unloaded remote simulation algorithm and exact numerical integration behavior; equivalence of outcomes is required.
- Timing and details of wireless transport, including EG22 pairing, endpoint relocation/removal, range, energy, network UI and operation.

## 13. Documentation and implementation boundary

This revision records design decisions only. It does **not** authorize gameplay implementation, new assets, or other code changes. After documentation review and owner merge, implementation requires separate authorization from synchronized `main`, independent review, and Godot runtime acceptance according to the project's workflow.
