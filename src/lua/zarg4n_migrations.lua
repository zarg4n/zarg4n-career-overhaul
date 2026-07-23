local Migrations = {}

local CURRENT_SCHEMA_VERSION = 2
local MAX_SAVE_UID_LENGTH = 128

function Migrations.IsValidSaveUid(save_uid)
    return type(save_uid) == "string"
        and #save_uid >= 1
        and #save_uid <= MAX_SAVE_UID_LENGTH
        and save_uid:match("^[A-Za-z0-9_-]+$") ~= nil
end

local function copy(value, seen)
    if type(value) ~= "table" then
        return value
    end

    seen = seen or {}
    if seen[value] ~= nil then
        return seen[value]
    end

    local result = {}
    seen[value] = result
    for key, item in pairs(value) do
        result[copy(key, seen)] = copy(item, seen)
    end
    return result
end

local function v2_defaults(save_uid)
    return {
        schema_version = CURRENT_SCHEMA_VERSION,
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
        migration_journal = {},
        rollback_metadata = {
            players = {},
        },
    }
end

local function validate_optional_table(state, field)
    local value = state[field]
    if value ~= nil and type(value) ~= "table" then
        return false, field .. " must be a table"
    end
    return true, nil
end

local function validate_structures(state)
    local fields = {
        "players",
        "feature_flags",
        "eligibility",
        "migration_journal",
        "rollback_metadata",
    }

    for _, field in ipairs(fields) do
        local valid, validation_error = validate_optional_table(state, field)
        if not valid then
            return false, validation_error
        end
    end

    if state.rollback_metadata ~= nil
        and state.rollback_metadata.players ~= nil
        and type(state.rollback_metadata.players) ~= "table" then
        return false, "rollback_metadata.players must be a table"
    end

    return true, nil
end

local function normalize_v2(state)
    local valid, validation_error = validate_structures(state)
    if not valid then
        return nil, validation_error
    end

    state.players = state.players or {}
    state.eligibility = state.eligibility or { explicit = false }
    state.eligibility.explicit = state.eligibility.explicit == true
    state.feature_flags = state.feature_flags or {}
    state.feature_flags.database_writes = state.feature_flags.database_writes == true
        and state.eligibility.explicit == true
    if not state.eligibility.explicit then
        state.feature_flags.database_writes = false
    end
    state.migration_journal = state.migration_journal or {}
    state.rollback_metadata = state.rollback_metadata or {}
    state.rollback_metadata.players = state.rollback_metadata.players or {}
    return state
end

function Migrations.NewState(save_uid)
    if not Migrations.IsValidSaveUid(save_uid) then
        return nil, "invalid save uid"
    end
    return v2_defaults(save_uid), nil
end

function Migrations.Upgrade(source, expected_save_uid, migrated_at)
    if type(source) ~= "table" then
        return nil, "invalid state"
    end
    if not Migrations.IsValidSaveUid(expected_save_uid) then
        return nil, "invalid save uid"
    end
    if not Migrations.IsValidSaveUid(source.save_uid)
        or source.save_uid ~= expected_save_uid then
        return nil, "state save uid mismatch"
    end

    local version = tonumber(source.schema_version)
    if version == CURRENT_SCHEMA_VERSION then
        return normalize_v2(copy(source))
    end
    if version ~= 1 then
        return nil, "unsupported state schema"
    end

    local structurally_valid, structure_error = validate_structures(source)
    if not structurally_valid then
        return nil, structure_error
    end

    local state = copy(source)
    state.schema_version = CURRENT_SCHEMA_VERSION
    state.feature_flags = {
        database_writes = false,
    }
    state.eligibility = {
        explicit = false,
    }
    state.migration_journal = state.migration_journal or {}
    table.insert(state.migration_journal, {
        from_version = 1,
        to_version = CURRENT_SCHEMA_VERSION,
        migrated_at = migrated_at or 0,
        database_writes_enabled = false,
    })
    state.rollback_metadata = state.rollback_metadata or { players = {} }

    return normalize_v2(state)
end

Migrations.CURRENT_SCHEMA_VERSION = CURRENT_SCHEMA_VERSION

return Migrations
