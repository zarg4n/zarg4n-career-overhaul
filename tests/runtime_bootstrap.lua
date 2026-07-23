package.path = "src/lua/?.lua;" .. package.path

package.preload["imports/career_mode/helpers"] = function() return true end
package.preload["imports/other/helpers"] = function() return true end
package.preload["imports/core/live_editor"] = function() return true end
package.preload["zarg4n_config"] = function()
    return { author = "zarg4n", version = "0.2.0", target_title_update = "TU1.6.4" }
end
local logged_errors = {}
package.preload["zarg4n_logger"] = function()
    return {
        Info = function() end,
        Warn = function() end,
        Error = function(_, message) logged_errors[#logged_errors + 1] = message end,
    }
end

local loaded_uids = {}
local saved_states = 0
local dispatched_events = 0
package.preload["zarg4n_state_store"] = function()
    local Store = {}
    function Store.new() return setmetatable({}, { __index = Store }) end
    function Store:Load(uid)
        table.insert(loaded_uids, uid)
        return { save_uid = uid, players = {} }, nil
    end
    function Store:Save()
        saved_states = saved_states + 1
        return true, nil
    end
    return Store
end
local allow_writes = false
package.preload["zarg4n_save_guard"] = function()
    return {
        CanWrite = function()
            return allow_writes, allow_writes and nil or "new-career marker required"
        end,
    }
end
package.preload["zarg4n_migrations"] = function()
    return {
        IsValidSaveUid = function(uid)
            return type(uid) == "string" and uid:match("^[A-Za-z0-9_-]+$") ~= nil
        end,
    }
end
local injected_event_error = false
package.preload["zarg4n_events"] = function()
    local Events = {}
    function Events.new(runtime)
        return {
            InitializePlayers = function() end,
            OnCareerEvent = function()
                if injected_event_error then error("injected callback failure") end
                dispatched_events = dispatched_events + 1
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
allow_writes = true
registered_handler(nil, 999, {})
assert(saved_states == 0, "unrelated career events must not write unchanged state")
allow_writes = false
active_uid = "save-b"
registered_handler(nil, 29, {})
assert(#loaded_uids == 2 and loaded_uids[2] == "save-b", "save switch must reload isolated state")
assert(dispatched_events == 2, "valid switched save event must dispatch")

active_uid = ""
registered_handler(nil, 29, {})
assert(dispatched_events == 2, "blank UID must fail closed without reusing prior runtime")
assert(#loaded_uids == 2, "blank UID must not load or reuse a state")
assert(#logged_errors >= 1, "blank UID must be logged safely")

active_uid = "../invalid"
registered_handler(nil, 29, {})
assert(dispatched_events == 2, "invalid UID must fail closed before dispatch")
assert(#loaded_uids == 2, "invalid UID must not reach state store")

active_uid = "save-b"
injected_event_error = true
local callback_ok = pcall(registered_handler, nil, 29, {})
assert(callback_ok, "top-level callback must contain runtime failures")
assert(#logged_errors >= 2, "contained callback failure must be logged")
assert(saved_states == 0, "unmarked careers must not create or update runtime state files")
print("PASS: runtime bootstrap loads once and switches career state safely.")
