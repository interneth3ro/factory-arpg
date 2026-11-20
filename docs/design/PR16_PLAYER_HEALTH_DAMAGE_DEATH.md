# Factory ARPG --- PR #16 Approved Design Specification

**Milestone:** Player Health, Enemy Damage, and Death\
**Status:** APPROVED --- Decisions M57--M74\
**Approved:** 2026-11-20\
**Repository:** `interneth3ro/factory-arpg`\
**Engine:** Godot 4.7.2\
**Implementation target:** PR #16, one focused feature PR\
**Authority:** Owner-approved design decisions from the Factory ARPG
ChatGPT design pass. This document is authoritative for PR #16 even if
the repository decision log has not yet been synchronized.

## 1. Purpose and scope

Implement player survivability in the existing two-enemy combat arena
without changing the frozen combat prototype A1--A16 or regressing PRs
#13--#15. Scope includes player health, enemy damage, contact-time dodge
protection, deterministic chronological resolution, feedback, HUD,
death, enemy terminal behavior, F5 reset, diagnostics, and focused
acceptance validation.

**Not in scope:** healing, armor, resistances, status effects, player
knockback/stun, general post-hit invulnerability, defensive hitstop,
respawn systems, death penalties, new combat managers, generalized event
buses, persistent saves, or unrelated refactors. All numerical tuning
below is provisional/configurable unless explicitly stated otherwise.

## 2. Approved decision register

### M57 --- Balanced health and enemy damage (Option B)

-   Player maximum health: **100 HP**.
-   Pursuer attack damage: **15 HP**.
-   Heavy attack damage: **30 HP**.
-   These values are provisional and configurable.

### M58 --- Vulnerability at actual contact time (Option B)

-   Determine dodge invulnerability **at the actual geometric contact
    instant**, not from the player's state at the end of a physics tick.
-   Contacts inside the early dodge invulnerability window deal **zero**
    damage; vulnerable contacts deal full damage.
-   An invulnerable contact still consumes the attack's single contact
    opportunity.
-   No general post-hit invulnerability.
-   Different enemy attacks are evaluated independently.
-   Existing dodge timing is unchanged.

### M59 --- Independent simultaneous hits (Option B)

-   Every distinct enemy attack can apply its own damage if the player
    is vulnerable at its contact time.
-   A Pursuer and Heavy landing eligible contacts can jointly deal **45
    HP**.
-   No per-tick damage cap or arbitrary immunity.
-   Health clamps at zero; terminal death transitions only once.

### M60 --- Archetype-weighted damage feedback (Option B)

-   Pursuer: moderate red body flash for **0.12 s**.
-   Heavy: stronger red body flash for **0.20 s**.
-   Update HP immediately.
-   Nonlethal damage causes no knockback, stun, or movement/attack/dodge
    interruption.
-   New hits refresh feedback; simultaneous hits display the strongest
    effect rather than stacking.
-   Lethal damage uses the separate death presentation.

### M61 --- Fixed player health HUD (Option B)

-   Always-visible red horizontal health bar in the **upper-left**
    screen corner.
-   Show numeric `current / maximum` HP, e.g. `75 / 100`.
-   Update immediately and briefly flash on damage.
-   Remain visible at `0 / 100` during death.
-   F5 restores `100 / 100`.
-   Independent of F3; no overhead duplicate.

### M62 --- Brief death transition and terminal state (Option B)

-   On reaching zero HP, immediately disable player movement, attacks,
    dodge, and input buffers; cancel any active player attack.
-   Show procedural collapse/slump and fade to muted color over
    approximately **0.35 s**.
-   Centered terminal message: **`YOU DIED — Press F5 to Restart`**.
-   HUD remains visible at zero.
-   Surviving enemies stop pursuit and attacks, and clear active contact
    geometry and movement requests.
-   F5 works immediately, including during transition.
-   No auto-respawn, death penalty, or extra menu.

### M63 --- Enemy behavior after player death (Option B)

-   Surviving enemies immediately cancel combat and navigation.
-   Active hit regions and Heavy ground warning disappear immediately.
-   Visually settle to neutral resting stance over approximately **0.20
    s**; remain stationary and cannot reacquire the dead player.
-   Preserve surviving enemy health; already-defeated enemies retain
    defeated appearance.
-   F5 restores original positions, health, and behavior.
-   Settling is visual only, never a delay on reset.

### M64 --- Layered player visual priorities (Option B)

-   Priority: **death \> damage flash \> dodge presentation \> normal
    movement/attack presentation**.
-   Protected dodge contacts cause no damage flash.
-   Vulnerable contacts during dodge flash immediately without canceling
    dodge.
