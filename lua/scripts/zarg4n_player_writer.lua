local PlayStyles = require "zarg4n_playstyles"

local PlayerWriter = {}

local function clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

local function set_if_changed(table_ref, record, field, value)
    if value ~= nil and table_ref:GetRecordFieldValue(record, field) ~= value then
        table_ref:SetRecordFieldValue(record, field, value)
    end
end

local function append_unique(list, value)
    for _, item in ipairs(list) do
        if item == value then
            return
        end
    end
    table.insert(list, value)
end

local function body_targets(table_ref, record, profile, physical)
    local current_height = tonumber(table_ref:GetRecordFieldValue(record, "height")) or 0
    local current_weight = tonumber(table_ref:GetRecordFieldValue(record, "weight")) or 0
    local target_height = math.max(
        current_height,
        (profile.base_height or current_height) + (physical.height_delta_cm or 0)
    )
    local target_weight = math.max(
        current_weight,
        (profile.base_weight or current_weight) + (physical.weight_delta_kg or 0)
    )
    local base_strength = tonumber(profile.base_strength)
        or tonumber(table_ref:GetRecordFieldValue(record, "strength")) or 0
    local base_jumping = tonumber(profile.base_jumping)
        or tonumber(table_ref:GetRecordFieldValue(record, "jumping")) or 0
    return {
        height = clamp(target_height, 140, 215),
        weight = clamp(target_weight, 45, 120),
        strength = clamp(base_strength + (physical.strength_total or 0), 0, 99),
        jumping = clamp(base_jumping + (physical.jumping_total or 0), 0, 99),
    }
end

function PlayerWriter.Apply(table_ref, record, row, profile, development, physical, award)
    if development.write_potential ~= false then
        local potential = clamp(tonumber(development.projected_potential) or row.potential or 0, 0, 99)
        set_if_changed(table_ref, record, "potential", potential)
    end

    local age = tonumber(row.age) or 99
    if age <= 23 then
        local targets = body_targets(table_ref, record, profile, physical)
        set_if_changed(table_ref, record, "height", targets.height)
        set_if_changed(table_ref, record, "weight", targets.weight)
        set_if_changed(table_ref, record, "strength", targets.strength)
        set_if_changed(table_ref, record, "jumping", targets.jumping)
    end

    if award ~= nil then
        local target_field = award.level == "plus" and "icontrait1" or "trait1"
        local current_flags = table_ref:GetRecordFieldValue(record, target_field)
        set_if_changed(table_ref, record, target_field, PlayStyles.AddFlag(current_flags, award.id))
        if award.level == "plus" then
            append_unique(profile.plus_playstyles, award.id)
        else
            append_unique(profile.regular_playstyles, award.id)
        end
    end

    return true
end

function PlayerWriter.Matches(table_ref, record, row, profile, development, physical, award)
    if development.write_potential ~= false then
        local expected = clamp(tonumber(development.projected_potential) or row.potential or 0, 0, 99)
        if tonumber(table_ref:GetRecordFieldValue(record, "potential")) ~= expected then
            return false
        end
    end

    if (tonumber(row.age) or 99) <= 23 then
        local targets = body_targets(table_ref, record, profile, physical)
        for field, expected in pairs(targets) do
            if tonumber(table_ref:GetRecordFieldValue(record, field)) ~= expected then
                return false
            end
        end
    end

    if award ~= nil then
        local target_field = award.level == "plus" and "icontrait1" or "trait1"
        if not PlayStyles.HasFlag(table_ref:GetRecordFieldValue(record, target_field), award.id) then
            return false
        end
    end
    return true
end

return PlayerWriter
