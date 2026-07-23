local Migrations = {}

local CURRENT_SCHEMA_VERSION = 2
local FRESH_STATE_ORIGIN = "fresh_v2"
local MAX_SAVE_UID_LENGTH = 128

function Migrations.IsValidSaveUid(save_uid)
    return type(save_uid) == "string"
        and #save_uid >= 1
        and #save_uid <= MAX_SAVE_UID_LENGTH
        and save_uid:match("^[A-Za-z0-9_-]+$") ~= nil
end

local function copy(value, seen)
    if type(value) ~= "table" then return value end

    seen = seen or {}
    if seen[value] ~= nil then return seen[value] end

    local result = {}
    seen[value] = result
    for key, item in pairs(value) do
        result[copy(key, seen)] = copy(item, seen)
    end
    return result
end

local function valid_current_state(state, expected_save_uid)
    if type(state) ~= "table" then return false, "invalid state" end
    if tonumber(state.schema_version) ~= CURRENT_SCHEMA_VERSION then
        return false, "unsupported state schema"
    end
    if not Migrations.IsValidSaveUid(expected_save_uid) then
        return false, "invalid save uid"
    end
    if not Migrations.IsValidSaveUid(state.save_uid)
        or state.save_uid ~= expected_save_uid then
        return false, "state save uid mismatch"
    end
    if state.state_origin ~= FRESH_STATE_ORIGIN then
        return false, "state was not created for a fresh career"
    end
    if type(state.lifecycle) ~= "table"
        or type(state.players) ~= "table"
        or type(state.feature_flags) ~= "table"
        or type(state.eligibility) ~= "table" then
        return false, "invalid state structure"
    end
    return true, nil
end

function Migrations.NewState(save_uid)
    if not Migrations.IsValidSaveUid(save_uid) then
        return nil, "invalid save uid"
    end
    return {
        schema_version = CURRENT_SCHEMA_VERSION,
        state_origin = FRESH_STATE_ORIGIN,
        save_uid = save_uid,
        initialized = false,
        last_processed_date = 0,
        players = {},
        feature_flags = {
            database_writes = false,
        },
        eligibility = {
            explicit = false,
        },
        lifecycle = {
            awaiting_initial_user_added = true,
        },
    }, nil
end

function Migrations.ValidateCurrent(source, expected_save_uid)
    local valid, validation_error = valid_current_state(source, expected_save_uid)
    if not valid then return nil, validation_error end

    local state = copy(source)
    local activated = state.eligibility.explicit == true
        and state.eligibility.source == "career_event"
        and state.eligibility.marker == "initial_user_added"
        and state.lifecycle.awaiting_initial_user_added == false
    state.eligibility.explicit = activated
    state.feature_flags.database_writes =
        state.feature_flags.database_writes == true and activated
    return state, nil
end

Migrations.CURRENT_SCHEMA_VERSION = CURRENT_SCHEMA_VERSION
Migrations.FRESH_STATE_ORIGIN = FRESH_STATE_ORIGIN

return Migrations
