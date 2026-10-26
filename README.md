# Frostbite Fishing

An original Roblox ice-fishing development build: a snowy forest surrounds a frozen pond, and a lakeside tackle cabin sells equipment and buys your catches. All scenery and UI are generated from code; no paid models or external assets are required.

## Open in Roblox Studio

1. Download/open `dist/FrostbiteFishing.rbxlx` in **Roblox Studio**. The file is generated in this workspace; rebuild it with `python3 tools/build_place.py` if needed.
2. Press **Play** (F5), rather than Run. The server generates the map, and the local player receives the interface.
3. Walk from the spawn onto the blue ice. Press **F** or tap **Drill / Cast** to drill a hole and cast. Later casts near your hole reuse it. Press **G / New Hole** to replace it, including when upgrading its size.
4. When a fish bites, **press Hook or Space** within the reaction window. Then **hold Space or the on-screen Reel button** to move your green zone right. Release to drift left. Keep the moving gold fish inside the zone until the catch meter fills. Too much line tension lets the fish escape.
5. Return to the wooden cabin. Use its proximity prompt or press **B** nearby to open the shop. Sell fish at **Mara, the fish buyer**, or through the shop. Buy or equip better gear. **I** opens your fish bag anywhere.

The Shop hotbar button has been removed; use the cabin interaction (or B nearby). Prompts follow the active input device and show keyboard controls on PC.

Use **J / Journal**, **K / Quests**, **M / Map**, **O / Settings**, **H / Guide**, or the field-kit tabs. Use **Gear** to equip items you already own. Trail boards let you unlock and travel to new lakes.

You start with 120 coins, a hand auger, a starter rod, a plain hook, and unlimited bread bait. Bait packs are optional, so running out of coins cannot prevent fishing.

## Included gameplay

- Circular frozen pond, ice veins, snow-covered trees, cabin, spawn, and surrounding ridges.
- Five augers: larger visible holes unlock successive fish tiers and better augers drill faster. Drilling has a progress indicator, ice shavings, a rotating model, and a procedural character pose.
- Five rods: luck, control, strength, reel speed, and stability affect encounters and reeling.
- Seven lures: permanent unlocks that improve fish odds.
- Free bread and six consumable bait options with species preferences and faster bites, sold in packs of ten casts.
- Species-specific fish anatomy, natural skin patterns, fins, jaws, barbels and scutes, with lazy/detail-limited previews. [Model overview and glow rules](docs/FISH_AND_GLOWS.md).
- Small timed public glow zones: 2× catch value, 2× luck, or both. Multiple players can fish inside a zone; bonuses lock when hooked and boosted values remain payable after expiry.
- Twenty-two fish species across Common, Uncommon, Rare, Epic, and Legendary tiers, with variable weights and sale prices. Five species are available with the starter auger.
- Visible rods with reels and line guides; augers with spiral flights, blades, grips, and motor housings on powered tiers. Casting, waiting, and reeling have procedural R6/R15 character poses.
- Rotating shop-card models plus an enlarged **3D View** for every rod, auger, bait, and lure. Drag to rotate; scroll to zoom. The cabin rack uses the same models.
- Mounted, framed signs with surface lettering instead of floating text.
- Locally predicted reel movement with smooth server reconciliation, rendered every frame. Space and gamepad A are captured during fishing; jumping is restored when it ends. Touch reeling uses a dedicated hold button.
- Five physical lake regions, permanent trail unlocks, regional fish, docks, shelters, travel boards, a tutorial NPC, and a quest NPC.
- Searchable/sortable inventory, individual sales, favorites and locks, a collection journal, records, eleven quests, milestone rewards, and a saved skippable tutorial.
- Seven variant outcomes with server-rolled color/value modifiers, a hook reaction window, different fish struggle profiles, 3D catches and a landing effect.
- Shared day/night/weather, local snowfall and aurora ribbons, meaningful environmental preferences, and saved accessibility/volume settings.
- Shop level requirements, auto-equipping purchases, fish inventory, selling, coin/fish/level leaderboard, catch XP, and trophy/discovery bonuses.
- Persistent coins, XP, gear, bait, fish, discoveries, and best weights in published servers; a visible level/XP HUD.
- An admin menu for `unbenator`: F2 opens coin/XP grants, self flight, teleport/bring, freeze/unfreeze, heal, respawn, and kick controls.
- Server-authoritative purchases, fish selection, bait consumption, reeling simulation, and rewards. Clients submit hold/release input, never a fish or payout. Distance checks restrict shopping and fishing; remote requests are rate-limited. Walking away or respawning cancels a cast.
- Mouse, keyboard, and touch buttons with a screen-scaled shop and fishing interface.

## Scope of this version

**Published servers save progress. Studio defaults to a sandbox that does not save.** See [Phase 2 setup and testing](docs/PHASE2.md) for safe Studio persistence testing and admin configuration. **Custom audio requires upload/configuration:** eleven original WAVs are included under `assets/audio`; safe UI-only placeholder sounds play until asset IDs are assigned. The generated models and poses are original procedural artwork, not finished artist-authored meshes or animation clips. [Release gates and current scope](docs/RELEASE.md) distinguish implementation from required Studio/live/device validation.

Fishing holes are interactable gameplay objects displayed on solid ice: players cannot fall through them. One hole per player remains available through catches, cancellations, equipment purchases, and respawns. A nearby hole is reused by **F** or its proximity prompt; **G** deliberately replaces it. Its original tier determines eligible fish, so upgrading an auger requires drilling a new, larger hole to unlock that tier. Holes are cleaned up on disconnect. Completed and in-progress holes have spacing checks.

