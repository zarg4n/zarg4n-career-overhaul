package.path = "src/lua/?.lua;" .. package.path

local Stats = require "zarg4n_stats"
local Development = require "zarg4n_development"
local PlayStyles = require "zarg4n_playstyles"
local Profile = require "zarg4n_player_profile"
local PlayerWriter = require "zarg4n_player_writer"
local PhysicalGrowth = require "zarg4n_physical_growth"
local Positions = require "zarg4n_positions"

local function assert_close(actual, expected, tolerance, label)
    if math.abs(actual - expected) > tolerance then
        error(string.format("%s: expected %.4f, got %.4f", label, expected, actual))
    end
end

local profile = {
    initialized_age = 18,
    baseline_overall = 67,
    baseline_potential = 82,
    development_profile = 60,
    physical_potential = 82,
    speed_potential = 60,
    mental_potential = 58,
    aerial_potential = 55,
}

local created_profile = Profile.Create({
    playerid = 101,
    position_name = "ST",
    age = 17,
    overallrating = 65,
    potential = 82,
    height = 180,
    weight = 72,
}, "save-1")
assert(type(created_profile.regular_playstyles) == "table", "profile must track regular PlayStyles")
assert(type(created_profile.plus_playstyles) == "table", "profile must track PlayStyle+ awards")
assert(created_profile.identity_revealed == false, "new prospect identity must start hidden")
Profile.AdvanceSeason(created_profile)
assert(created_profile.identity_revealed == true, "prospect identity must reveal after one observed season")

local weighted = Stats.Aggregate(10, {
    { app = 10, avg = 700, goals = 2, assists = 1 },
    { app = 2, avg = 160, goals = 1, assists = 0 },
})
assert_close(weighted.average_rating, 7.1667, 0.001, "weighted average rating")

local cameo = Stats.Aggregate(10, {
    { app = 1, avg = 85, goals = 1, assists = 1 },
})
local cameo_result = Development.Calculate(profile, cameo, {
    age = 18,
    overallrating = 67,
    potential = 82,
})
assert(cameo_result.development_multiplier > 1, "decisive cameo must aid development")
assert(cameo_result.potential_delta == 0, "one cameo must not change season potential")

local strong_season = Stats.Aggregate(10, {
    { app = 30, avg = 2250, goals = 12, assists = 8 },
})
local strong_result = Development.Calculate(profile, strong_season, {
    age = 18,
    overallrating = 69,
    potential = 82,
})
assert(strong_result.potential_delta >= 1, "exceptional full season must affect potential")
assert(strong_result.potential_delta <= 3, "potential growth must remain capped")
local prime_result = Development.Calculate(profile, strong_season, {
    age = 28,
    overallrating = 78,
    potential = 80,
})
assert(prime_result.write_potential == true, "performance development must include the prime years")
local peaked_result = Development.Calculate(profile, {
    appearances = 20,
    average_rating = 6.5,
    goal_contribution = 0,
    sample_confidence = 1,
}, {
    age = 28,
    overallrating = 86,
    potential = 80,
})
assert(peaked_result.projected_potential == 80, "current OVR must not bypass the seasonal potential cap")
local veteran_result = Development.Calculate(profile, strong_season, {
    age = 34,
    overallrating = 86,
    potential = 80,
})
assert(veteran_result.write_potential == false, "veterans must not have potential forced up to current OVR")
assert(veteran_result.projected_potential == 80, "veteran potential must remain untouched")

local defender_season = Stats.Aggregate(11, {
    { app = 28, avg = 2044, goals = 1, assists = 1, clean_sheets = 16 },
})
local defender_result = Development.Calculate(profile, defender_season, {
    age = 19,
    position_name = "RCB",
    overallrating = 68,
    potential = 80,
})
assert(defender_result.potential_delta >= 1, "elite defensive season must affect potential without goals")
local goalkeeper_season = Stats.Aggregate(13, {
    { app = 30, avg = 2130, goals = 0, assists = 0, clean_sheets = 20 },
})
local goalkeeper_result = Development.Calculate(profile, goalkeeper_season, {
    age = 21,
    position_name = "GK",
    overallrating = 70,
    potential = 82,
})
assert(goalkeeper_result.potential_delta >= 1,
    "goalkeepers must fall back to clean sheets when save totals are unavailable")
assert(Positions.Normalize("RCB") == "CB", "side-specific centre-back position must normalize")
assert(Positions.Normalize("LDM") == "CDM", "side-specific defensive midfield position must normalize")

local poor_season = Stats.Aggregate(12, {
    { app = 24, avg = 1320, goals = 0, assists = 0 },
})
local poor_result = Development.Calculate(profile, poor_season, {
    age = 20,
    position_name = "ST",
    overallrating = 69,
    potential = 82,
})
assert(poor_result.potential_delta < 0, "sustained poor performance must be able to reduce potential")
assert(poor_result.potential_delta >= -2, "potential loss must remain capped")

local bruiser_candidates = PlayStyles.BuildCandidates(profile, {
    strength = 72,
    jumping = 65,
    shotpower = 62,
    longshots = 55,
    stamina = 77,
    acceleration = 74,
    interceptions = 68,
}, cameo)
local has_bruiser = false
for _, candidate in ipairs(bruiser_candidates) do
    has_bruiser = has_bruiser or candidate.id == "BRUISER"
