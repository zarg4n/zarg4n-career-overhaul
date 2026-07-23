package.path = "src/lua/?.lua;" .. package.path

package.preload["imports/career_mode/enums"] = function()
    ENUM_CM_EVENT_MSG_INITIAL_USER_ADDED = 1
    ENUM_CM_EVENT_MSG_POST_LOAD_PREPARE = 2
    ENUM_CM_EVENT_MSG_END_OF_SEASON_REACHED = 3
    return true
end
package.preload["imports/other/helpers"] = function() return true end
package.preload["imports/core/date"] = function()
    local Date = {}
    function Date:new() return setmetatable({}, { __index = Date }) end
    function Date:FromGregorianDays() end
    return Date
end
package.preload["zarg4n_stats"] = function()
    return { Aggregate = function() error("denied save must not aggregate stats") end }
end
package.preload["zarg4n_development"] = function()
    return {
        Calculate = function() error("denied save must not calculate development") end,
        Apply = function() error("denied save must not write development") end,
    }
end
package.preload["zarg4n_physical_growth"] = function()
    return { Calculate = function() error("denied save must not calculate physical growth") end }
end
package.preload["zarg4n_playstyles"] = function()
    return {
        HydrateProfile = function() end,
        BuildCandidates = function() error("denied save must not build candidates") end,
        ResolveAward = function() error("denied save must not award playstyles") end,
        ApplyEvolution = function() end,
    }
end
package.preload["zarg4n_player_writer"] = function()
    return {
        Apply = function() error("denied save must not write player data") end,
        Matches = function() return true end,
    }
end
package.preload["zarg4n_config"] = function()
    return { max_profile_age = 35, version = "0.2.0" }
end
package.preload["zarg4n_player_profile"] = function()
    return {
        Create = function(row, save_uid)
            return {
                player_id = row.playerid,
                baseline_potential = row.potential,
                development_profile = 50,
                personality = require("zarg4n_personality").Create(row.playerid, save_uid),
            }
        end,
        Validate = function() return true end,
        AdvanceSeason = function() end,
    }
end

local messages = {}
package.preload["zarg4n_logger"] = function()
    return {
        Info = function(_, message) messages[#messages + 1] = message end,
        Warn = function() end,
        Error = function(_, message) error(message) end,
    }
end

local db_reads = 0
LE = {
    db = {
        GetTable = function()
            db_reads = db_reads + 1
            return {}
        end,
    },
}
local date_calls = 0
GetCurrentDate = function()
    date_calls = date_calls + 1
    return { ToInt = function() return 20260723 end }
end
GetUserSeniorTeamPlayerIDs = function() return {} end
GetPlayerStats = function() return {} end

local Migrations = require "zarg4n_migrations"
local SaveGuard = require "zarg4n_save_guard"
local state = assert(Migrations.NewState("new-career-test"))
local save_calls = 0
local runtime = {
    state = state,
    state_store = {
        Save = function()
            save_calls = save_calls + 1
            return true
        end,
    },
    player_development_manager = { Save = function() end },
}

local Events = require "zarg4n_events"
local events = Events.new(runtime)
events:ProcessSeasonEnd()
assert(db_reads == 0, "denied save must hard no-op before database access")
assert(SaveGuard.CanWrite(state) == false, "unknown save must stay read-only")

events:OnCareerEvent(nil, ENUM_CM_EVENT_MSG_POST_LOAD_PREPARE, {})
assert(SaveGuard.CanWrite(state) == false, "loading an existing save must not enable writes")

events:OnCareerEvent(nil, ENUM_CM_EVENT_MSG_INITIAL_USER_ADDED, {})
assert(SaveGuard.CanWrite(state) == true, "initial-user event must mark the new career eligible")
assert(state.eligibility.source == "career_event", "eligibility source must be explicit")
assert(state.eligibility.marker == "initial_user_added", "eligibility marker must be stable")
assert(save_calls >= 1, "eligibility must be checkpointed")

local date_calls_before_unrelated = date_calls
events:OnCareerEvent(nil, 999, {})
assert(date_calls == date_calls_before_unrelated, "unrelated events must not read career date")

local forbidden_payload = setmetatable({}, {
    __index = function() error("event payload was dereferenced") end,
})
events:OnCareerEvent(nil, 94, forbidden_payload)
assert(#messages == 1, "documented transfer event must emit one structured log")
assert(messages[1]:match("event_id=94"), "structured log must include event id")
assert(messages[1]:match("kind=bid_rejected"), "structured log must include event kind")

local personality_a = require("zarg4n_personality").Create(101, "new-career-test")
local personality_b = require("zarg4n_personality").Create(101, "new-career-test")
assert(personality_a.ambition == personality_b.ambition, "personality must be deterministic")

print("PASS: v0.2.0 integration keeps existing saves read-only and enables only new careers.")
