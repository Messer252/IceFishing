local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Progression = require(ReplicatedStorage.Shared.Progression)
local Settings = require(script.Parent.ServerSettings)
local Schema = require(script.Parent.ProfileSchema).create(Config, Progression)
local PlayerStore = require(script.Parent.PlayerStore)
local Service = {}
local sandbox = RunService:IsStudio() and not Settings.StudioPersistence
if RunService:IsStudio() and Settings.StudioPersistence then
    assert(Settings.StudioStoreName ~= Settings.LiveStoreName, "Studio must use its separate test DataStore name.")
end
local storage = not sandbox and DataStoreService:GetDataStore(RunService:IsStudio() and Settings.StudioStoreName or Settings.LiveStoreName) or nil
local store = not sandbox and PlayerStore.new({
    store = storage, schema = Schema, clock = os.time, wait = task.wait, spawn = task.spawn,
    token = game.JobId .. ":" .. HttpService:GenerateGUID(false),
    autosaveSeconds = Settings.AutosaveSeconds, leaseSeconds = Settings.LeaseSeconds,
    onLost = function(id)
        local player = Players:GetPlayerByUserId(id)
        if player then player:SetAttribute("ProfileReady", false) player:Kick("Your saved session could not be kept safe. Please rejoin.") end
    end,
    onError = function(id)
        warn("[PlayerData] Save delayed for user " .. id .. "; retrying before the session lease expires.")
    end,
}) or nil

function Service.load(player)
    if sandbox then
        player:SetAttribute("DataMode", "Studio sandbox · not saved")
        return Schema.new()
    end
    player:SetAttribute("DataMode", RunService:IsStudio() and "Studio test saves" or "Saved progression")
    local profile, problem = store:load(player.UserId)
    if not profile then return nil, problem end
    return profile
end
function Service.release(player)
    if sandbox then return true end
    local ok, problem = store:release(player.UserId)
    if not ok then warn("[PlayerData] Final save failed for " .. player.UserId .. ": " .. tostring(problem)) end
    return ok
end
function Service.step() if store then store:step() end end
function Service.shutdown() if store and not store:shutdown() then warn("[PlayerData] Some profiles could not finish saving before shutdown.") end end
return Service
