local Config = dofile("src/shared/Config.lua")
local Progression = dofile("src/shared/Progression.lua")
local Schema = dofile("src/server/ProfileSchema.lua").create(Config, Progression)
local PlayerStore = dofile("src/server/PlayerStore.lua")
local checks = 0
local function check(value, message) assert(value, message) checks = checks + 1 end
local clone = Schema.clone
local function fixture()
    local state = { now = 100, records = {}, failures = 0, calls = 0, lost = {}, errors = {} }
    local api = {}
    function api:UpdateAsync(key, fn)
        if state.yieldFirst then state.yieldFirst = false coroutine.yield("waiting") end
        state.calls = state.calls + 1
        if state.failures > 0 then state.failures = state.failures - 1 error("Injected DataStore outage") end
        local result = fn(clone(state.records[key]))
        if state.retryTransform then result = fn(clone(state.records[key])) end
        if result ~= nil then state.records[key] = clone(result) end
        if state.failAfterCommit then state.failAfterCommit = false error("Injected lost write acknowledgement") end
        return clone(result)
    end
    function state.client(token)
        return PlayerStore.new({ store = api, schema = Schema, clock = function() return state.now end,
            wait = function(dt) state.now = state.now + dt end, spawn = function(fn) fn() end,
            token = token, leaseSeconds = 180, autosaveSeconds = 60,
            onLost = function(id) state.lost[id] = true end, onError = function(id) state.errors[id] = true end })
    end
    return state
end
local f = fixture()
local a, b = f.client("A"), f.client("B")
local p = a:load(1)
check(p and p.coins == 120 and p.xp == 0, "First-time profile initializes only after acquiring a lease")
check(not b:load(1), "Concurrent servers cannot both load the same player")
check(not a:load(1), "A server cannot load an already-open profile twice")
p.coins = 543
p.xp = 180
check(f.records.player_1.data.coins == 120, "In-memory progress does not mutate persistent data without a save")
check(a:save(1, false), "Periodic save succeeds for its owner")
check(f.records.player_1.data.coins == 543 and f.records.player_1.lease.token == "A", "Autosave commits a snapshot and renews ownership")
p.coins = 600
check(a:release(1), "Leave save releases the profile")
check(not f.records.player_1.lease and not a.entries[1], "Release removes the lease and local entry")
local loaded = b:load(1)
check(loaded.coins == 600 and loaded.level == Progression.describe(180).level, "Rejoin restores the latest saved coins and XP-derived level")
check(loaded.owned.rod.twig and loaded.equipped.bait == "bread", "Equipment survives a round trip")

local g = fixture()
g.failures = 3
local c = g.client("C")
check(not c:load(2) and not c.entries[2] and not g.records.player_2, "Failed loads never create or save a fallback profile")
check(g.calls == 3, "Storage errors receive bounded retries")
g.failures = 2
check(c:load(2) ~= nil, "Transient failures recover on a subsequent successful attempt")
local old = clone(g.records.player_2)
g.failures = 3
c.entries[2].data.coins = 999
check(not c:save(2, false) and g.records.player_2.data.coins == old.data.coins, "A failed save preserves the previous stored snapshot")
check(g.errors[2] and not g.lost[2], "Temporary outages are retried without immediately discarding session ownership")
g.now = c.entries[2].leaseUntil - 4
c:step()
check(g.lost[2], "The session is stopped before an unrenewed lease expires")

local h = fixture()
local first, second = h.client("first"), h.client("second")
local firstData = first:load(3)
firstData.coins = 900
h.now = h.now + 181
local nextData = second:load(3)
nextData.coins = 222
second:save(3, false)
check(not first:save(3, false) and h.lost[3], "A stale server cannot save over a new session")
check(h.records.player_3.data.coins == 222, "A stale save cannot duplicate or overwrite another session's money")

local j = fixture()
j.records.player_4 = { version = 99, data = { coins = 700 } }
check(not j.client("J"):load(4) and j.records.player_4.version == 99, "Future schemas are refused without overwriting them")
j.records.player_5 = { version = 1, data = { coins = 321, bag = {}, owned = { rod = { carbon = true } }, equipped = { rod = "carbon" } } }
local migrated = j.client("M"):load(5)
check(migrated and migrated.schemaVersion == 3 and migrated.coins == 321 and migrated.owned.rod.carbon, "Legacy profiles migrate without losing valid equipment or currency")
local bad = Schema.new()
bad.coins = 0 / 0
j.records.player_6 = { version = 2, data = bad }
check(not j.client("N"):load(6), "Corrupt numeric values cannot become live profiles")
bad = Schema.new()
bad.statistics.catches = "broken"
j.records.player_7 = { version = 2, data = bad }
check(not j.client("N"):load(7), "Malformed saved statistics cannot break the catch controller")
bad = Schema.new()
bad.bag = { { catchId = "same", name = "Perch", rarity = "Common", value = 25, kg = 1, color = { 1, 2, 3 } },
    { catchId = "same", name = "Perch", rarity = "Common", value = 25, kg = 1, color = { 1, 2, 3 } } }
