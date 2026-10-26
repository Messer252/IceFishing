# Content, polish, and release validation

This build implements the remaining Phase 3 content and Phase 4 presentation systems and adds Phase 5 hardening/automation. **It is not certified production ready.** No Roblox Studio engine, live DataStore, actual account lookup, real device, or physics/performance test has been available in the cloud workspace.

## What changed

### Phase 3: connected progression content

- Fish bag: search, Recent/Rarity/Weight/Value sorting, individual sales, bulk unprotected sales, favorites, locks, catch inspection, timestamps, location, weight, value, and original 3D fish models. Favorites and locks block individual and bulk sales until explicitly cleared.
- Gear inventory: equip owned rods, augers, bait and lures away from the shop. The server verifies ownership and bait stock; gear changes are blocked during a cast. Equipment previews use the same models as held tools and shop stock.
- Journal: silhouettes for unknown species, discovery percentage, catch counts, best weights, variants found, bait/time/weather preferences, region hints, and one-time collection milestones.
- Eleven quests, including a four-step starter chain, distinct species, rare/trophy/variant catches, snow conditions, exploration, and a repeatable perch quest with a cooldown. Accept before making progress; rewards require an explicit server-validated claim. Claim/accept/sell replays cannot duplicate rewards.
- Tutorial: six real gameplay checkpoints, Nolan's guide, saved skip/completion state, and instructions available after completion. First Ice starts automatically for new/unfinished profiles.
- Five physical lake regions with travel boards, docks, shelters, trees, lighting, unlock levels/prices, and regional luck. Return travel is free after unlocking. Travel requests require a nearby board; the server preloads streamed terrain, temporarily holds the character, and restores movement. Casts/admin movement cannot conflict with an in-progress trip.
- Twenty-two fish, including Whisperpine Snowfin, Glass Koi, Tundra Gar, and Glacier Leviathan exclusive to their respective lakes. Auger tiers still apply. The original starter pond retains its existing general fish pool.
- Seven variant outcomes: Normal, Frosted, Albino, Midnight, Golden, Crystal, Aurora. Variant/weight/species/value are rolled by the server. Variants change the model color and sale value. Normal remains 88% of rolls; progression does not require a special variant.
- Profile schema 3 migrates schema 1/2 records, keeping coins, XP, gear, catches, discoveries and best weights. Legacy per-species counts initialize to at least one where older profiles only saved discovery/best-weight data; new catches track exact counts. The existing `FrostbitePlayers_v2` / `FrostbiteStudio_TEST_v2` store names are intentionally retained. Do not rename them to v3 or reset player data.

### Phase 4: presentation and environment

- A hook reaction window before the smooth, server-authoritative reeling minigame. Press Hook, Space, or gamepad A when the bite arrives. Missing the window cancels the encounter without a reward.
- Different continuous movement profiles for drifting panfish, sweeping bass, bursting predators, heavy fish, and mythical fish. Strength/reel speed/stability still affect the encounter. Client prediction uses the same target functions as the server.
- Original procedural fish models, a short world-space landing effect, R6/R15 fishing/landing poses, and 3D catch cards with variant/rarity/weight/value/XP/new-species/trophy details.
- A synchronized day/night and weather cycle: clear, light snow, heavy snow, blizzard, aurora night. Snowfall and aurora ribbons are client-local; environmental preferences and regional/weather luck actually change encounter weights. No weather condition prevents fishing.
- More pointed pines, docks, huts, a small outpost, NPC/task/travel signs, and illuminated shelters. Region geography is generated from source at play startup.
- Saved volume, reduced-effects and high-contrast menu settings. Phone layouts reflow cards and scroll tabs/admin tools instead of shrinking the entire desktop interface. Native button feedback and menu tweens are used.
- Eleven original synthesized WAVs and an asset-ID configuration module. **Custom audio is not uploaded or finished in-engine.** Temporary bundled UI pings are used where possible; ambient music/wind and drilling/reel loops require the supplied files to be uploaded and assigned. See [audio setup](../assets/audio/README.md).

### Phase 5: hardening and verification tools

- Combined per-player token budget and per-action intervals, including slower full-profile requests; input remains responsive at normal reel rates. Unknown command names are rejected before allocating limiter state.
- Server checks for ownership, stock, region access, level/currency caps, distances, active sessions, hook timing, quest prerequisites/reward flags/cooldowns, and settings types. A bait-stock cap prevents purchases that would exceed supported stock.
- Favorites/locks and currency-cap sales are transactional. Invalid/duplicate catch IDs leave data intact. Normal casts and arbitrary client messages cannot directly create rewards.
- Existing safe-load/session-lease/autosave/final-save handling remains in place; content/settings/collection/quest migrations are validated before a profile becomes playable.
- Workspace streaming with destination prefetch, limited local snowfall, hidden-preview animation skipping, one reusable hole per player, hole spacing/reservations, disconnect cleanup and bounded inventory counts.
- Reproducible place generation, original audio verification, locked validation dependencies, source parsing, gameplay/fault-injection/controller tests, and a GitHub Actions workflow. A local pass is not evidence the hosted workflow ran.

