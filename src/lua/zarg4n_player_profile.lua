local Profile = {}
local Positions = require "zarg4n_positions"

local function clamp(value)
    return math.max(0, math.min(100, math.floor(value + 0.5)))
end

local function hash(seed)
    local value = 2166136261
    for index = 1, #seed do
        value = (value * 16777619 + string.byte(seed, index)) % 2147483647
    end
    return value
end

local function roll(seed, low, high)
    local value = hash(seed) % 10000 / 10000
    return low + (high - low) * value
end

local function role_bias(position)
    local map = {
        GK = { physical = 0, speed = 0, technical = 0, mental = 8, aerial = 4 },
        CB = { physical = 5, speed = 2, technical = 2, mental = 5, aerial = 5 },
        LB = { physical = 2, speed = 7, technical = 4, mental = 2, aerial = 1 },
        RB = { physical = 2, speed = 7, technical = 4, mental = 2, aerial = 1 },
        CDM = { physical = 5, speed = 2, technical = 5, mental = 6, aerial = 1 },
        CM = { physical = 2, speed = 3, technical = 7, mental = 6, aerial = 1 },
        CAM = { physical = 1, speed = 4, technical = 8, mental = 5, aerial = 0 },
        LM = { physical = 1, speed = 7, technical = 6, mental = 2, aerial = 0 },
        RM = { physical = 1, speed = 7, technical = 6, mental = 2, aerial = 0 },
        LW = { physical = 1, speed = 8, technical = 7, mental = 1, aerial = 0 },
        RW = { physical = 1, speed = 8, technical = 7, mental = 1, aerial = 0 },
        ST = { physical = 5, speed = 4, technical = 6, mental = 5, aerial = 3 },
        CF = { physical = 3, speed = 4, technical = 8, mental = 5, aerial = 1 },
    }
    return map[position] or { physical = 2, speed = 2, technical = 2, mental = 2, aerial = 2 }
end

function Profile.Create(player_row, save_uid)
    local player_id = tonumber(player_row.playerid) or 0
    local position = Positions.Normalize(player_row.position_name)
    local bias = role_bias(position)
    local seed = tostring(save_uid) .. ":" .. tostring(player_id)

    local current_ovr = tonumber(player_row.overallrating) or 50
    local potential = tonumber(player_row.potential) or current_ovr
    local quality_factor = math.max(0, math.min(12, potential - current_ovr))

    return {
        player_id = player_id,
        seed = seed,
        position = position,
        initialized_age = tonumber(player_row.age) or 18,
        physical_potential = clamp(roll(seed .. ":physical", 35, 82) + bias.physical),
        speed_potential = clamp(roll(seed .. ":speed", 35, 82) + bias.speed),
        technical_potential = clamp(roll(seed .. ":technical", 35, 82) + bias.technical),
        mental_potential = clamp(roll(seed .. ":mental", 35, 82) + bias.mental),
        aerial_potential = clamp(roll(seed .. ":aerial", 25, 78) + bias.aerial),
        body_growth_potential = clamp(roll(seed .. ":body", 20, 78) + quality_factor),
        memory_strength = clamp(roll(seed .. ":memory", 25, 90)),
        trust_sensitivity = clamp(roll(seed .. ":trust", 25, 90)),
        development_profile = clamp(roll(seed .. ":profile", 20, 90)),
        base_height = tonumber(player_row.height) or 0,
        base_weight = tonumber(player_row.weight) or 0,
        base_strength = tonumber(player_row.strength) or 0,
        base_jumping = tonumber(player_row.jumping) or 0,
        strength_growth_total = 0,
        jumping_growth_total = 0,
        baseline_potential = potential,
        baseline_overall = current_ovr,
        regular_playstyles = {},
        plus_playstyles = {},
        archetype_phase = (tonumber(player_row.age) or 18) <= 18 and "prospect" or "emerging",
        role_archetype = "unresolved",
        candidate_affinities = {},
        archetype_history = {},
        seasons_observed = 0,
        identity_revealed = false,
    }
end

function Profile.AdvanceSeason(profile)
    profile.seasons_observed = (tonumber(profile.seasons_observed) or 0) + 1
    profile.identity_revealed = profile.seasons_observed >= 1
end

function Profile.Validate(profile)
    return type(profile) == "table"
        and tonumber(profile.player_id) ~= nil
        and tonumber(profile.baseline_potential) ~= nil
        and tonumber(profile.development_profile) ~= nil
end

return Profile
