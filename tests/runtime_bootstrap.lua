package.path = "src/lua/?.lua;" .. package.path

package.preload["imports/career_mode/helpers"] = function() return true end
package.preload["imports/other/helpers"] = function() return true end
package.preload["imports/core/live_editor"] = function() return true end
package.preload["zarg4n_config"] = function()
    return { author = "zarg4n", target_title_update = "TU1.6.4" }
end
package.preload["zarg4n_logger"] = function()
    return { Info = function() end, Warn = function() end, Error = function() end }
end

local loaded_uids = {}
package.preload["zarg4n_state_store"] = function()
    local Store = {}
    function Store.new() return setmetatable({}, { __index = Store }) end
    function Store:Load(uid)
        table.insert(loaded_uids, uid)
        return { save_uid = uid, players = {} }, nil
    end
    function Store:Save() return true, nil end
    return Store
end
package.preload["zarg4n_events"] = function()
    local Events = {}
    function Events.new(runtime)
        return {
            InitializePlayers = function() end,
            OnCareerEvent = function()
                assert(runtime.state.save_uid == GetSaveUID(), "event must use the active save state")
            end,
        }
    end
    return Events
end

local handlers = 0
local active_uid = "save-a"
function IsInCM() return true end
function GetSaveUID() return active_uid end
function AddEventHandler(_, callback)
    handlers = handlers + 1
    _G.registered_handler = callback
end
function Log() end
LE = {
    player_development_manager = {
        Load = function() end,
    },
}

dofile("src/lua/zarg4n_career_overhaul.lua")
dofile("src/lua/zarg4n_career_overhaul.lua")

assert(handlers == 1, "entrypoint must register one career event handler")
assert(#loaded_uids == 1 and loaded_uids[1] == "save-a", "bootstrap must load the active save")
active_uid = "save-b"
registered_handler(nil, 29, {})
assert(#loaded_uids == 2 and loaded_uids[2] == "save-b", "save switch must reload isolated state")
print("PASS: runtime bootstrap loads once and switches career state safely.")
