local Content = require(game:GetService("ReplicatedStorage").Shared.Content)
local Lighting = game:GetService("Lighting")
local Service = {}
function Service.start()
    local origin, accumulator = workspace:GetServerTimeNow(), 1
    local current = Content.environment(0)
    local api = {}
    function api.state() return current end
    function api.step(dt)
        accumulator = accumulator + dt
        if accumulator < 1 then return end
        accumulator = 0
        current = Content.environment(workspace:GetServerTimeNow() - origin)
        Lighting.ClockTime = current.hour
        Lighting.Brightness = current.night and 1.1 or 2
        Lighting.FogEnd = Content.weather(current.weather).fog
        workspace:SetAttribute("Weather", current.weather)
        workspace:SetAttribute("WorldHour", current.hour)
        workspace:SetAttribute("EnvironmentOrigin", origin)
    end
    api.step(1)
    return api
end
return Service
