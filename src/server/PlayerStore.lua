-- Storage orchestration is independent of Roblox for fault-injection tests.
local PlayerStore = {}
PlayerStore.__index = PlayerStore

function PlayerStore.new(options)
    return setmetatable({ options = options, entries = {}, closing = false }, PlayerStore)
end

function PlayerStore:_update(id, transform)
    local lastError
    for attempt = 1, 3 do
        local ok, result = pcall(function() return self.options.store:UpdateAsync("player_" .. id, transform) end)
        if ok then return true, result end
        lastError = tostring(result)
        if attempt < 3 then self.options.wait(attempt) end
    end
    return false, lastError
end

function PlayerStore:load(id)
    if self.closing or self.entries[id] then return nil, "Profile is already active or server is closing." end
    local o, reason = self.options, nil
    local ok, record = self:_update(id, function(old)
        reason = nil
        if old ~= nil and (type(old) ~= "table" or (old.version ~= 1 and old.version ~= o.schema.version)) then
            reason = "Unsupported saved profile. No data was overwritten." return nil
        end
        local lease = old and old.lease
        if lease and (type(lease) ~= "table" or type(lease.expires) ~= "number" or lease.expires ~= lease.expires
            or math.abs(lease.expires) == math.huge or type(lease.token) ~= "string") then
            reason = "Invalid saved session. No data was overwritten." return nil
        end
        if lease and lease.token ~= o.token and lease.expires > o.clock() then
            reason = "Your previous session is still saving. Please rejoin shortly." return nil
        end
        local data, problem
        if old then data, problem = o.schema.migrate(old.data) else data = o.schema.new() end
        if not data then reason = "Saved profile could not be loaded: " .. tostring(problem) return nil end
        return { version = o.schema.version, data = data, lease = { token = o.token, expires = o.clock() + o.leaseSeconds } }
    end)
    if not ok then return nil, "Saving service is unavailable. Please rejoin later." end
    if not record or not record.lease or record.lease.token ~= o.token then return nil, reason or "Profile is busy. Please rejoin." end
    if self.closing then
        self.entries[id] = { data = record.data, leaseUntil = record.lease.expires, nextSave = 0 }
        self:release(id)
        return nil, "Server is closing. Please rejoin."
    end
    self.entries[id] = { data = record.data, leaseUntil = record.lease.expires,
        nextSave = o.clock() + o.autosaveSeconds + id % 11 }
    return record.data
end

function PlayerStore:save(id, release)
    local entry, o = self.entries[id], self.options
    if not entry or entry.lost then return false, "Profile is not owned." end
    if entry.busy then return false, "busy" end
    entry.busy = true
    local snapshot = o.schema.clone(entry.data)
    local ok, result = self:_update(id, function(old)
        if not old or not old.lease or old.lease.token ~= o.token or old.lease.expires <= o.clock() then return nil end
        if old.version ~= o.schema.version then return nil end
        return { version = o.schema.version, data = snapshot,
            lease = not release and { token = o.token, expires = o.clock() + o.leaseSeconds } or nil }
    end)
    entry.busy = false
    if ok and result and (release and not result.lease or not release and result.lease and result.lease.token == o.token) then
        if release then self.entries[id] = nil else
            entry.leaseUntil, entry.nextSave = result.lease.expires, o.clock() + o.autosaveSeconds
            entry.lost = false
            if entry.releasePending then entry.nextSave = o.clock() end
        end
        return true
    end
    if ok then
        entry.lost = true
        if o.onLost then o.onLost(id) end
    else
        entry.nextSave = o.clock() + 10
        if o.onError then o.onError(id) end
    end
    return false, ok and "Session ownership was lost." or "Saving service is unavailable."
end

function PlayerStore:release(id)
    local entry = self.entries[id]
    if not entry then return true end
    entry.releasing = true
    local deadline = self.options.clock() + 20
    while entry.busy and self.options.clock() < deadline do self.options.wait(0.1) end
    if entry.busy then
        entry.releasing, entry.releasePending = false, true
        return false, "Save did not finish before shutdown."
    end
    local ok, problem = self:save(id, true)
    if not ok and not entry.lost then
        entry.releasing, entry.releasePending = false, true
        entry.nextSave = self.options.clock() + 10
    end
    return ok, problem
end

function PlayerStore:step()
    local o = self.options
    for id, entry in pairs(self.entries) do
        if not entry.lost and o.clock() >= entry.leaseUntil - 5 then
            entry.lost = true
            if o.onLost then o.onLost(id) end
        elseif not entry.busy and not entry.lost and not entry.releasing and o.clock() >= entry.nextSave then
            -- Reserve before spawning so consecutive heartbeats cannot queue saves.
            entry.nextSave = o.clock() + o.autosaveSeconds
            o.spawn(function()
                if entry.releasePending then self:release(id) else self:save(id, false) end
            end)
        end
    end
end

function PlayerStore:shutdown()
    self.closing = true
    for id in pairs(self.entries) do self.options.spawn(function() self:release(id) end) end
    local deadline = self.options.clock() + 25
    while next(self.entries) and self.options.clock() < deadline do self:step() self.options.wait(0.1) end
    return next(self.entries) == nil
end

return PlayerStore
