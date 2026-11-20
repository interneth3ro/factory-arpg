# PR #16 owner runtime acceptance

Run against the draft's exact head in Godot 4.7.2. Record the SHA, physics rate, observed failures and the relevant F3 rows. All boxes start pending. Open the [combat test arena](../scenes/combat/combat_test_arena.tscn) and run that scene. Give the game window keyboard focus for F3/F5. Use the editor's game-input forwarding if necessary.

## Reproducible timing and reset checks

The [owner-run fixture](../tests/combat/player_contact_acceptance.gd) instances the arena in memory. From the repository root, run the following with the Godot 4.7.2 executable. A passing run prints `Player contact acceptance: 0 failures` and exits with code 0. Check the console for script or resource errors as well.

```powershell
godot --headless --path . --script res://tests/combat/player_contact_acceptance.gd
```

- [ ] Verify edge entry, tangent contact at a polygon vertex, and a one-pixel near miss. In the arena, cross the Heavy rim during Active and pass just behind a block. Damage should agree with its visible clipped warning. Check the moving Pursuer at a corner and after its lunge hits a wall.
- [ ] Verify the two real avoidance callbacks at full HP. The Heavy's earlier Active start resolves first even though Pursuer appears first in the scene. Both F3 records share a physics tick, have distinct offsets and leave 55 HP. Check that the later Pursuer hit preserves Heavy's strength, 0.20 s flash and 0.07 s emphasis. A fresh Pursuer hit on the next tick takes over with its own strength and durations.
- [ ] With 10 HP and Pursuer scheduled first, check that Pursuer applies only 10 HP and owns the lethal entry. The Heavy's later event is ignored and HP stays zero. In the equal-time case Heavy wins the name tie. Repeat to check determinism.
- [ ] Verify a tick that starts 90 ms into a dodge. The fixture reports contacts one microsecond before, exactly at, and one microsecond after expiry. Expect blocked, applied, applied (70 HP) even though the current-state query is already false. Then check three obstacle cases. A disk already inside the unclipped sector enters the continuously visible region after expiry and takes damage. When a moving shadow reveals the disk, a clipped miss/touch interval spanning expiry blocks damage. Move the same interval entirely past expiry and damage applies, even though the unclipped overlap began during protection.
- [ ] Verify reset between collection and drain. The fixture replays an old-generation contact and drain against a fresh batch with the same frame number. Only the new contact should survive, leaving 85 HP and one history entry. Check that reset also invalidates the old dodge interval.

## Health, presentation and controls

- [ ] Spawn with F3 closed. Check the upper-left red bar reads `100 / 100`. Move across the arena and toggle F3 twice. The bar stays fixed and legible, with no duplicate above the player.
- [ ] From full health, take an isolated Pursuer hit (85 HP), reset, then take a Heavy hit (70 HP). Check the number and fill change together. Stand through the remainder of Active. The same enemy/execution must appear only once.
- [ ] Compare the moderate 0.12 s Pursuer flash with the stronger 0.20 s Heavy flash. Check for stronger body and HUD emphasis at the beginning (0.04 s and 0.07 s). For two hits in one physics tick, check that the stronger flash and emphasis win for both equal and distinct offsets. A later tick refreshes feedback.
- [ ] Move and attack through a nonlethal hit, then dodge during an existing flash. Movement, weapon phases and dodge timing continue. When the flash ends, check the color matches the current dodge or weapon phase. Receiving a hit alone must leave offensive hitstop at zero.
- [ ] Dodge into an active sector on the first protected tick. Check for a consumed enemy contact, zero loss and no red flash. Stay within reach across expiry during that same execution and verify there is no second hit. Enter a fresh strike late in dodge and verify full damage and a flash while the dodge finishes.
- [ ] Open F3 and collect more than five contacts. Check HP, alive/dead and current i-frames. Read the latest entry at the bottom. Each row should identify the enemy, execution, physics frame, tick offset, actual decision, HP loss and resulting HP. Only the latest five remain. A lethal row remains identifiable if a later row in its batch reads `IGNORED (DEAD)`.

## Death and reset

- [ ] Let a hit kill the player during Wind-up, Active and Recovery on separate runs. Also test a buffered late click and a vulnerable late dodge. Attack geometry, direction marker, motion, hitstop and pending input stop when death resolves. Hold WASD/LMB, press Space and select weapons. The player stays down, the attack count stays fixed and no further damage is dealt.
- [ ] Check the roughly 0.35 s slump and muted final body color, centered **YOU DIED — Press F5 to Restart**, and persistent `0 / 100` HUD. Wait several seconds and toggle F3 while dead. The terminal state persists.
- [ ] Die while Heavy shows a warning and while Pursuer is lunging on separate runs. Surviving enemies immediately clear danger geometry, velocity and navigation requests, retain HP and settle visually over about 0.20 s. Wait for several attack cooldowns and verify no reacquisition. Repeat after defeating one enemy and verify its dimmed, nonblocking appearance persists.
- [ ] Press F5 during nonlethal flash, dodge, offensive hitstop, lethal strike, player collapse, enemy settling, terminal rest and arena completion. Also press F5 together with Space/LMB. On the reset tick expect original positions, player 100 HP, enemies 75/150 HP, dagger, Ready/Idle, neutral poses and hidden terminal/completion messages.
- [ ] While each transition would still be running, inspect the next frames for an old tint, pose, warning, contact, displacement or HP loss. F3 should keep its visibility preference and show empty histories, cleared hitstop, cleared dodge recovery and reset attack counts. Hold LMB across reset, then release and press again. Only the fresh press attacks. Repeat F5 rapidly and verify both enemies can engage normally afterward.

## PR #13–#15 regressions

- [ ] Check screen-relative WASD, normalized diagonals, collision and independent mouse aim. Test Space with held WASD and neutral WASD. Verify locked direction, collision-limited burst, deceleration, early i-frames and dodge recovery.
- [ ] Select dagger, sword and greatsword. Compare wind-up/active/recovery colors, mobility, reach, swept contacts and aim commitment. Check one outgoing hit per target per swing, hold-to-repeat, release, a buffered tap that succeeds and an earlier tap that expires. Dodge cancels the attack and clears its buffered repeat.
- [ ] Hit each enemy with each weapon. Check 10/25/45 base damage, distinct white flashes, and offensive hitstop of 25/40/60 ms. Enemy attack clocks and lunges pause only for the consumed offensive hitstop. Player movement and eligible dodge remain responsive.
- [ ] Aggro both archetypes. Check sight acquisition, passage around blocks using their respective clearances, avoidance, stop/resume spacing, short retreat, blocked retreat, and disengagement/reacquisition. Check standstill before Wind-up, aim commitment, Heavy warning freeze, collision-limited Pursuer lunge and recovery handoff.
- [ ] Defeat one enemy during an attack. Its warning, collision and attack stop and it dims. Defeat both before the player dies. Completion appears with F3 closed. F5 restores the fight, and both enemies can damage the player on fresh executions.

After owner acceptance, generate and review Godot's UID sidecars for the new scripts and verify the exact resulting PR head according to the [metadata policy](GODOT_METADATA.md). Record the tested head and any subsequent metadata-only change separately.
