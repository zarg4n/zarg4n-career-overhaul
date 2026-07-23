local Personality = {}

local function clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

local function hash(seed)
    local value = 2166136261
    for index = 1, #seed do
        value = (value * 16777619 + string.byte(seed, index)) % 2147483647
    end
    return value
end

local function dimension(seed, name)
    return hash(seed .. ":" .. name) % 101
end

function Personality.Create(player_id, career_id)
    local seed = tostring(career_id or "") .. ":" .. tostring(player_id or 0)
    return {
        player_id = tonumber(player_id) or 0,
        impulsive = dimension(seed, "impulsive"),
        calm = dimension(seed, "calm"),
        carefree = dimension(seed, "carefree"),
        ambition = dimension(seed, "ambition"),
        confidence = dimension(seed, "confidence"),
    }
end

local function effect(value)
    if value < 0 then
        return math.ceil(value - 0.5)
    end
    return math.floor(value + 0.5)
end

function Personality.Respond(personality, approach, context)
    personality = personality or {}
    context = context or {}

    local impulsive = clamp(tonumber(personality.impulsive) or 50, 0, 100)
    local calm = clamp(tonumber(personality.calm) or 50, 0, 100)
    local carefree = clamp(tonumber(personality.carefree) or 50, 0, 100)
    local ambition = clamp(tonumber(personality.ambition) or 50, 0, 100)
    local confidence = clamp(tonumber(personality.confidence) or 50, 0, 100)
    local form = clamp(tonumber(context.form) or 0, -2, 2)
    local effects
    local tone

    if approach == "praise" then
        effects = {
            morale = effect(2 + confidence * 0.025 + form * 0.5),
            sharpness = effect(0.5 + ambition * 0.012),
            trust = effect(1 + calm * 0.012),
        }
        tone = confidence >= 70 and "assured" or "appreciative"
    elseif approach == "challenge" then
        effects = {
            morale = effect(-1 + ambition * 0.025 + impulsive * 0.008),
            sharpness = effect(1 + ambition * 0.02 + impulsive * 0.018),
            trust = effect(-1 + calm * 0.015),
        }
        tone = impulsive >= 70 and "fired_up" or "focused"
    elseif approach == "criticism" then
        effects = {
            morale = effect(-4 + carefree * 0.04 + calm * 0.006),
            sharpness = effect(-1 + ambition * 0.025 + calm * 0.008),
            trust = effect(-2 + calm * 0.03 + carefree * 0.003),
        }
        tone = carefree >= 70 and "unfazed" or (calm >= 70 and "measured" or "defensive")
    else
        error("unsupported response approach: " .. tostring(approach))
    end

    return {
        approach = approach,
        tone = tone,
        effects = effects,
    }
end

return Personality
