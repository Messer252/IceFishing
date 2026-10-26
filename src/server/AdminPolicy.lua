local Policy = {}
local actions = { roster = true, money = true, xp = true, fly = true, kick = true,
    gotoPlayer = true, bring = true, freeze = true, unfreeze = true, heal = true, respawn = true,
    pond = true, shop = true }
local selfActions = { roster = true, fly = true, pond = true, shop = true }
local function integer(n) return type(n) == "number" and n == n and math.abs(n) <= 9007199254740991 and n % 1 == 0 end

function Policy.new(settings, isStudio)
    local allowed = {}
    for _, id in ipairs(settings.AdminUserIds) do if integer(id) and id > 0 then allowed[id] = true end end
    if isStudio then for _, id in ipairs(settings.StudioAdminUserIds) do if integer(id) then allowed[id] = true end end end
    return {
        allowResolved = function(id) if integer(id) and id > 0 then allowed[id] = true return true end return false end,
        isAdmin = function(id) return allowed[id] == true end,
        validate = function(request)
            if type(request) ~= "table" or not actions[request.action] then return false, "Unknown admin action." end
            if not selfActions[request.action] and not integer(request.targetId) then return false, "Select a player in this server." end
            if request.action == "money" or request.action == "xp" then
                local cap = request.action == "money" and settings.MaxMoneyGrant or settings.MaxXPGrant
                if not integer(request.amount) or request.amount < 1 or request.amount > cap then return false, "Enter a whole number between 1 and " .. cap .. "." end
            end
            return true
        end,
    }
end
return Policy
