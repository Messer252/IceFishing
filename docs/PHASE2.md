# Phase 2: progression, saving, and administration

This documents the Phase 2 baseline. The newer build uses schema 3 in the same existing store namespaces and implements the content described in [the release guide](RELEASE.md).

The user authorized Phase 2 after the Phase 1 code update. This implementation preserves the existing map, drilling/casting/reeling loop, reusable holes, and 3D equipment workflow. Roblox Studio acceptance testing from Phase 1 remains outstanding; advancing the implementation does not establish that gate passed.

## Implemented systems

- Eighteen configurable species, including all fifteen species from the master brief and the three existing original/existing extras. Five starter species remain available immediately. Epic fish use the new Titanium Auger tier; the Arctic Auger reaches Legendary fish.
- Five rods, five augers, seven lures, and seven bait options including free bread. Existing IDs remain valid for profile migrations. Previously owned equipment stays equipable even if a later balancing change adds a level requirement.
- Rod luck/control plus strength, reel speed, and stability. Strength changes heavy-fish encounter difficulty; reel speed increases actual catch gain; stability reduces actual tension gain. Bait preferences and lure preferences change species weights, and paid bait speeds up bites. These are gameplay effects, not display-only stats.
- Server-generated encounter weights within species bounds, weight-dependent difficulty/value, XP, trophy rolls, and first-discovery bonuses. Catch IDs, species, timestamps, location, normal variant, and lock/favorite defaults are persisted for future inventory extensions. Variant generation, bestiary UI, and inventory sorting/locking controls belong to Phase 3.
- Lifetime XP and a configurable level curve up to level 100, shop level requirements, visible equipment statistics, XP progress, and catch/level-up feedback.
- Versioned player profiles containing coins, XP, equipped/owned gear, consumable bait, fish bag, discoveries, best weights, statistics, and reserved tables for settings/quests/regions.
- Server-side administration for the Roblox user ID resolved for `unbenator`, plus optional pinned numeric admin IDs. Coin/XP grants, self flight, teleport to pond/shop/player, bring, freeze/unfreeze, heal, respawn, and kick operate on players in the current server.

## Save behavior

`PlayerDataService.lua` integrates Roblox DataStoreService with the independently testable `PlayerStore.lua` and `ProfileSchema.lua` modules.

Published servers use `FrostbitePlayers_v2`. Studio defaults to an explicitly labeled, unsaved sandbox. If Studio persistence is enabled, it uses `FrostbiteStudio_TEST_v2`; a runtime assertion prevents selecting the live store name from Studio.

Loads acquire an ownership lease using UpdateAsync before the gameplay profile becomes available. A lease is tied to the server's JobId plus a unique token. Another active server cannot load the same player. Failed/corrupt/unsupported profile loads kick with an explanation; they do not start and save a fresh default profile. Version 1 records migrate to version 2 while retaining valid coins, gear, and catches. An absent profile is the only case that creates defaults.

Progress changes in memory. Autosaves are staggered roughly every 60 seconds, retry transient API errors, and renew a 180-second lease. Leave/shutdown saves commit the final snapshot and release ownership. A failed leave save stays queued while this server remains alive. Shutdown uses a bounded flush window. Unrenewed/foreign ownership stops the session before unsafe further play; stale servers cannot overwrite a new owner's data.

No system can guarantee unsaved progress during an indefinite Roblox outage or forced process termination. The current implementation is fault-tested against a fake DataStore, not yet verified against Roblox's live service or production load. Do not describe it as production validated.

## Test persistence safely in Studio

1. Open the updated place in Studio and publish it to a separate private **test experience**.
2. In **ServerScriptService → Server → ServerSettings**, set `StudioPersistence = true`. Keep `StudioStoreName = "FrostbiteStudio_TEST_v2"` and leave the live name different.
3. In the test experience's settings, enable **Studio Access to API Services** under Security. Roblox may move the setting between Studio/experience settings; it must be enabled for Studio DataStore testing. HTTP requests are not required by these modules.
4. Press Play. The HUD should say **Studio test saves**. Catch/sell fish, earn XP, buy bait/gear, and retain a fish in the bag.
5. Stop Play, wait for shutdown to finish, and start again. Verify coins, XP, equipment, bait, and the retained catch are restored.
6. Test two players, a normal disconnect, and a rapid reconnect. A competing session should wait/refuse access rather than duplicate the profile. After a crashed server, an unexpired old lease can delay rejoining for up to about three minutes.
7. Return `StudioPersistence` to false for disposable local playtests. The HUD should say **Studio sandbox · not saved**. This changes Studio only; published servers still use saving.

