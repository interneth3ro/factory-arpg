# Core game foundation implementation and acceptance

## Sequence and authority

**CF25, CF28.** Build the permanent game in the F1–F10 order below. Each milestone adds one capability that can be exercised before the next starts. F3 establishes the data contract, F5 proves a small save can restore the player, and F9 completes persistence across the playable systems. F4 supplies the physical spaces. Their inventories and mineable resources become functional in F7 and F8 respectively.

**CF27.** Use the [architecture](CORE_GAME_FOUNDATION_ARCHITECTURE.md) for ownership and persistence, the [gameplay specification](CORE_GAME_FOUNDATION_GAMEPLAY.md) for player-visible behavior and this plan for scope and acceptance. The [decision log](DECISION_LOG.md#core-foundation-decisions) maps each approval to its specification. PR #30's [reconciled factory progression](EARLY_GAME_GATHERING_AND_AUTOMATION.md) governs the later factory phase.

**CF26.** Review the exact diff and static references, exercise the applicable state invariants, then have the owner evaluate the observable behavior in Godot on the identified revision. Record the revision, checks, outcomes and remaining gaps. From F3 onward, check each new kind of state against its identity and serialization contract. From F5 onward, rerun the location-and-position restore check whenever the save contract changes. Keep the standalone arena independently launchable at every gate. Repeat affected combat checks against the accepted [melee](COMBAT_PROTOTYPE_V0.1.md), [player survivability](PR16_PLAYER_HEALTH_DAMAGE_DEATH.md), [feedback](PR17_COMBAT_IMPACT_FEEDBACK.md) and [pistol](RANGED_MAGIC_COMBAT_INPUT.md#pistol-checks) baselines.

**CF29.** At readiness review, compare the next milestone's dependencies and exclusions with merged work, identify the state or regression risks and agree on observable evidence. Surface a conflicting requirement for owner disposition before coding it. Close a milestone against its stated criteria and the owner's runtime result. At F10, record any remaining issue and its disposition before declaring the foundation ready for factory integration.

**CF30.** Permanent production begins with F1 after the completed combat foundation. Integrated factory gameplay follows F10, then a representative vertical slice and game expansion. This supersedes the earlier separate integrated-loop prototype prerequisite. [Development roadmap](../DEVELOPMENT_ROADMAP.md#3-roadmap-at-a-glance)

The checks below are planned for separately authorized implementation work. Engine execution, including headless tests, requires explicit owner authorization. After independent review, owner merge and cleanup of the documentation PR, F1 requires a fresh Codex session and separate owner authorization.

## F1 — Permanent game entry and session lifecycle

- **Dependencies.** Approved documentation and the existing standalone arena baseline.
- **Deliver.** A permanent main entry and game root that start and end a session with a minimal location. Shared-player extraction, authored world content and disk saves are outside F1.
- **Static or automated checks.** Resolve the configured main scene and its references. Trace initialization and teardown to verify that starting another session cannot retain the prior root or active location.
- **Owner runtime acceptance.** Run the project from its normal entry, confirm a usable session opens, then end it and start again. Both starts reach the permanent entry with one active session.
- **Regression.** Launch the arena directly and exercise its encounter reset independently of the main entry.

## F2 — Shared combat-capable player

- **Dependencies.** F1 and the accepted arena player, four combat styles and encounter controls.
- **Deliver.** A reusable player scene with modular movement, action and health responsibilities used by both entry points. Keep arena-only setup in the arena. Exclude new styles, mining, enemies in the permanent world and balance changes.
- **Static or automated checks.** Verify that both scenes reference the same player and that no required player reference points into the arena hierarchy. Review affected contact, feedback and pistol regression fixtures.
- **Owner runtime acceptance.** Move, aim, dodge and use all four styles in the permanent session. In the arena, land melee and pistol hits, take damage, die and restart. Check HUD and feedback against the baseline.
- **Regression.** F1 still starts cleanly. Arena F5 preserves the active style, clears pending input and restores HP. Encounter selection and diagnostics still work.

## F3 — World state, object identity and serialization contracts

- **Dependencies.** F1's session boundary and F2's shared player.
- **Deliver.** Scene-independent authoritative records, stable object IDs, explicit registration and versioned encode/decode contracts for foundation state. Exclude playable travel, user-facing saves and slot management.
- **Static or automated checks.** Round-trip a representative state record. Bind it, change it, unbind it and bind a fresh instance under the same ID. Check that an ambiguous registration or unsupported version cannot overwrite valid state.
- **Owner runtime acceptance.** Inspect a representative registered object, unload its owning scene and register it again in the session. The record survives the gap, and the new instance reflects the prior value.
- **Regression.** Starting a fresh session produces independent records. The shared player and standalone arena still start without a disk save.

## F4 — Starting world, home base, interaction and travel

- **Dependencies.** F1–F3 for location ownership, persistent player and registered world objects.
- **Deliver.** A small handcrafted region, separate home-base shell with reserved functional areas, shared interaction targeting and paired arrival anchors. Defer disk restore to F5, working storage to F7 and mining to F8. Exclude encounters, production and finished artwork.
- **Static or automated checks.** Check both ends of each passage, unique location/object IDs and resolvable destinations. Trace location replacement to verify that it retains the player.
- **Owner runtime acceptance.** Explore the region, use the passage home and travel back. Each direction arrives at its paired safe anchor. Repeat the trip and inspect player identity and location ownership across the swaps. Each interaction fires once.
- **Regression.** Unloaded location records survive both trips. Movement, aiming and collision work after arrival. The arena remains accessible directly.

## F5 — Early save and location restore

- **Dependencies.** F3's versioned records and F4's playable locations and placement rules.
- **Deliver.** An early save/load path that records and restores actual player location and position. Exclude complete inventory, container and mining persistence, autosave policy and multiple-slot workflows.
- **Static or automated checks.** Round-trip locations and distinct positions in each. Exercise an invalid location, unsafe position, unsupported data and a failed replacement write with disposable test data. Preserve the last valid save.
- **Owner runtime acceptance.** Save away from the entrance, travel elsewhere, end the session and reload. Verify the saved location and position. Repeat from the other location. Verify the invalid-placement case reports failure or yields a safe recovery.
- **Regression.** Ordinary travel continues to use paired anchors and the same player. Loading and traveling again must never create a second active player.

## F6 — Item definitions, backpack and inventory UI

- **Dependencies.** F2's player/input contexts, F3's state contracts and F5's restore baseline.
- **Deliver.** Data-driven item definitions, independent backpack state and a usable 24-slot inventory UI with item-specific capacity rules and 100-unit basic-resource stacks. Exclude physical storage transfers, mining and complete on-disk inventory persistence.
- **Static or automated checks.** Exercise empty, partly filled and full backpacks with controlled item data. Check stack overflow into a free slot, rejection at capacity and independent quantities for two inventories using the same definition.
- **Owner runtime acceptance.** Open a backpack with known contents. Count its slots, inspect the basic-resource stack boundary and verify displayed quantities agree with state. Interacting with the UI must not issue a world attack.
- **Regression.** Backpack contents survive ordinary travel. Closing inventory restores normal player control. F5 still restores location and position.

## F7 — General storage and safe transfers

- **Dependencies.** F4's physical base and interactions, F6's backpack and stack rules.
- **Deliver.** One physical 48-slot general-storage container at home with its own inventory. Support drag-and-drop, quick and partial-stack transfers. Exclude dedicated production storage, construction access, reservations, conveyor access and automatic sorting.
- **Static or automated checks.** Count each item type on both sides before and after transfers. Cover exact fit, partial fit, full destination, cancellation and repeated input. Check that container records use independent identities and expose no automatic material source.
- **Owner runtime acceptance.** Move a known stack each way using the three transfer modes. Try five basic units against a stack of 98 with no spare slot. Only two fit. Reopen the container after a round trip and verify both inventories.
- **Regression.** Backpack limits, UI input priority, F4 travel and F5 placement restore still hold. Complete disk persistence for contents belongs to F9.

## F8 — Manual mining and handcrafted deposits

- **Dependencies.** F2/F4 for player, targeting and authored sites, F3 for deposit records, F6/F7 for capacity and freeing backpack space.
- **Deliver.** The dedicated mining capability and manually placed, infinite, throughput-limited basic deposits. Implement stationary cycles, interruption, per-deposit partial progress and capacity-aware collection. Exclude rare-deposit content, extraction machines and background simulation.
- **Static or automated checks.** Interrupt two distinct deposits at different progress values, unload/rebind them and round-trip their state records. At completion check full, partial and zero capacity, then retry collection. Account for every whole unit awarded or still collectible and retain infinite yield.
- **Owner runtime acceptance.** Start with clear sight and range, move the cursor to another deposit while holding, then interrupt with movement, dodge, release, tool switch, lost range and obstruction. Reacquire, visit home and return. Confirm the original progress, single awards and safe collection after freeing space.
- **Regression.** Combat selection preserves its input rules. Travel retains one player, general storage still conserves items, and the F5 restore path works. F9 verifies the complete on-disk playthrough.

## F9 — Complete persistence, autosaves and independent slots

- **Dependencies.** F3/F5 save contracts and all playable player, location, container, backpack and deposit state through F8.
- **Deliver.** Complete manual and automatic saves with independent playthrough slots. Capture player location/position, persistent player and world records, inventory contents and in-progress or partially collected mining results. Exclude factory simulation and future production records.
- **Static or automated checks.** Round-trip two slots with different values for the same authored IDs. Check manual and automatic writes around travel, transfers and cycle completion. Simulate interrupted or failed writes on disposable data and recover the previous valid save.
- **Owner runtime acceptance.** Create two playthroughs with different locations, contents and mining progress. Resume each after quitting using both save paths across the trials. Collect an outstanding balance, save and reload again. Verify exact quantities, progress, placement and slot isolation.
- **Regression.** Recheck F5 placement and failure recovery, F7 item conservation and F8 single awards through load, travel and renewed mining. An arena launch or reset cannot change slot contents.

## F10 — End-to-end acceptance and targeted hardening

- **Dependencies.** F1–F9 delivered with their acceptance evidence.
- **Deliver.** A reviewed end-to-end result and fixes for demonstrated foundation defects. Exclude new gameplay, factory production, general refactoring and content expansion.
- **Static or automated checks.** Trace CF decisions to the delivered behavior and exact test revisions. Recheck serialization, failed writes, identity, item totals and slot isolation. Rerun relevant regressions for each fix under the repository's authorization rules.
- **Owner runtime acceptance.** From the permanent entry, mine, interrupt a second deposit, return home, transfer part of a stack and save away from an entrance. Resume, verify placement and both inventories, revisit each deposit and finish the interrupted cycle. Switch slots and back. Compare expected quantities and progress at every step.
- **Regression and closure.** Launch the arena independently, exercise the four styles, dodge, damage, death, reset and encounter selection. Record the owner's disposition of the complete journey, persistence failures and combat regressions. Unresolved material loss, duplication, unsafe restore or cross-slot contamination blocks foundation closure.
