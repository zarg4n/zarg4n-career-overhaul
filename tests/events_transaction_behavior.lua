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
    return { Aggregate = function() return { appearances = 20 } end }
end
package.preload["zarg4n_development"] = function()
    return {
        Calculate = function()
            return {
                performance_score = 0.5,
                projected_potential = 81,
                development_multiplier = 1.05,
            }
        end,
        Apply = function() return true end,
    }
end
package.preload["zarg4n_physical_growth"] = function()
    return {
        Calculate = function()
            return { strength_growth = 1, jumping_growth = 1 }
        end,
    }
end
package.preload["zarg4n_playstyles"] = function()
    return {
        HydrateProfile = function() end,
        BuildCandidates = function()
            return { "POWER_SHOT" }, {
                archetype_phase = "prime",
                role_archetype = "efficient_forward",
                candidate_affinities = { finishing = 9 },
                archetype_history = { "efficient_forward" },
            }
        end,
        ResolveAward = function()
            return { regular = "POWER_SHOT", id = 2, level = "regular" }
        end,
        ApplyEvolution = function(profile, evolution)
            profile.archetype_phase = evolution.archetype_phase
            profile.role_archetype = evolution.role_archetype
            profile.candidate_affinities = evolution.candidate_affinities
            profile.archetype_history = evolution.archetype_history
        end,
    }
end

local player_fields
local apply_count = 0
package.preload["zarg4n_player_writer"] = function()
    return {
        Apply = function(_, _, _, profile, development)
            apply_count = apply_count + 1
            player_fields.potential = development.projected_potential
            table.insert(profile.regular_playstyles, "POWER_SHOT")
        end,
        Matches = function(_, _, _, _, development)
            return player_fields.potential == development.projected_potential
        end,
    }
end
package.preload["zarg4n_logger"] = function()
    return { Info = function() end, Warn = function() end, Error = function() end }
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
        Observe = function() return nil end,
    }
end
package.preload["zarg4n_config"] = function()
    return { max_profile_age = 35 }
end
package.preload["zarg4n_player_profile"] = function()
    return {
        Create = function() error("existing profile expected") end,
        Validate = function() return true end,
        AdvanceSeason = function(profile)
            profile.seasons_observed = profile.seasons_observed + 1
            profile.identity_revealed = true
        end,
    }
end

local function new_player_fields()
    return {
        playerid = 101,
        preferredposition1 = 25,
        birthdate = 1,
        overallrating = 75,
        potential = 80,
        strength = 70,
        jumping = 68,
        shotpower = 76,
        longshots = 74,
        stamina = 72,
        acceleration = 78,
        sprintspeed = 80,
        interceptions = 30,
        finishing = 82,
        positioning = 80,
        reactions = 78,
        ballcontrol = 79,
        dribbling = 77,
        vision = 70,
        shortpassing = 72,
        longpassing = 65,
        standingtackle = 25,
        defensiveawareness = 28,
        height = 180,
        weight = 75,
        trait1 = 0,
        icontrait1 = 0,
    }
end

local players_table = {}
function players_table:GetFirstRecord() return 1 end
function players_table:GetNextValidRecord() return 0 end
function players_table:GetRecordFieldValue(_, field) return player_fields[field] end

LE = { db = { GetTable = function() return players_table end } }
GetCurrentDate = function() return { ToInt = function() return 20260723 end } end
GetUserSeniorTeamPlayerIDs = function() return { [101] = true } end
GetPlayerPrimaryPositionName = function() return "ST" end
CalculatePlayerAge = function() return 24 end
GetPlayerStats = function() return {} end

local function new_profile()
    return {
        last_development = { score = 1 },
        playstyle_candidates = { "BRUISER" },
        last_playstyle_award = { regular = "BRUISER" },
        last_stats = { appearances = 10 },
        physical_projection = { strength_total = 2 },
        last_processed_date = 20250723,
        archetype_phase = "emerging",
        role_archetype = "explosive_winger",
        candidate_affinities = { finishing = 3 },
        archetype_history = { "explosive_winger" },
        strength_growth_total = 2,
        jumping_growth_total = 3,
        regular_playstyles = {},
        plus_playstyles = {},
        pending_transaction = nil,
        committed_transaction = nil,
        seasons_observed = 1,
        identity_revealed = false,
    }
end

local function new_runtime(profile, save_result)
    return {
        state = {
            save_uid = "transaction-test",
            players = { ["101"] = profile },
            last_processed_date = 0,
        },
        state_store = { Save = save_result },
        player_development_manager = { Save = function() end },
    }
end

local Events = require "zarg4n_events"

player_fields = new_player_fields()
local prepare_profile = new_profile()
local prepare_runtime = new_runtime(prepare_profile, function()
    return false, "injected prepare failure"
end)
Events.new(prepare_runtime):ProcessSeasonEnd()
assert(player_fields.potential == 80, "failed WAL prepare must prevent DB mutation")
assert(apply_count == 0, "failed WAL prepare must not call player writer")
assert(prepare_profile.pending_transaction == nil, "failed prepare must clear in-memory pending transaction")

player_fields = new_player_fields()
local profile = new_profile()
local save_calls = 0
local fail_commit = true
local runtime = new_runtime(profile, function()
    save_calls = save_calls + 1
    if fail_commit and save_calls == 2 then
        return false, "injected commit failure"
    end
    return true
end)
local events = Events.new(runtime)
events:ProcessSeasonEnd()

assert(player_fields.potential == 81, "DB target may remain after durable WAL and commit failure")
assert(apply_count == 1, "first attempt applies DB target once")
assert(profile.pending_transaction ~= nil, "commit failure must retain durable pending transaction")
assert(profile.last_processed_date == 20250723, "commit failure must not advance profile checkpoint")
assert(#profile.regular_playstyles == 0, "writer profile side effect must be restored in memory")
assert(runtime.state.last_processed_date == 0, "commit failure must not advance season checkpoint")

fail_commit = false
events:ProcessSeasonEnd()
assert(apply_count == 1, "retry must detect matching DB target and avoid a duplicate write")
assert(profile.pending_transaction == nil, "successful retry must clear pending transaction")
assert(profile.last_processed_date == 20260723, "successful retry must commit player checkpoint")
assert(profile.last_development.projected_potential == 81, "retry must commit prepared result")
assert(runtime.state.last_processed_date == 20260723, "successful retry must commit season checkpoint")

print("PASS: durable player transaction WAL is fail-closed and idempotent.")
