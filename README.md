# Frostbite Fishing

A playable Roblox ice-fishing prototype: a snowy forest surrounds a frozen pond, and a lakeside tackle cabin sells equipment and buys your catches. All scenery and UI are generated from code; no paid models or external assets are required.

## Open in Roblox Studio

1. Download/open `dist/FrostbiteFishing.rbxlx` in **Roblox Studio**. The file is generated in this workspace; rebuild it with `python3 tools/build_place.py` if needed.
2. Press **Play** (F5), rather than Run. The server generates the map, and the local player receives the interface.
3. Walk from the spawn onto the blue ice. Press **F** or tap **Drill & Fish** to drill a hole and cast.
4. Once a fish bites, **hold Space or the on-screen Reel button** to move your green zone right. Release to drift left. Keep the moving gold fish inside the zone until the catch meter fills. Too much line tension lets the fish escape.
5. Return to the wooden cabin. Use its proximity prompt or press **B** nearby to open the shop. Sell fish, then buy or equip better gear. **I** opens your fish bag anywhere.

You start with 120 coins, a hand auger, a starter rod, a plain hook, and unlimited bread bait. Bait packs are optional, so running out of coins cannot prevent fishing.

## Included gameplay

- Circular frozen pond, ice veins, snow-covered trees, cabin, spawn, and surrounding ridges.
- Four augers: larger visible holes unlock successive fish tiers.
- Four rods: better fish odds and a wider control zone in the reel minigame.
- Four lures: permanent unlocks that improve fish odds.
- Free bread and two consumable bait options, sold in packs of ten casts.
- Eight fish species across Common, Uncommon, Rare, and Legendary tiers, with variable weights and sale prices.
- Shop, auto-equipping purchases, fish inventory, selling, coin/fish leaderboard, and catch notifications.
- Server-authoritative purchases, fish selection, bait consumption, reeling simulation, and rewards. Clients submit hold/release input, never a fish or payout. Distance checks restrict shopping and fishing; remote requests are rate-limited. Walking away or respawning cancels a cast.
- Mouse, keyboard, and touch buttons with a screen-scaled shop and fishing interface.

## Scope of this version

**Progress is session-only.** Leaving the server resets coins, equipment, bait, and your fish bag. Persistent player data, trading, monetization, audio, and animated fish/auger models are future work. Fishing holes are visual openings on solid ice: players cannot fall through them. You can drill again after a catch; old holes expire or are replaced on the next cast.

The reel minigame is an original tracking mechanic based on your requested style. The map follows your written description; no design attachment was available in the chat.

## Develop

The existing checkout is sufficient; no Git worktree is needed.

```sh
cd /workspace/IceFishing
python3 tools/build_place.py
python3 -m unittest discover -s tests -p 'test_*.py' -v
```

Python 3 and its standard library are sufficient to build the place. No Python packages or credentials are needed. The ready-to-open `dist/FrostbiteFishing.rbxlx` is included in Git alongside its source and build script; rebuild it after changing the game scripts.

If you use [Rojo](https://rojo.space/), `default.project.json` maps the same source tree. Run `rojo serve` and connect through its Studio plugin, or use `rojo build -o dist/FrostbiteFishing.rbxlx`. Rojo is optional and was not installed or tested in the cloud workspace.

| File | Purpose |
| --- | --- |
| `src/shared/Config.lua` | Equipment, prices, species, progression, and tuning |
| `src/shared/Reel.lua` | Pure reeling simulation shared with tests |
| `src/server/World.lua` | Generated map, fishing holes, and rods |
| `src/server/Game.server.lua` | Player sessions, shop, fishing, and rewards |
| `src/client/Game.client.lua` | Responsive interface and controls |
| `tools/build_place.py` | Deterministic Roblox XML place exporter |

The server builds the map when play begins. Change `World.lua` to make lasting map changes; edits to a running generated map are temporary.

## Validation

Cloud checks cover fish-tier restrictions, gear luck (including starter-tier quality), equipment data, achievable catches for all species, escape/timeout behavior, and XML packaging/source preservation. The Lua gameplay suite runs under Lua 5.3+ or Fengari:

```sh
lua tests/gameplay.lua
# Or install this optional test runner outside the checkout:
npm install --prefix /tmp/ice-fishing-validation --cache /tmp/ice-fishing-npm-cache --no-audit --no-fund fengari-node-cli luaparse
/tmp/ice-fishing-validation/node_modules/.bin/fengari tests/gameplay.lua
```

**Roblox Studio is required for engine validation.** These checks have not been run in Studio:

- Start Play and check the Output window for errors; verify the map, spawn, trees, shop, and UI appear.
- Catch and sell starter fish; verify the coin balance, bag count, and inventory update.
- Buy a rod and bait, cast, and verify one bait is consumed. Equip bread to keep fishing without paid bait.
- Buy successive augers; check larger holes appear and higher fish tiers become available.
- Hold/release on desktop and Studio's touch emulator. Verify deliberate misses lose the fish and following it can land a catch.
- Reset while fishing and walk away from a cast; verify the rod/session is cleaned up.
- Start a two-player local server. Check separate bags/balances, visible rods/holes, hole spacing, and independent catches.
- Try shop actions from far away and repeated clicks; verify no remote purchases or duplicate rewards occur.
- Stop and restart Play to confirm the documented session reset.

Do not publish as a finished live game until the Studio checks pass. Use **File → Publish to Roblox** from your own Roblox account when ready.