The reel minigame is an original tracking mechanic. See [the release guide](docs/RELEASE.md) for content, controls, asset setup, changed systems, and required production checks. [Phase 2](docs/PHASE2.md) documents saving/admin setup; the current schema is 3 and intentionally retains the same store names. YouTube could not be accessed from this workspace; the latest changes follow your written feedback and Studio screenshot.

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
| `src/shared/Content.lua` | Regions, quests, variants, weather, tutorial, milestones |
| `src/shared/ContentRules.lua` | Unlocks, settings, collection and tutorial rules |
| `src/shared/Inventory.lua` | Sorting, protection flags, atomic sales |
| `src/shared/QuestRules.lua` | Objective tracking and one-time claims |
| `src/shared/NetworkGate.lua` | Per-player RPC budgets and cooldowns |
| `src/shared/FishModels.lua` | Original procedural fish models |
| `src/server/ContentService.lua` | Server content/inventory/travel actions |
| `src/server/WorldExpansion.lua` | Additional lakes, outpost and travel/NPC interactions |
| `src/server/EnvironmentService.lua` | Shared weather and clock |
| `src/client/AdventureUI.lua` | Field-kit menus and catch cards |
| `src/client/Feedback.lua` | Local snowfall, aurora and configured sound cues |
| `src/shared/Progression.lua` | XP curve, levels, and progress |
| `src/shared/FishGeneration.lua` | Encounter weight, difficulty, value, and trophies |
| `src/server/PlayerDataService.lua` | Roblox persistence integration |
| `src/server/PlayerStore.lua` | Session leases, autosave, retry, and final saves |
| `src/server/ProfileSchema.lua` | Versioned defaults, validation, and migrations |
| `src/server/ServerSettings.lua` | Server-only save/admin settings |
| `src/server/AdminService.lua` | Authorized admin actions |
| `src/server/AdminPolicy.lua` | Numeric permissions and request validation |
| `src/client/AdminMenu.lua` | Admin UI and flight controls |
| `src/shared/Reel.lua` | Pure reeling simulation shared with tests |
| `src/shared/HoleRules.lua` | Hole reuse and tier rules |
| `src/shared/Equipment.lua` | Models shared by held equipment, racks, and previews |
| `src/server/World.lua` | Generated map, NPC, signs, holes, particles, and line |
| `src/server/Game.server.lua` | Player sessions, shop, fishing, and rewards |
| `src/client/Game.client.lua` | Responsive interface and controls |
| `src/client/AnglerAnimation.lua` | Procedural character poses for all anglers |
| `src/client/EquipmentPreview.lua` | 3D preview rotation, camera, and zoom |
| `tools/build_place.py` | Deterministic Roblox XML place exporter |

The server builds the map when play begins. Change `World.lua` to make lasting map changes; edits to a running generated map are temporary.

## Validation

Cloud checks cover fish-tier restrictions, gear luck, equipment data, achievable catches for all species, escape/timeout behavior, frame-rate independence, delayed snapshot smoothing, and XML packaging/source preservation. Controller integration tests execute the actual server/client scripts with Roblox API fakes, including recasting, selling, input binding, reset/disconnect cleanup, and two independent anglers. These are not rendering, physics, performance, or Studio tests.

```sh
lua tests/gameplay.lua
lua tests/runtime.lua
lua tests/persistence.lua
lua tests/phase2.lua
lua tests/content.lua
lua tests/fish_models.lua
lua tests/glow_events.lua
# Or use the pinned Node-based offline runner:
npm ci --prefix tools --no-audit --no-fund
node tools/check_lua.cjs
node tools/run_lua_tests.cjs
```

**Roblox Studio is required for engine validation.** These checks have not been run in Studio:

- Start Play and check the Output window for errors; verify the map, spawn, trees, shop, and UI appear.
- Catch and sell starter fish; verify the coin balance, bag count, and inventory update.
- Drill once and catch repeatedly from the exact same hole. Cancel, respawn, and return to it. Verify it stays until **New Hole** replaces it or you leave the server.
- Observe auger rotation/ice shavings, rod/reel models, casting, arm poses, bobber lowering, and the visible line in both R6 and R15.
- Open each shop tab and its enlarged **3D View**. Verify rotating geometry, drag rotation, scroll zoom, and readable mounted signs.
- Verify the drilling progress indicator and use Mara's proximity prompt to sell a catch.
- Buy a rod and bait, cast, and verify one bait is consumed. Equip bread to keep fishing without paid bait.
- Buy successive augers; check larger holes appear and higher fish tiers become available.
- Hold/release on desktop and Studio's touch emulator. Verify deliberate misses lose the fish and following it can land a catch.
- During drilling, casting, waiting, and reeling, press Space: it should not jump. Cancel/land a fish, then verify normal movement and jumping return. Check gamepad A and loss of window focus.
- With Studio network emulation enabled, check continuous reel movement and immediate hold/release response under latency. Inspect Output for any client errors.
- Reset while fishing and walk away from a cast; verify the rod/session is cleaned up.
- Start a two-player local server. Check separate bags/balances, visible rods/holes, hole spacing, and independent catches.
- Try shop actions from far away and repeated clicks; verify no remote purchases or duplicate rewards occur.
- Follow the [Phase 2 persistence/admin checklist](docs/PHASE2.md): test save/rejoin and owner/nonadmin permissions. Sandbox Studio sessions intentionally reset; Studio test saves and published-server profiles should restore.

Complete every gate in [the release checklist](docs/RELEASE.md) before publishing publicly. Use **File → Publish to Roblox** from your own Roblox account when ready.