-   A flash can continue through a later dodge but cannot affect
    invulnerability timing.
-   New damage refreshes the flash; simultaneous hits choose strongest
    feedback.
-   Death overrides all effects; F5 clears transient effects.
-   Preserve existing attack-phase colors via coordinated presentation
    ownership.

### M65 --- Dedicated player health component (Option B)

-   Introduce a small dedicated player health component owning
    current/max HP, damage validation, and terminal death state.
-   Enemy attack system reports geometric contacts rather than directly
    modifying HP.
-   Existing movement FSM remains authoritative for dodge timing.
-   Player coordinator disables gameplay actions on death.
-   HUD/presentation consume health and feedback notifications.
-   Do not refactor enemy health or add a general damage manager.
-   Final node paths, signals, and signatures are determined after
    repository inspection.

### M66 --- Immediate atomic F5 reset (Option B)

-   F5 has priority over gameplay input and works at any point, even in
    the same tick as lethal damage or during death/enemy-resting
    animations.
-   Cancel transitions and clear health, damage, movement, attack,
    dodge, contact, and input-buffer transient state.
-   Restore player 100/100 HP, spawn position, default weapon, and
    starting action/movement state.
-   Restore enemies' positions, HP, navigation, attack phases,
    histories, telegraphs, and encounter completion.
-   Preserve F3 visibility.
-   Held LMB must require a fresh press.
-   Repeated F5 is safe/deterministic; stale animation callbacks cannot
    alter a restored encounter.
-   Extend the existing reset coordinator rather than create another
    restart system.

### M67 --- Chronological lethal-contact resolution (Option B)

-   Resolve eligible contacts by their actual within-tick contact times.
-   Check dodge protection at each time, apply damage in order, clamp HP
    at zero, and trigger death once.
-   Ignore contacts occurring after the lethal contact.
-   Equal timestamps use a deterministic stable tie-breaker (such as
    enemy identifier).
-   Record attack execution/damage data accurately in F3.
-   Do not introduce an unnecessarily broad event framework.

### M68 --- Visual-only defensive impact emphasis (Option B)

-   Additional visual emphasis: Pursuer **0.04 s**, Heavy **0.07 s**,
    alongside M60 flashes.
-   Briefly strengthen player damage color and HUD bar flash; **no
    gameplay pause**.
-   Do not interrupt movement, attack, dodge, invulnerability, enemy
    attacks, or cooldowns.
-   Simultaneous hits use the strongest emphasis without stacking
    durations.
-   Existing offensive hitstop remains unchanged.

### M69 --- Detailed F3 damage diagnostics (Option B)

-   Extend existing F3 section with current/max HP, alive/dead state,
    current dodge i-frame status.
-   Report last enemy contact, execution ID, within-tick timestamp,
    vulnerability decision, actual damage, and resulting HP.
-   Outcomes include `APPLIED`, `BLOCKED (DODGE)`, and `IGNORED (DEAD)`.
-   Maintain a bounded history of the **five most recent contact
    resolutions**.
-   Show chronological ordering of same-tick contacts and identify
    lethal contact.
-   F5 clears transient history; HUD remains independent of F3.
-   Diagnostics must display the resolver's actual decisions, not
    independently recompute them.

### M70 --- Physics-tick-scoped contact collection (Option B)

-   Gather contacts for the current physics tick, then sort and resolve
    chronologically.
-   Preserve timestamp, enemy identity, execution ID, and encounter
    generation.
-   Resolve only **after all relevant enemy attack callbacks for the
    tick complete**.
-   Validate dodge timing at each contact, stop applying damage on
    death, and discard/mark later contacts.
-   F5 clears pending contacts; no stale contacts carry into later
    ticks.
-   Collection orders events only; the player health component remains
    damage/death authority.
-   **Do not assume a particular Godot node or navigation avoidance
    callback always runs last.** Verify the actual processing lifecycle.

### M71 --- Earliest verified contact timestamp (Option B)

-   Enemy detector reports earliest verified geometric contact within
    its swept collision interval, relative to tick start.
-   Use that time for sorting and dodge protection.
-   Preserve one contact per target per attack execution.
-   Keep existing PR #15 sector geometry, obstacle clipping, and
    movement authority.
-   A bounded, documented approximation is permitted where exact
    continuous collision time is impractical; protect conservatively at
    genuinely ambiguous i-frame boundaries.
-   Address the known moving Pursuer shadow-edge limitation only as a
    narrowly scoped opportunity, not a full collision rewrite.

### M72 --- Read-only dodge invulnerability intervals (Option B)

-   Existing player movement FSM exposes the actual interval(s) of
    invulnerability in each physics tick.
