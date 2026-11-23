# Foundation F3 — World State, Object Identity and Serialization Contracts

**Status.** The owner approved F3-A through F3-E. F1 and F2 are complete. F3 implementation requires a separately authorized PR after this specification merges. The milestone plan governs scope and acceptance. [F1–F10 plan](CORE_GAME_FOUNDATION_IMPLEMENTATION.md) · [Foundation architecture](CORE_GAME_FOUNDATION_ARCHITECTURE.md) · [Decision log](DECISION_LOG.md#foundation-f3-decisions)

## Session boundary inherited from F1 and F2

The permanent entry prepares a candidate session off-tree, attaches it after successful initialization and frees it on failure. The session owns the shared `Player` and the `ActiveLocation` host as siblings. It instantiates the placeholder under that host and binds its HUD to the player after attachment. End Session tears down the location and frees the session before the entry offers another start. F3 gives the registry that same session lifetime. Recreating the placeholder keeps the session, player and permanent HUD alive. [Entry lifecycle](../../scenes/game/permanent_game_entry.gd) · [Session scene](../../scenes/game/game_session_root.tscn) · [Session lifecycle](../../scenes/game/game_session_root.gd)

Both the permanent session and the standalone arena instantiate the shared player. Health, movement, action timing, hit detection, projectiles and transient combat state stay with the existing combat components. Each context owns its HUD. The arena supplies its own targets, cover, encounter controls and resets. Its direct launch requires neither a permanent session nor a registry or disk save. [Shared player](../../scenes/combat/shared_player.tscn) · [Player coordinator](../../scenes/combat/combat_test_player.gd) · [Arena scene](../../scenes/combat/combat_test_arena.tscn)

## F3-A — Typed Records with Central Registry

**Option B.** Each permanent game session owns one authoritative registry. A record holds the typed, validated persistent values for one identity. A binding associates a live object with its record for as long as that instance is registered. Freeing the instance ends that association. The record remains available even when its scene is absent.

The record type defines its fields, valid values and permitted changes. Unvalidated dictionaries cannot serve as the authoritative domain model. Introduce further types when their milestones require them. Mutable records belong exclusively to their session. A global singleton sharing those records across sessions would violate CF4 and playthrough isolation under CF8.

## F3-B — Location-Scoped Persistent Object IDs

**Option B.** Each persistent location has a stable authored location ID. Each persistent object in it has a stable authored object ID. The logical identity is the pair `location_id + object_id`. The same local object ID in two distinct locations names two distinct records. Reserve a separate session scope for entities owned by the session, including a future persistent player-state identity. A location cannot claim that scope. F3 need not serialize player state.

Within a playthrough each identity designates exactly one persistent object. Reject ambiguous or duplicate identities. A node path, runtime instance ID, load order, traversal order, incidental node name or number of visits cannot determine a persistent identity. Another playthrough may reuse the same authored pair with independent mutable values. Dynamic construction and runtime-generated persistent IDs are deferred until gameplay requires them.

## F3-C — Explicit Location-Managed Registration

**Option B.** The session coordinates the registry. A location-level coordinator explicitly manages the whole set of persistent objects its scene proposes to bind. The required lifecycle is **Prepare → Validate → Bind → Operate → Unbind**.

| Phase | Responsibility and observable result |
| --- | --- |
| Prepare | Collect the candidate instances, authored identities, expected record types and initial values for new records. Keep the proposal separate from live records and bindings. |
| Validate | Check the complete set, including scope, identities, instance eligibility, field validity, existing record types and current bindings. Reject ambiguity, duplicate identities within the proposal, a second live claimant or an incompatible type. The result is independent of traversal order. |
| Bind | Commit the complete validated set together. Create a typed record from valid authored defaults only for a previously unseen identity. For a known identity, bind the new instance and initialize its display from the existing record. Any registration failure leaves all prior values and bindings intact and publishes none of the proposed records or bindings. |
| Operate | A currently bound instance may request a typed state change. Validate the binding and proposed value before changing the authoritative record. The instance reflects the accepted value. A rejected request preserves the last valid value. |
| Unbind | On unload, release the runtime association and retain the record. Check which instance owns the current binding on both mutation and unbind. A late request from an old instance can neither change the value nor unregister its replacement. |

On a failed session start, dispose of the candidate and its registry through F1's failure path. Ending an active session releases all bindings and records. Starting another creates an independent registry. The coordinator class, method names and node hierarchy are implementation choices. The controlled unload/rebind exercise below is sufficient for F3.

## F3-D — Versioned Envelope and Independently Versioned Typed Records

**Option B.** Encode one coherent snapshot of the session's authoritative records, including records whose scenes are unloaded. The top-level envelope declares its format version. Each entry carries its stable scoped identity, explicit type identifier, that type's schema version and its validated persistent values. Each record type versions its fields independently of the envelope and of other types.

Encode only structured data sufficient to reconstruct those values. Exclude live scene instances, Godot node references, bindings, signal connections, transient input and arena encounter state. A valid encode followed by decode must reproduce equivalent identities, types and authoritative values.

Decode into a separate candidate. Check the structure and supported envelope version, then every identity, type, record schema version and value. Reject unknown or incompatible types, unsupported versions at either level, duplicate or conflicting identities, invalid fields or values, and malformed structured state. Adopt the recovered records together only after the entire candidate passes. Report failure and preserve the previously valid authoritative state, even if the last entry is the only invalid one. F3 uses this contract in memory. Historical migration awaits a concrete compatibility requirement. The disk format and write workflow belong to later persistence work.

## F3-E — Visible Development-Only Persistent State Marker

**Option B.** Place a small visible development-only marker in the F1 placeholder location. Give it a stable authored identity and a simple inspectable typed value, such as a counter. On first registration it displays the initial record value. Change the value through its binding, then unload the owning placeholder. The marker instance disappears and its record remains inspectable in the session. Recreate the placeholder with a fresh instance under the same identity. The marker displays the value recorded before unloading. After End Session and a new start, the same authored marker displays its initial value. [F1 placeholder](../../scenes/game/f1_placeholder_location.tscn)

Minimal development controls may change the value and trigger controlled scene recreation. Recreation must remain available while the placeholder is absent. Preserve movement, dodge, combat input and End Session throughout the exercise. The marker demonstrates record ownership and requires no deposit, container, factory object or gameplay interaction system.

## Milestone boundaries

| Milestone | Work reserved for that milestone |
| --- | --- |
| F4 | Playable locations, paired travel anchors and shared interaction targeting. |
| F5 | Early disk save/load and restoration of the player's actual location and position under CF23. |
| F6 and F7 | Item and backpack records and inventory UI in F6. Physical general storage, container records and transfers in F7. |
| F8 | Mining, extraction cycles, deposit-owned progress and outstanding awards under CF31. |
| F9 | Complete disk persistence, user-facing manual and automatic saves and independent playthrough slots. |
| F10 and beyond | F10 covers end-to-end acceptance and targeted hardening. Integrated factory production and simulation follow the foundation. |

F3 excludes combat redesign, balance changes and general-purpose frameworks beyond these demonstrated needs. [Milestone plan](CORE_GAME_FOUNDATION_IMPLEMENTATION.md) · [Gameplay scope](CORE_GAME_FOUNDATION_GAMEPLAY.md)

## Verification matrix for the implementation PR

Under CF26 and CF29, review the exact implementation diff and static references, exercise the deterministic contract cases and record the owner's Godot results against the tested revision. Static review alone cannot establish runtime correctness.

| Contract | Static inspection or deterministic exercise | Required result |
| --- | --- | --- |
| First registration and mutation (A–C, E) | Bind an unseen marker and request a different valid value. Then request an invalid value. | Exactly one record and binding exist. The record and display reflect the accepted change and retain it after rejection. |
| Unload and rebind (A–C, E) | Unbind and unload the location, inspect its record, then bind a fresh instance with the original authored defaults. | The record retains the changed value while unbound. The new marker reads that value. |
| Scoped identity (B) | Use the same local object ID in two locations. Revisit one with changed node names or traversal order. | The locations have distinct records. The revisit resolves the original pair. |
| Conflicting registration (B, C) | Include a valid unseen object alongside a duplicate proposed ID, an already bound identity, an ambiguous scope or an existing record of incompatible type. Repeat each case in reverse order. | Reject each complete set. Prior records and live bindings survive. The valid unseen object acquires neither a record nor a binding. |
| Stale binding (C) | After rebinding, request mutation and unbind using the old association. | Both fail to affect the replacement. It remains bound and can update its record. |
| Representative round-trip (A, D) | Encode the changed marker while unbound and decode into a fresh registry. Inspect the envelope and record. | The scoped identity, type and value round-trip using the declared versions. The snapshot contains persistent data only. |
| Unsupported versions (D) | Change only the envelope version to an unsupported one. Separately change only the record schema version. | Each candidate is rejected in full. Previously valid state survives both attempts. |
| Malformed or conflicting snapshot (B, D) | Try malformed structure, duplicate or conflicting identities, an unknown or incompatible type, and an invalid value. Include a valid changed record before a bad entry. | Reject each entire candidate. Compare all identities, types and values before and after failure. No valid prefix is adopted. |
| Session isolation (A, B, E) | Change the marker, end the session and start another with the same authored identity. | The old registry and associations are released. The fresh record starts at its authored initial value. |
| Player and arena independence | Trace both entry paths to the shared player and inspect the arena and combat fixtures for registry dependencies. | The permanent player and HUD survive placeholder recreation. The standalone arena and its fixtures require no registry. Both entry paths work without a disk save. |

Preserve the existing contact timing and reset, weapon feedback and encounter selection, and pistol collision and lifecycle assertions. Apply the accepted F2 combat regression checklist to the implementation. [Contact fixture](../../tests/combat/player_contact_acceptance.gd) · [Feedback fixture](../../tests/combat/weapon_feedback_acceptance.gd) · [Pistol fixture](../../tests/combat/pistol_acceptance.gd) · [F2 regression checks](FOUNDATION_F2_SHARED_PLAYER.md#verification-for-the-implementation-pr)

### Owner runtime acceptance in Godot 4.7.2

- [ ] Start a permanent session from the normal entry without a disk save. Observe the marker and record its initial value.
- [ ] Change the value. Note the displayed result and confirm it agrees with the authoritative record.
- [ ] Unload the marker's owning placeholder. Confirm the marker is gone and inspect its retained value before recreating the scene.
- [ ] Recreate the placeholder in the same session. Confirm a fresh marker binds under the original identity and displays the changed value.
- [ ] End the session and start another. Confirm the marker starts with its original initial value.
- [ ] Check movement, aim, dodge, Dagger, one-handed Sword, Greatsword and Pistol. Check permanent HUD health and active/pending style and verify that marker controls never trigger combat or obstruct teardown.
- [ ] Launch the standalone arena directly without a permanent session, registry or save. Exercise its accepted combat, HUD, diagnostics, encounter selection, death and reset checks. Record the tested SHA, outcomes and any exceptions.
