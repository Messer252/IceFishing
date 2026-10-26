local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local Content = require(ReplicatedStorage.Shared.Content)
local Audio = require(ReplicatedStorage.Shared.AudioConfig)
local Feedback = {}
function Feedback.start(remotes)
    local settings, loops = { musicVolume = 0.35, sfxVolume = 0.65, reducedEffects = false }, {}
    local sfxGroup, musicGroup = Instance.new("SoundGroup"), Instance.new("SoundGroup")
    sfxGroup.Name, musicGroup.Name = "FrostbiteSFX", "FrostbiteMusic"
    sfxGroup.Parent, musicGroup.Parent = SoundService, SoundService
    local function sound(key, loop)
        local id = Audio[key]
        local placeholder = not id or #id == 0
        if placeholder then
            if loop or not Audio.useBundledPlaceholders or key == "splash" then return nil end
            id = "rbxasset://sounds/electronicpingshort.wav"
        end
        local item = Instance.new("Sound")
        item.Name, item.SoundId, item.Looped = "Frostbite_" .. key, id, loop or false
        item.SoundGroup = (key == "music" or key == "wind") and musicGroup or sfxGroup
        item.Volume = key == "wind" and 0.3 or 0.45
        item.PlaybackSpeed = placeholder and (key == "level" and 1.3 or key == "coins" and 1.7 or 1) or 1
        item.Parent = SoundService
        item:Play()
        if not loop then Debris:AddItem(item, 10) end
        return item
    end
    local function stopLoop(key) if loops[key] then loops[key]:Destroy() loops[key] = nil end end
    loops.wind, loops.music = sound("wind", true), sound("music", true)
    local snow = Instance.new("Part")
    snow.Name, snow.Size, snow.Transparency, snow.Anchored = "LocalSnowfall", Vector3.new(65, 0.2, 65), 1, true
    snow.CanCollide, snow.CanQuery, snow.CanTouch, snow.CastShadow, snow.Parent = false, false, false, false, workspace
    local emitter = Instance.new("ParticleEmitter")
    emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    emitter.Lifetime, emitter.Speed, emitter.EmissionDirection = NumberRange.new(4, 6), NumberRange.new(5, 10), Enum.NormalId.Bottom
    emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.11), NumberSequenceKeypoint.new(1, 0.06) })
    emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(0.9, 0.3), NumberSequenceKeypoint.new(1, 1) })
    emitter.Acceleration, emitter.SpreadAngle, emitter.Parent = Vector3.new(-1.5, -1, 0.6), Vector2.new(12, 12), snow
    local aurora = {}
    for i = 1, 3 do
        local holder = Instance.new("Part")
        holder.Name, holder.Size, holder.Transparency, holder.Anchored = "LocalAurora", Vector3.new(1, 1, 1), 1, true
        holder.CanCollide, holder.CanQuery, holder.CanTouch, holder.CastShadow, holder.Parent = false, false, false, false, workspace
        local a, b = Instance.new("Attachment"), Instance.new("Attachment")
        a.Position, b.Position, a.Parent, b.Parent = Vector3.new(-120, 0, 0), Vector3.new(120, 0, 0), holder, holder
        local beam = Instance.new("Beam")
        beam.Attachment0, beam.Attachment1, beam.Width0, beam.Width1 = a, b, 10 + i * 4, 13 + i * 4
        beam.Segments, beam.FaceCamera, beam.LightEmission = 32, true, 0.8
        beam.Color = ColorSequence.new(Color3.fromRGB(90, 235, 195), Color3.fromRGB(171, 126, 245))
        beam.Transparency, beam.CurveSize0, beam.CurveSize1, beam.Parent = NumberSequence.new(0.65), 30 * i, -25 * i, holder
        table.insert(aurora, { part = holder, beam = beam })
    end
    local accumulator = 0
    RunService.RenderStepped:Connect(function(dt)
        accumulator = accumulator + dt
        local camera = workspace.CurrentCamera
        if not camera then return end
        snow.Position = camera.CFrame.Position + Vector3.new(0, 25, 0)
        if accumulator > 0.2 then
            accumulator = 0
            local weather = Content.weather(workspace:GetAttribute("Weather"))
            emitter.Rate = settings.reducedEffects and math.min(8, weather.snow) or weather.snow
            sfxGroup.Volume, musicGroup.Volume = settings.sfxVolume, settings.musicVolume
            for i, ribbon in ipairs(aurora) do
                ribbon.beam.Enabled = weather.id == "Aurora" and not settings.reducedEffects
                ribbon.part.CFrame = CFrame.new(camera.CFrame.Position + Vector3.new(0, 85 + i * 8, -100 - i * 10)) * CFrame.Angles(0, 0.1 * math.sin(workspace:GetServerTimeNow() * 0.1 + i), 0)
            end
        end
    end)
    remotes.Event.OnClientEvent:Connect(function(kind, data)
        if kind == "profile" then settings = data.settings
        elseif kind == "stage" then
            stopLoop("drill") stopLoop("reel")
            if data.stage == "drilling" then loops.drill = sound("drill", true) elseif data.stage == "waiting" then sound("splash") end
        elseif kind == "hook" then sound("bite")
        elseif kind == "bite" then loops.reel = sound("reel", true)
        elseif kind == "caught" then
            stopLoop("reel") sound(data.discovery and "discovery" or "catch")
            if data.rarity == "Legendary" or data.rarity == "Epic" then sound("level") end
        elseif kind == "ended" then stopLoop("drill") stopLoop("reel")
        elseif kind == "feedback" then sound(data) end
    end)
    Players.LocalPlayer.CharacterRemoving:Connect(function() stopLoop("drill") stopLoop("reel") end)
    if Audio.music == "" then warn("[Audio] Original WAVs are in assets/audio. Assign uploaded asset IDs in Shared.AudioConfig; bundled UI pings are temporary placeholders.") end
end
return Feedback
