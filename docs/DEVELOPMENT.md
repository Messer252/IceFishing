# Hooked! development plan

The user's master brief defines an original, multiplayer ice-fishing simulator. Existing working systems and the Rojo/Python build workflow are retained. Build one cohesive playable loop before adding more regions or progression systems.

## Baseline inspected

The project already provided a generated snowy map, player spawn, walkable frozen pond, shop, coins, equipment unlocks, consumable bait, randomized catches, bag, selling, and server-driven fishing. Existing gaps included disposable holes, a HUD formatting error, sparse equipment visuals, floating signs, no character fishing pose, and a reel display that jumped between network snapshots. Player progress was session-only.

## Phase 1 implementation update

The current source implements the join → drill → catch → sell → upgrade loop, with the following improvements:

- Reusable, owner-bound holes. Catching, cancelling, equipping, and respawning preserve the hole. New Hole replaces it; disconnect cleans it up. A hole retains its original fish tier. In-progress drilling reserves space to prevent simultaneous overlapping holes.
- Separate drilling, casting, waiting, and reeling stages, with centralized cleanup and movement/jump restoration.
- Configured drilling times, rotating augers, ice-shaving particles, and progress feedback.
- Shared procedural equipment models: rods, reels, auger spiral flights, handles, powered housings, bait tins, and lures. Held tools, cabin displays, and previews share one factory.
- R6/R15 procedural character poses, bobber movement, a visible curved line, and lowering feedback. These are prototype animations, not final authored animation clips.
- Smooth reel presentation: fixed-step authoritative simulation, local input prediction, continuous target motion, and gradual snapshot reconciliation. The client never decides catches or rewards.
- High-priority Space/gamepad A handling and client/server jump suppression during a cast, with restored controls after completion/cancellation/reset.
- Enlarged, drag-rotatable equipment previews and scroll zoom, plus framed surface signs.
- Five starter-pond species, eleven species total, basic bag/catch notifications, Mara the fish-buying NPC, shop upgrades, and starter currency.
- A fix for multiple return values from `gsub` breaking the equipment HUD.

**Phase 1 is not marked complete.** Automated tests exercise logic and controller integration, but the gameplay acceptance gate requires an actual Roblox Studio playtest. No Studio engine, rendering, asset, latency-emulation, or performance test has been run in this cloud workspace.

### Files changed

New modules: `src/shared/Equipment.lua`, `src/shared/HoleRules.lua`, `src/client/AnglerAnimation.lua`, and `src/client/EquipmentPreview.lua`.

Updated controllers/configuration: `src/server/Game.server.lua`, `src/server/World.lua`, `src/shared/Config.lua`, `src/shared/Reel.lua`, and `src/client/Game.client.lua`.

Validation/build/documentation: `tests/gameplay.lua`, `tests/runtime.lua`, `tests/test_build.py`, `tools/run_lua_tests.cjs`, `README.md`, this plan, and rebuilt `dist/Hooked.rbxlx`.

### Studio acceptance gate

Open the built place and press Play. Confirm Output has no errors. Join, drill once, catch multiple times from the same hole, sell to Mara, purchase/equip the first upgrade, and fish again. Check arm poses and held equipment in R6/R15. Test mouse, touch, Space, and gamepad A; confirm Space does not jump during fishing and works again afterward. Use network emulation to check reel presentation. Run a two-player server to verify independent inventories/rewards, hole spacing, simultaneous casting, reset/disconnect cleanup, and duplicate sell attempts. The README contains the detailed checklist.

The NPC and generated equipment are original primitive-based prototype models. Audio, final rigged fish, polished authored animation clips, and full art direction remain unfinished content. Do not advertise these as completed assets.

## Phase 2 implementation

The user explicitly authorized proceeding to Phase 2. See [Phase 2 progression, persistence, and admin tools](PHASE2.md) for implemented systems, changed files, safe Studio data testing, owner setup, and remaining acceptance checks. The first-phase engine checks above remain pending; proceeding does not assert they passed.

## Remaining validation and phases

1. **Close Phase 1:** correct any errors or usability issues found by the Studio acceptance playtest, then tune catch timing and the first upgrade against real play sessions.
2. **Phase 2 — progression (implemented; engine/service acceptance pending):** validate versioned player profiles with safe load failure behavior, UpdateAsync session ownership, autosave, shutdown saving, migrations, and a separate Studio test namespace. Add XP/levels, full species definitions, richer equipment statistics, and balanced unlocks. Do not save every individual catch directly to DataStore.
3. **Phase 3 — content:** unique catch IDs, variants, locked/favorited inventory and individual selling, bestiary/records, quests, trophies, and additional regions. Keep generation, currency, ownership, and rewards authoritative on the server.
4. **Phase 4 — polish:** final equipment/fish assets and animation clips, licensed/original audio, tutorial guidance, weather/day-night effects, environmental detail, UI transitions, accessibility, and full device/controller testing.
5. **Phase 5 — production validation:** failure/reconnect tests for persistence, remote abuse/replay tests, multi-client performance tests targeting 10–15 players, profiling on low-end devices, progression balancing, and deployment checks.

Keep additional lakes behind the starter-loop acceptance gate. Preserve working systems; extract services when their responsibilities grow rather than replacing the project with a monolithic script. User-facing controls must perform real actions. Missing assets and untested capabilities must remain clearly labeled.

## Remaining-phase implementation

The user authorized all remaining phases. The current build adds the content, environment, inventory, journal, quests, regions, variants, tutorial, procedural fish/landing visuals, settings, audio source pack, responsive menus, network hardening, CI workflow and migration tests described in [the release guide](RELEASE.md). Schema 3 preserves existing Phase 2 data and store names.

Phase 5 remains **pending external acceptance**, not certified complete: Studio rendering/physics, real DataStore/owner checks, asset upload, real device and 10–15-player performance tests cannot be performed in this cloud machine. Follow the release matrix for the concrete remaining steps. Optional later features (trading, vehicles, seasonal events, Robux products) were not treated as required phase deliverables.