-   Include within-tick dodge initiation and expiration; maintain
    existing **0.24 s dodge**, **first 40% / 0.096 s** protected window.
-   Do not extend/shorten i-frames or duplicate timers in player health.
-   Preserve `is_invulnerable()` for current-state checks.
-   Clear transient interval history on death/F5.
-   Final interface can be a small read-only method or tick-scoped
    structure.

### M73 --- Encounter generation identity (Option B)

-   Maintain a lightweight encounter generation counter in the existing
    encounter coordinator.
-   Associate contact events with their originating generation.
-   Increment generation when F5 begins reset; immediately clear pending
    contacts.
-   Reject old-generation contacts and late callbacks.
-   After terminal death, reject later contacts.
-   Enemy attack execution IDs remain independent.
-   No persistent session/event infrastructure.

### M74 --- Fully validated survivability milestone (Option B)

-   Implement **all M57--M73 behavior in one focused PR #16**, not a
    basic subset or a deferred timing PR.
-   Prepare comprehensive owner runtime acceptance covering new features
    and regressions against PRs #13--#15.
-   Independent review, owner Godot acceptance, pre-merge verification,
    manual merge, separate cleanup remain required.

## 3. Integration facts from read-only inspection

At the planning inspection, live `main` was
`3d3390c2d5512dbbad3b50536d22dd452baec3d5`. **Codex must reverify live
main before editing.**

-   `scenes/combat/enemy_attack.gd`:
    `contact_registered(target, execution_id)` currently lacks contact
    time; `check_contact()` uses swept trace segments.
-   `scenes/combat/enemy_movement.gd`: enemy attacks advance through
    navigation avoidance callback `_move_with_safe_velocity`; its
    `_strike` path records traces and checks contact.
-   `scenes/combat/slide_trace.gd`: supports tick-relative time/position
    records and interpolation.
-   `scenes/combat/player_movement_fsm.gd`: owns dodge elapsed time and
    `is_invulnerable()`, but no historical per-tick interval API.
-   `scenes/combat/combat_test_player.gd`: coordinates F3, F5, player
    actions and traces.
-   `scenes/combat/enemy_health.gd`: owns enemy damage/defeat; preserve
    this separation.

These are planning observations, not permission to assume implementation
details remain unchanged.

## 4. Required acceptance matrix

  --------------------------------------------------------------------------------------
  Area                                Owner acceptance
  ----------------------------------- --------------------------------------------------
  Health                              Spawn 100/100; Pursuer −15; Heavy −30; independent
                                      combined hits; HP clamps at zero

  Dodge                               Protected contact no damage/flash; vulnerable
                                      contact full damage; within-tick boundary accuracy

  Ordering                            Chronological same-tick resolution; deterministic
                                      ties; exactly one lethal transition; no post-death
                                      damage

  HUD                                 Fixed upper-left bar and numeric HP; immediate
                                      updates; zero visible on death; F3-independent

  Feedback                            Distinct archetype flashes/emphasis; no defensive
                                      pause or input interruption; visual priority
                                      preserved

  Death                               Immediate terminal gameplay; \~0.35 s collapse;
                                      exact message; attacks and movement canceled

  Enemies                             Immediate attack/navigation stop; warning cleared;
                                      \~0.20 s rest; defeated enemies unchanged

  Reset                               F5 at any phase; full player/enemy restore; no
                                      stale callbacks; repeat-safe; F3 preference
                                      retained

  Diagnostics                         Five-event history;
                                      timestamp/execution/vulnerability/outcome/lethal
                                      source; F5 clears

  Regression                          WASD, aim, all weapons, buffers, offensive
                                      hitstop, dodge, enemy pursuit/retreat, attack
                                      telegraphs, enemy defeat and arena completion
  --------------------------------------------------------------------------------------

## 5. Implementation and governance constraints

-   Preserve frozen A1--A16 and all existing approved combat behavior.
-   Work from clean, synchronized `main`, traditional feature branch in
    primary checkout, one Draft PR; no worktrees or automatic merge.
-   No Godot editor launch, import, scene execution, headless engine
    test, or performance probe without explicit owner permission.
-   Static/nonexecuting checks permitted; use repository metadata
    validator.
-   Follow `AGENTS.md`, `docs/README.md`, `docs/GODOT_METADATA.md`, and
    documentation-sync skill.
-   Add this specification to the PR branch under
    `docs/design/PR16_PLAYER_HEALTH_DAMAGE_DEATH.md`, register M57--M74
    in `docs/design/DECISION_LOG.md`, and link the specification from
    `docs/README.md`. Preserve frozen baseline unchanged.
-   If architecture cannot satisfy an approved rule without a meaningful
    deviation, stop and request owner approval rather than silently
    changing the design.