j.records.player_8 = { version = 2, data = bad }
check(not j.client("N"):load(8), "Duplicate catch IDs are rejected on load")
j.records.player_13 = false
check(not j.client("N"):load(13) and j.records.player_13 == false, "Malformed non-table data is never mistaken for a new account")

local k = fixture()
k.retryTransform = true
local saver = k.client("stable")
saver:load(9)
saver.entries[9].data.coins = 789
local before = k.calls
saver:step()
check(k.calls == before, "Autosave does not write on every frame or catch")
k.now = k.now + 80
saver:step()
check(k.records.player_9.data.coins == 789, "Scheduled autosaves persist active progress")
saver:load(10)
check(saver:shutdown(), "Shutdown flushes all open profiles")
check(not k.records.player_9.lease and not k.records.player_10.lease, "Shutdown releases every session")
check(not saver:load(11), "A closing server refuses new loads")

local r = fixture()
local leaving = r.client("leaving")
leaving:load(12).coins = 456
r.failures = 3
check(not leaving:release(12), "A temporary leave-save outage is reported")
check(leaving.entries[12].releasePending, "A failed leave save stays queued for retry")
r.now = r.now + 11
leaving:step()
check(not leaving.entries[12] and r.records.player_12.data.coins == 456 and not r.records.player_12.lease, "A recovered leave-save retry commits the final balance and releases the lease")

local overlap = fixture()
local owner = overlap.client("one-server")
overlap.yieldFirst = true
local load = coroutine.create(function() return owner:load(20) end)
local resumed, paused = coroutine.resume(load)
check(resumed and paused == "waiting" and owner.loading[20], "In-flight loads reserve the account before yielding")
check(not owner:load(20), "Rapid same-server rejoins cannot start a competing load for one user ID")
local finished, data = coroutine.resume(load)
check(finished and data.coins == 120 and not owner.loading[20], "The original load completes and clears its reservation")

local original = owner.entries[20]
original.busy = true
local replacement
owner.options.wait = function(dt)
    overlap.now = overlap.now + dt
    original.busy = false
    -- Another release has completed, then the same account rejoined.
    overlap.records.player_20.lease = nil
    owner.entries[20] = nil
    replacement = assert(owner:load(20))
    replacement.coins = 777
end
check(owner:release(20), "A superseded release finishes without touching its replacement")
check(owner.entries[20] and owner.entries[20].data == replacement and owner.entries[20].data.coins == 777,
    "An older cleanup cannot release a newly loaded profile")

local queued = fixture()
local queueOwner = queued.client("queued")
local tasks = {}
queueOwner.options.spawn = function(fn) table.insert(tasks, fn) end
queueOwner:load(21)
queued.now = queued.now + 80
queueOwner:step()
check(#tasks == 1, "Autosave work captures the exact profile it was scheduled for")
queueOwner:release(21)
local currentData = assert(queueOwner:load(21))
currentData.coins = 888
local calls = queued.calls
tasks[1]()
check(queued.calls == calls and queueOwner.entries[21].data == currentData,
    "A stale queued autosave cannot write a replacement session")

local acknowledged = fixture()
local retryOwner = acknowledged.client("acknowledgement")
retryOwner:load(22).coins = 555
acknowledged.failAfterCommit = true
check(retryOwner:release(22), "A release that committed before a response timeout is safely recognized on retry")
check(acknowledged.records.player_22.data.coins == 555 and not acknowledged.records.player_22.lease and not retryOwner.entries[22],
    "Write receipts prevent a lost acknowledgement from corrupting or duplicating the final save")

local recovery = fixture()
local recovering = recovery.client("recovering")
recovering:load(23).coins = 606
recovery.now = recovering.entries[23].leaseUntil - 4
recovering:step()
check(recovery.lost[23] and recovering:release(23) and recovery.records.player_23.data.coins == 606,
    "A departing session can finish a verified final save before its lease expires")
local expired = recovery.client("expired")
expired:load(24)
recovery.now = recovery.now + 181
expired:step()
check(not expired:release(24) and not expired.entries[24], "An expired profile cannot write but its retired local entry does not block a later rejoin")
check(expired:load(24) ~= nil, "A fresh session can reacquire the safely expired account")
local shutdownFailure = fixture()
local losing = shutdownFailure.client("lost-final")
losing:load(25)
shutdownFailure.now = shutdownFailure.now + 181
losing:step()
check(not losing:shutdown(), "Shutdown does not report success for an unconfirmed expired final save")
print("PASS: " .. checks .. " persistence fault-injection checks (fake DataStore)")
