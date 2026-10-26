# Fish appearance, PC prompts, and shared glow events

## Fish models

All 22 species now have individual visual recipes in `src/shared/FishAppearance.lua`. `FishModels.lua` builds actual 3D anatomy, skin markings, fins and mouth features from those recipes. Normal fish use their natural species palette rather than the old rarity color. Special variants tint the model without removing its markings or changing its anatomy.

Examples:

- Yellow Perch: green-gold body, dark vertical bars, orange fins and a spiny double dorsal.
- Bluegill/Pumpkinseed: deep, compressed bodies and dark opercular spots; Pumpkinseed adds an orange ear edge, orange flecks and turquoise cheek rays.
- White Bass: silver body with several horizontal stripes. Largemouth/Smallmouth Bass have different mouths, proportions and lateral/vertical markings.
- Rainbow Trout: rose lateral stripe and dark spots. Arctic Char has pale spots, a warm belly and white fin edges. Lake Trout has a deeper forked tail and pale spotting.
- Pike/Muskellunge: elongated bodies, flattened projecting snouts and rear-positioned dorsal fins; pike have pale oblong spots, muskie have dark narrow bars.
- Walleye/Golden Walleye: glassy eyes, two separated dorsal fins and a white lower tail tip.
- Flathead Catfish: broad flattened head, mottled skin, projecting jaw and eight barbels. Burbot has a longer eel-like body, long dorsal/anal fins, rounded tail and one chin barbel.
- Sturgeon: pointed snout, underslung mouth, four barbels, raised scute rows and an asymmetric tail.
- Gar: a long narrow snout, teeth and diamond-shaped ganoid-scale markings. Koi has patches, short barbels and flowing fins. Fantasy species have their own crests, armor, glowing pearls or ribbon fins.

[View the species geometry sheet](fish-models.png). This is an orthographic visualization generated from the model builder through geometry API fakes, **not a Roblox Studio screenshot**. Studio inspection remains necessary for materials, clipping, fin orientations and final appearance.

Small cards build reduced-detail models lazily when visible. Hidden previews release their geometry after two seconds. Large inspection/catch views use higher detail. Geometry tests cover all recipes, anatomy, contrasting patterns, unchanged variant shapes and a maximum of 180 parts per detailed model / 110 per small preview.

## Interface

The Shop hotbar button is removed. Drill/Cast and Bag now fill the top hotbar row. Shop access remains at the cabin prompt; the nearby B shortcut still works.

Fishing, Bag and drilling prompts adapt to the last input device. PC users see keyboard/mouse instructions; controller labels appear only while actually using a gamepad. Touch users receive button instructions. Controller support itself has not been removed.

## Random glow events

The server creates small public glow spots in lakes occupied by players:

| Event | Color | Bonus |
| --- | --- | --- |
| Golden Shoal | Gold | 2× catch value |
| Lucky Current | Blue | 2× luck |
| Aurora Bloom | Purple | Both bonuses |

The first event is checked around 20 seconds after server startup. Later opportunities are randomly spaced 80–140 seconds apart. Spots have a radius of 10–13 studs, last 85–115 seconds, and fit inside the ice. Up to three can coexist, with no player-specific claim or consumption.

The colored boundary marks the actual bonus radius. Drill your own hole inside it; multiple anglers can benefit at the same time. Existing personal-hole ownership/spacing rules still apply. Walking into a zone while fishing from a hole outside it does not grant a bonus.

Bonuses are evaluated by the server **when the fish is hooked**, using the hole's position. Fish already hooked retain their boosted value after an event expires, and that value is saved on the catch and paid when sold. There is no second multiplication during sale. Overlapping bonuses use the highest multiplier rather than becoming accidental 4× boosts.

Luck doubles baseline-plus-gear luck, so even starter equipment benefits. It changes weighted encounter odds; it does not guarantee a rare fish or bypass auger-tier/region restrictions. XP is unchanged. Gold and blue events each have a 45% selection weight; dual-bonus events have 10%.

Clients render below-ice lights, surface glow, a boundary and countdown. Slightly translucent walkable ice plus a dark water layer reveals the lights underneath. Reduced-effects mode removes bloom and reduces animated lights while leaving the zone visible. Client visuals and snapshots cannot alter authoritative bonuses.

## Tests and Studio checks

Current local validation passed **843 Lua checks, 44 parsed Lua/Luau-compatible files, and three Python tests**.

Automated suites verify species geometry, markings, part budgets, PC/controller prompt switching, the missing Shop button, zone spawning/expiry, snapshot isolation, exact 2× value, starter luck improvement, non-stacking overlaps, shared eligibility and sale after expiry. The controller suite also hooks/catches inside an actual server-generated event using API fakes.

In Studio:

1. Open the rebuilt place and inspect several real species in the Journal and 3D inspection, including perch, trout, pike, flathead and sturgeon. Compare Normal and colored variants.
2. Play with keyboard/mouse. Confirm the hotbar has no Shop button and fishing prompts show no A/X/R1 controller labels. Visit the cabin to shop normally.
3. Wait for a glow event, find its circle and countdown, and drill inside it. Hook a fish; the reel header should identify the applied VALUE x2 / LUCK x2 bonuses.
4. With two players, place separate holes inside the same circle and catch from both. Neither catch should consume the event.
5. Keep a boosted fish until after the lights expire, then sell it. Confirm its saved value is paid once. A new fish hooked after expiration should receive ordinary bonuses.
6. Inspect glow visibility on all lakes, ice walkability, reduced-effects settings, streaming and actual device performance. These engine checks have not run in the cloud workspace.