## Admin menu

**F2** or the **ADMIN** button opens the menu. Select a player, enter an amount or optional kick reason, and choose an action. Kick and respawn require a second click within six seconds. The list supports players in this server only; kick is not a permanent ban.

- **Give coins / Give XP:** positive whole-number additions. Default per-request limits: 1,000,000 coins or 100,000 XP. Grants modify the authoritative profile and are included in its next save. No offline editing or arbitrary currency setting is exposed.
- **Fly:** toggles flight for the admin using the menu. WASD moves relative to the camera; Space/gamepad A moves up, Ctrl/gamepad B moves down, and touch has Up/Down buttons. Mobile/gamepad horizontal motion uses the normal movement controls. Opening the admin panel stops directional flight input while you use it. Flight is cancelled on character reset/disconnect; stopping it removes constraints, clears momentum, and restores the humanoid. Fishing cannot start while flying/frozen.
- **Go to player / Bring / To pond / To shop:** cancels an affected fishing session before teleporting.
- **Freeze / Unfreeze / Heal / Respawn / Kick:** act on the selected, online character/player. Freeze/respawn cancel fishing first. Other admins are protected from kick/freeze/respawn, and self-kick is refused.

The server calls `Players:GetUserIdFromNameAsync("unbenator")`; it never grants permission by display name, a client-supplied username, or an `IsAdmin` attribute. If lookup fails after retries, no username-based privileges are granted. This cloud machine cannot reach the Roblox user API, so the actual account lookup remains a Studio/published-server check.

For access that survives account renames, read the resolved numeric ID from the server Output message and put it in `ServerSettings.AdminUserIds`. Example shape: `AdminUserIds = { YOUR_NUMERIC_USER_ID }` with your real numeric ID, not that placeholder. Keep this module in ServerScriptService. No credential or token is needed.

Studio multiplayer tests may name local users `Player1` with negative user IDs rather than your real Roblox account. For that test only, set `StudioAdminUserIds = { -1 }` (or the actual test player's ID shown in Studio). This list is consulted only when RunService:IsStudio() is true, and cannot authorize a live player. Defaults grant no extra Studio admins.

Every command independently verifies the server's numeric permission list, target membership, data readiness where applicable, amount bounds, and cooldown. Client UI visibility is cosmetic. Commands are logged in server Output with actor/action/target/amount. There is no remote arbitrary code execution, permanent ban, global shutdown, or permission-granting command.

## Files

New server modules: `ServerSettings.lua`, `ProfileSchema.lua`, `PlayerStore.lua`, `PlayerDataService.lua`, `AdminPolicy.lua`, `AdminService.lua`.

New shared modules: `Progression.lua`, `FishGeneration.lua`. New client module: `AdminMenu.lua`.

Updated: the existing server/client controllers, shared equipment/configuration, packaging tests, Lua test runner, README/development notes, and generated place. New suites: `tests/persistence.lua` and `tests/phase2.lua`; controller tests also execute the real admin service and menu with API fakes.

## Acceptance checks still required

- Studio: Phase 1 gameplay loop, R6/R15 models/poses, responsive UI, reel latency behavior, and mouse/touch/gamepad input.
- Studio test DataStore: normal leave/rejoin, autosave, shutdown, competing sessions, a failed API-services permission, and independent players.
- Real `unbenator` login: owner lookup resolves the expected ID; F2 opens the admin menu; a second nonadmin sees no button and cannot invoke privileged remotes.
- Two-player admin test: grants persist after rejoin; kick only removes the chosen player; freeze cancels fishing; teleports don't duplicate rewards; fly/stop/reset restore controls and remove constraints.
- Performance and balance: XP/coin pacing, all rod stats, maximum-weight encounters, inventory limits, and a 10–15 player server. Cloud tests establish logic behavior, not these engine/performance outcomes.

Phase 2 is implemented but not marked production-ready or fully accepted until these checks pass. The next priority is this Studio/published-server verification, then Phase 3 collections, quests, variants, and additional areas.
