package.path = "src/lua/?.lua;" .. package.path

package.preload["imports/career_mode/enums"] = function()
    ENUM_CM_EVENT_MSG_INITIAL_USER_ADDED = 1
    ENUM_CM_EVENT_MSG_DATA_READY = 2
    ENUM_CM_EVENT_MSG_POST_LOAD_PREPARE = 3
    ENUM_CM_EVENT_MSG_END_OF_SEASON_REACHED = 4
    return true
end
package.preload["imports/other/helpers"] = function() return true end
package.preload["imports/core/date"] = function()
    local Date = {}
    function Date:new() return setmetatable({}, { __index = Date }) end
    function Date:FromGregorianDays() end
    return Date
end
package.preload["zarg4n_stats"] = function() return {} end
package.preload["zarg4n_development"] = function() return {} end
package.preload["zarg4n_physical_growth"] = function() return {} end
package.preload["zarg4n_playstyles"] = function()
    return {
        HydrateProfile = function() end,
        ApplyEvolution = function() end,
    }
end
package.preload["zarg4n_player_writer"] = function() return {} end
package.preload["zarg4n_logger"] = function()
    return {
        Info = function() end,
        Warn = function() end,
        Error = function(_, message) error(message) end,
    }
end
package.preload["zarg4n_config"] = function()
    return { max_profile_age = 35 }
end
package.preload["zarg4n_save_guard"] = function()
    return {
        CanWrite = function() return true end,
        MarkFreshCareer = function(state) return state end,
    }
end
package.preload["zarg4n_transfer_observer"] = function()
    return {
        New = function() return {} end,
        IsObservedEvent = function() return false end,
    }
end
package.preload["zarg4n_player_profile"] = function()
    return {
        Create = function(row)
            return {
                player_id = row.playerid,
                pending_transaction = nil,
                committed_transaction = nil,
            }
        end,
        AdvanceSeason = function() end,
    }
end

local records = {
    [101] = { playerid = 1 },
    [102] = { playerid = 2 },
    [103] = { playerid = 3 },
}
local order = { 101, 102, 103 }
local cursor = 0
local first_record_calls = 0
local get_table_calls = 0
local players_table = {}

function players_table:GetFirstRecord()
    first_record_calls = first_record_calls + 1
    cursor = 1
    return order[cursor]
end

function players_table:GetNextValidRecord()
    cursor = cursor + 1
    return order[cursor] or 0
end

function players_table:GetRecordFieldValue(record, field)
    local row = records[record]
    if field == "playerid" then return row.playerid end
    if field == "preferredposition1" then return 0 end
    if field == "birthdate" then return 0 end
    if field == "overallrating" then return 70 end
    if field == "potential" then return 80 end
    return 50
end

LE = {
    db = {
        GetTable = function(_, name)
            assert(name == "players")
            get_table_calls = get_table_calls + 1
            return players_table
        end,
    },
}

GetUserSeniorTeamPlayerIDs = function()
    return { [1] = true, [2] = true, [3] = true }
end
GetCurrentDate = function() return { ToInt = function() return 20260723 end } end
CalculatePlayerAge = function() return 20 end
GetPlayerPrimaryPositionName = function() return "CM" end

local state_save_calls = 0
local runtime = {
    state = {
        save_uid = "scan-test",
        players = {},
        initialized = false,
    },
    state_store = {
        Save = function()
            state_save_calls = state_save_calls + 1
            return true
        end,
    },
    player_development_manager = {
        Load = function() end,
        Save = function() end,
    },
    development_manager_ready = false,
}

local Events = require "zarg4n_events"
Events.new(runtime):InitializePlayers()

assert(get_table_calls == 1, "player initialization must fetch the players table once")
assert(first_record_calls == 1, "player initialization must scan the players table once")
assert(runtime.state.players["1"] ~= nil)
assert(runtime.state.players["2"] ~= nil)
assert(runtime.state.players["3"] ~= nil)
assert(state_save_calls == 1, "player initialization must persist newly created profiles once")

print("PASS: player initialization scans the players table once.")
