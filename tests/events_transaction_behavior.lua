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
            return { performance_score = 0.5, potential = 80 }
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
        ResolveAward = function() return { regular = "POWER_SHOT" } end,
        ApplyEvolution = function(profile, evolution)
            profile.archetype_phase = evolution.archetype_phase
            profile.role_archetype = evolution.role_archetype
            profile.candidate_affinities.finishing = evolution.candidate_affinities.finishing
            table.insert(profile.archetype_history, evolution.archetype_history[1])
        end,
    }
end
package.preload["zarg4n_player_writer"] = function()
    return {
        Apply = function() end,
        Matches = function() return true end,
    }
end
package.preload["zarg4n_logger"] = function()
    return { Error = function() end }
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

local player_fields = {
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

local old = {
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
    pending_transaction = nil,
    committed_transaction = { date = 20250723 },
    seasons_observed = 1,
    identity_revealed = false,
}

local profile = {}
for key, value in pairs(old) do profile[key] = value end

local save_calls = 0
local runtime = {
    state = {
        save_uid = "transaction-test",
        players = { ["101"] = profile },
        last_processed_date = 0,
    },
    state_store = {
        Save = function()
            save_calls = save_calls + 1
            if save_calls == 2 then
                return false, "injected commit failure"
            end
            return true
        end,
    },
    player_development_manager = { Save = function() end },
}

local Events = require "zarg4n_events"
Events.new(runtime):ProcessSeasonEnd()

local function assert_equal(actual, expected, label)
    if actual ~= expected then
        error(label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

assert_equal(profile.last_development.score, 1, "last development")
assert_equal(profile.playstyle_candidates[1], "BRUISER", "playstyle candidates")
assert_equal(profile.last_playstyle_award.regular, "BRUISER", "last award")
assert_equal(profile.last_stats.appearances, 10, "last stats")
assert_equal(profile.physical_projection.strength_total, 2, "physical projection")
assert_equal(profile.last_processed_date, 20250723, "processed date")
assert_equal(profile.archetype_phase, "emerging", "archetype phase")
assert_equal(profile.role_archetype, "explosive_winger", "role archetype")
assert_equal(profile.candidate_affinities.finishing, 3, "candidate affinities")
assert_equal(#profile.archetype_history, 1, "archetype history length")
assert_equal(profile.archetype_history[1], "explosive_winger", "archetype history")
assert_equal(profile.strength_growth_total, 2, "strength total")
assert_equal(profile.jumping_growth_total, 3, "jumping total")
assert_equal(profile.pending_transaction.date, 20260723, "pending transaction")
assert_equal(profile.committed_transaction.date, 20250723, "committed transaction")
assert_equal(profile.seasons_observed, 1, "seasons observed")
assert_equal(profile.identity_revealed, false, "identity reveal")
assert_equal(runtime.state.last_processed_date, 0, "season checkpoint")

if profile.candidate_affinities == old.candidate_affinities
    or profile.archetype_history == old.archetype_history then
    error("rollback restored shallow aliases instead of independent snapshots")
end

print("PASS: event transaction rollback restores the complete profile snapshot.")