end
assert(has_bruiser, "physical identity must qualify for Bruiser")

assert(PlayStyles.AddFlag(0, "POWER_SHOT") == 4, "Power Shot must use the FC 26 trait bit")
assert(PlayStyles.AddFlag(4, "POWER_SHOT") == 4, "adding a trait twice must be idempotent")
local hydrated = { regular_playstyles = {}, plus_playstyles = {} }
PlayStyles.HydrateProfile(hydrated, {
    trait1 = 268435460 + 1024 + 16777216,
    icontrait1 = 4,
})
assert(#hydrated.regular_playstyles == 4, "all existing FC 26 PlayStyles must be imported into the profile")
assert(hydrated.plus_playstyles[1] == "POWER_SHOT", "existing PlayStyle+ must be preserved")
PlayStyles.HydrateProfile(hydrated, { trait1 = 65536, icontrait1 = 4 })
local merged_intercept = false
for _, id in ipairs(hydrated.regular_playstyles) do
    merged_intercept = merged_intercept or id == "INTERCEPT"
end
assert(merged_intercept, "new database PlayStyles must merge into an existing profile")

local award_profile = {
    regular_playstyles = { "BRUISER", "RELENTLESS" },
    plus_playstyles = {},
}
local award = PlayStyles.ResolveAward(award_profile, { overallrating = 80 }, strong_season, bruiser_candidates)
assert(award ~= nil and award.level == "plus", "80 OVR prospect with two styles must earn first PlayStyle+")

local fields = {
    potential = 82,
    height = 180,
    weight = 72,
    strength = 74,
    jumping = 70,
    trait1 = 0,
    icontrait1 = 0,
}
local fake_table = {
    GetRecordFieldValue = function(_, _, field) return fields[field] end,
    SetRecordFieldValue = function(_, _, field, value) fields[field] = value end,
}
local writer_profile = {
    base_height = 180,
    base_weight = 72,
    base_strength = 74,
    base_jumping = 70,
    regular_playstyles = {},
    plus_playstyles = {},
}
PlayerWriter.Apply(fake_table, 1, { age = 18 }, writer_profile, {
    projected_potential = 84,
    write_potential = true,
}, {
    height_delta_cm = 2,
    weight_delta_kg = 3,
    strength_total = 2,
    jumping_total = 1,
}, {
    id = "POWER_SHOT",
    level = "regular",
})
assert(fields.potential == 84, "season potential delta must be written")
assert(fields.height == 182 and fields.weight == 75, "physical target must use baseline body")
assert(fields.strength == 76 and fields.jumping == 71, "physical attributes must grow conservatively")
assert(fields.trait1 == 4 and fields.icontrait1 == 0, "regular PlayStyle must not become PlayStyle+")
PlayerWriter.Apply(fake_table, 1, { age = 18 }, writer_profile, {
    projected_potential = 84,
    write_potential = true,
}, {
    height_delta_cm = 2,
    weight_delta_kg = 3,
    strength_total = 2,
    jumping_total = 1,
}, nil)
assert(fields.strength == 76 and fields.jumping == 71,
    "replaying a pending player write must be idempotent")
assert(PlayerWriter.Matches(fake_table, 1, { age = 18 }, writer_profile, {
    projected_potential = 84,
    write_potential = true,
}, {
    height_delta_cm = 2,
    weight_delta_kg = 3,
    strength_total = 2,
    jumping_total = 1,
}, {
    id = "POWER_SHOT",
    level = "regular",
}), "persisted career values must be recognizable during save reconciliation")
fields.potential = 80
PlayerWriter.Apply(fake_table, 1, { age = 34 }, writer_profile, {
    projected_potential = 86,
    write_potential = false,
}, {}, nil)
assert(fields.potential == 80, "writer must preserve veteran potential")

local athletic_profile = {
    initialized_age = 17,
    body_growth_potential = 80,
    physical_potential = 85,
    aerial_potential = 70,
}
local early_body = PhysicalGrowth.Calculate(athletic_profile, {}, { age = 18, performance_score = 0.8 })
local mature_body = PhysicalGrowth.Calculate(athletic_profile, {}, { age = 23, performance_score = 0.8 })
assert(early_body.weight_delta_kg > 0 and early_body.weight_delta_kg < mature_body.weight_delta_kg,
    "body mass must emerge gradually through age 23")
local slight_profile = {
    initialized_age = 16,
    body_growth_potential = 25,
    physical_potential = 35,
    aerial_potential = 40,
}
local slight_body = PhysicalGrowth.Calculate(slight_profile, {}, { age = 20, performance_score = 0.8 })
assert(slight_body.height_delta_cm == 0, "not every prospect should grow taller")
local late_profile = {
    initialized_age = 20,
    body_growth_potential = 90,
    physical_potential = 90,
    aerial_potential = 90,
}
local late_body = PhysicalGrowth.Calculate(late_profile, {}, { age = 20, performance_score = 0.8 })
assert(late_body.height_delta_cm == 0 and late_body.weight_delta_kg <= 1,
    "players first observed after academy age must not receive retroactive body jumps")
local poor_body = PhysicalGrowth.Calculate(athletic_profile, {}, { age = 19, performance_score = -0.4 })
assert(poor_body.strength_growth == 0 and poor_body.jumping_growth == 0,
    "automatic physical attributes must not rise after a poor season")

print("PASS: runtime development behavior is conservative.")
