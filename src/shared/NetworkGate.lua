local Gate = {}
Gate.__index = Gate
function Gate.new() return setmetatable({ users = {} }, Gate) end
function Gate:allow(id, action, now, bagSize)
    local state = self.users[id]
    if not state then state = { tokens = 16, at = now, actions = {} } self.users[id] = state end
    state.tokens = math.min(16, state.tokens + math.max(0, now - state.at) * 8)
    state.at = now
    -- Full-profile responses become more expensive as inventories grow.
    local cost = action == "input" and 0.1 or 1 + math.floor((bagSize or 0) / 20)
    local interval = action == "input" and 0.005 or (action == "ready" and 1 or 0.25)
    if state.tokens < cost or now - (state.actions[action] or -math.huge) < interval then return false end
    state.tokens = state.tokens - cost
    state.actions[action] = now
    return true
end
function Gate:remove(id) self.users[id] = nil end
return Gate
