local Dialogue = {}

local FAMILIES = {
    post_match = true,
    promise = true,
    press = true,
    transfer_observer = true,
}

local VARIANT_TAGS = {
    post_match = {
        { impact = true },
        { score_contribution = true },
        { cameo = true },
        { pressing = true },
        { poor = true },
        { goal = true },
        { defensive = true },
        { rushed = true },
        { pressure = true, generic = true },
        { strong = true, generic = true },
    },
    transfer_observer = {
        { rejected = true },
        { rejected = true },
        { counter_offer = true },
        { counter_offer = true },
        { negotiation = true },
        { retracted = true },
        { loan = true },
        { about_to_complete = true },
        { complete = true },
        { transfer_message = true },
    },
}

local function hash(seed)
    local value = 5381
    local text = tostring(seed or "")
    for index = 1, #text do
        value = (value * 33 + string.byte(text, index)) % 2147483647
    end
    return value
end

local function normalize_tags(context)
    local source = type(context) == "table" and context.tags or nil
    if type(source) ~= "table" then
        return { generic = true }
    end

    local tags = {}
    for key, value in pairs(source) do
        if type(key) == "number" then
            tags[tostring(value)] = true
        elseif value then
            tags[tostring(key)] = true
        end
    end
    if next(tags) == nil then
        tags.generic = true
    end
    return tags
end

local function eligible_variants(family, tags)
    local requirements = VARIANT_TAGS[family]
    if not requirements then
        return { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }
    end

    local eligible = {}
    for variant, required_tags in ipairs(requirements) do
        for tag in pairs(required_tags) do
            if tags[tag] then
                eligible[#eligible + 1] = variant
                break
            end
        end
    end
    return eligible
end

function Dialogue.SelectKey(family, seed, context)
    if not FAMILIES[family] then
        error("unsupported dialogue family: " .. tostring(family))
    end
    local eligible = eligible_variants(family, normalize_tags(context))
    if #eligible == 0 then
        error("no eligible dialogue variant for family: " .. tostring(family))
    end
    local variant = eligible[hash(seed) % #eligible + 1]
    return string.format("%s.%02d", family, variant)
end

function Dialogue.Build(family, seed, effects, context)
    return {
        key = Dialogue.SelectKey(family, seed, context),
        family = family,
        effects = effects or {},
    }
end

return Dialogue
