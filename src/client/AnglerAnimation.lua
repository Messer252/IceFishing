-- Procedural R6/R15 poses need no uploaded animation IDs or asset permissions.
-- Character attributes replicate the activity; each client animates all anglers.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Animation = {}

function Animation.start()
    local rigs = {}
    return RunService.RenderStepped:Connect(function(dt)
        local seen = {}
        for _, player in ipairs(Players:GetPlayers()) do
            local character = player.Character
            if character then
                seen[character] = true
                local stage = character:GetAttribute("FishingStage")
                local resultAt = character:GetAttribute("FishingResultAt") or -100
                if not stage and character:GetAttribute("FishingResult") == "caught" and workspace:GetServerTimeNow() - resultAt < 0.8 then stage = "landing" end
                local rig = rigs[character]
                if stage and not rig then
                    rig = { motors = {}, blend = 0 }
                    for _, m in ipairs(character:GetDescendants()) do
                        if m:IsA("Motor6D") and (m.Name == "RightShoulder" or m.Name == "LeftShoulder"
                            or m.Name == "Right Shoulder" or m.Name == "Left Shoulder" or m.Name == "Waist"
                            or m.Name == "Neck" or m.Name == "LeftWrist") then
                            table.insert(rig.motors, { motor = m, base = m.C0 })
                        end
                    end
                    rigs[character] = rig
                end
                if rig then
                    local alpha = 1 - math.exp(-14 * math.min(dt, 0.1))
                    rig.blend = rig.blend + ((stage and 1 or 0) - rig.blend) * alpha
                    local t = workspace:GetServerTimeNow() - (stage == "landing" and resultAt or character:GetAttribute("FishingStageAt") or 0)
                    local drilling, reeling = stage == "drilling", stage == "reeling"
                    local cycle = math.sin(t * (drilling and 10 or reeling and 9 or 2))
                    local lift = stage == "landing" and (65 + math.sin(t / 0.8 * math.pi) * 35) or (stage == "hooking" and 85) or drilling and 78 or (stage == "casting" and (62 + math.sin(math.min(t / 0.8, 1) * math.pi) * 30) or 58)
                    for _, entry in ipairs(rig.motors) do
                        local m, pose = entry.motor, CFrame.new()
                        if m.Parent then
                            if m.Name == "RightShoulder" then pose = CFrame.Angles(math.rad(lift + cycle * 3), math.rad(-10), math.rad(12))
                            elseif m.Name == "LeftShoulder" then pose = CFrame.Angles(math.rad(lift - 6 + cycle * (reeling and 9 or 3)), math.rad(20), math.rad(-25))
                            elseif m.Name == "Right Shoulder" then pose = CFrame.Angles(0, math.rad(-10), math.rad(lift + cycle * 3))
                            elseif m.Name == "Left Shoulder" then pose = CFrame.Angles(0, math.rad(15), math.rad(-lift + 10 - cycle * 6))
                            elseif m.Name == "LeftWrist" then pose = CFrame.Angles(reeling and math.sin(t * 10) * 0.3 or 0, 0, 0)
                            elseif m.Name == "Waist" then pose = CFrame.Angles(math.rad(8 + cycle), 0, 0)
                            elseif m.Name == "Neck" then pose = CFrame.Angles(math.rad(-9), 0, 0) end
                            m.C0 = entry.base * CFrame.new():Lerp(pose, rig.blend)
                        end
                    end
                    if not stage and rig.blend < 0.001 then
                        for _, entry in ipairs(rig.motors) do if entry.motor.Parent then entry.motor.C0 = entry.base end end
                        rigs[character] = nil
                    end
                end
            end
        end
        for character in pairs(rigs) do if not seen[character] then rigs[character] = nil end end
    end)
end
return Animation
