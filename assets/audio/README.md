# Original Frostbite audio pack

These eleven mono 16-bit PCM, 22,050 Hz WAV files are synthesized by `tools/generate_audio.py` using original tone/noise recipes and no third-party samples. They are project source assets, not uploaded Roblox assets. You may use and modify them for this game.

| File | Cue |
| --- | --- |
| drill.wav | Loop while drilling |
| reel.wav | Loop during reeling |
| splash.wav | Lowering the line |
| bite.wav | Hook reaction alert |
| catch.wav | Successful catch |
| coins.wav | Selling fish |
| purchase.wav | Equipment purchase |
| level.wav | Level-up / major catch |
| discovery.wav | New-species catch |
| wind.wav | Ambient wind loop |
| music.wav | Short original winter music loop |

Download the repository ZIP to obtain all files. In Roblox's Creator Dashboard/Asset Manager, upload audio under the account/group that owns the experience, confirm moderation, and grant the experience permission to use each asset. Roblox's upload limits and permission UI may vary by account.

In Studio, open `ReplicatedStorage → Shared → AudioConfig`. Replace each empty string with its uploaded ID in the form `rbxassetid://1234567890`, matching the key to its WAV filename. Apply the same IDs in `src/shared/AudioConfig.lua` if continuing development through this repository, then rebuild the place. Never substitute guessed asset IDs.

Until configured, only temporary bundled Roblox UI pings play for supported cues. Ambient tracks and equipment loops safely stay silent. Set `useBundledPlaceholders = false` to disable those placeholder pings. Volume settings work on the associated sound groups and persist with player profiles.

Audition the uploaded sounds in Studio and on a real device. These generated cues are functional source material, not a claim of finished professional sound design. Inspect loop transitions and rebalance volumes for the final mix before public release.