## Controls

| Action | Keyboard / controller / touch |
| --- | --- |
| Drill or reuse hole | F / X / Drill-Cast button |
| Create replacement hole | G / New Hole button |
| Hook and reel | Space / A / Hook-Hold button |
| Shop | B / Y / cabin prompt |
| Fish inventory | I / R1 / Bag button |
| Journal / Quests / Map / Settings / Guide | J / K / M / O / H, or field-kit tabs |
| Admin | F2 or Admin button; existing owner policy applies |

Travel boards open Map, Iris opens Quests, and Nolan opens Guide. Buy upgrades at the original cabin; use Gear to switch owned items later. The fish seller remains at the starting outpost. Fish/sell/profile state are individual to each player; weather/time are shared.

## Reproduce automated checks

From the repository root:

```sh
npm ci --prefix tools --no-audit --no-fund
node tools/check_lua.cjs
node tools/run_lua_tests.cjs
python3 -m unittest discover -s tests -p 'test_*.py' -v
python3 tools/build_place.py
```

Python's standard library builds the place; Node dependencies are only for offline validation. `python3 tools/generate_audio.py` regenerates the original WAV files deterministically. GitHub Actions runs the same source/test/build checks on pushes and pull requests, including a stale-place check.

The earlier content release passed **733 Lua checks and three Python tests**; the latest model/interface/glow update adds the coverage described in [its update guide](FISH_AND_GLOWS.md). The generated place was rebuilt from the checked source. Hosted CI has not been observed from this workspace.

The controller suite exercises the real game/admin/content/UI controllers with API fakes, including a 15-player lifecycle simulation. World geometry, rendered previews, audio playback, streaming, and actual network/physics throughput are **not** established by these tests.

## Required release gates

| Gate | Current evidence | Required before public release |
| --- | --- | --- |
| Source/build correctness | Offline parsing, logic, migration/fault, controller, PCM and XML tests | Inspect the hosted CI result after push |
| Full gameplay loop | Controller integration with API fakes | Studio Play: drill, hook, catch, protect/sell, upgrade, claim, travel, rejoin |
| World/art/animations | Source-generated original geometry and poses | Inspect every lake, R6/R15, fish previews, landing effects, signs, camera/clipping |
| Real saving | Fake DataStore errors, retries, competing/stale leases, migration | Separate private test experience: enable Studio API access and test store mode; real rejoin/shutdown/concurrent-session tests |
| Owner/admin | Server policy and command tests | Log in as unbenator, verify resolved ID, optionally pin it; second nonadmin must be denied |
| Streaming/travel | Transaction and controller tests | Stream to each lake, reset/disconnect during loading, simulate loading failure and poor connection |
| Devices/input | Phone reflow/controller branches tested with fakes | Studio emulation plus a real phone/tablet/gamepad; portrait/landscape, focus loss, chat typing, safe areas |
| Performance | Fifteen fake players have isolated sessions and cleanup | Real 10–15 player server; measure server heartbeat, memory, physics, outgoing traffic, client FPS and frame time |
| Audio | Eleven reproducible, non-silent PCM files | Upload to the experience owner/group, set AudioConfig IDs, grant usage permission, audition volumes/loops and all cues |
| Balance | Probability/bounds/achievability rules tested | Time early upgrades/region access and high-tier encounters with real play sessions |

Keep `StudioPersistence = false` for disposable sandbox tests. For save testing, follow [Phase 2's private test setup](PHASE2.md) using the dedicated test namespace. Never point Studio at live data, and do not delete profiles to clear a lease. After a crashed session, an unexpired lease can delay rejoining for up to about three minutes.

Do not downgrade production to an older build that cannot understand schema 3. Roblox's DataStore version history should be inspected in a test/recovery workflow before any rollback; no destructive reset or migration rollback tool is exposed to players or admins.

Publish privately first from Studio. Set the intended player limit in the experience's Roblox settings, verify all gates above, then choose public availability in the Creator Dashboard. This repository update does not upload assets, publish a Roblox experience, change its player limit, or certify live readiness.

## Scope boundaries

Trading, Robux products, snowmobiles, tournaments and seasonal events remain optional future features from the master brief. They are not part of the Phase 3–5 core delivery. Final artist-authored mesh/animation/audio polish can replace the generated assets without changing the gameplay services. Generated models/poses and placeholder sounds should not be advertised as finished authored assets.

## Fish and public glow update

See [the model/interface/glow guide](FISH_AND_GLOWS.md) for the new anatomical recipes, geometry overview, removed Shop hotbar button, input-specific prompts, timed shared events and their server-authoritative income/luck rules. The existing Studio/live/device acceptance gates still apply.
