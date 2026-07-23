local Migrations = require "zarg4n_migrations"

local SaveGuard = {}

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

local function valid_state(state)
    return type(state) == "table"
        and state.schema_version == 2
        and Migrations.IsValidSaveUid(state.save_uid)
        and type(state.players) == "table"
        and type(state.feature_flags) == "table"
        and type(state.eligibility) == "table"
        and type(state.migration_journal) == "table"
        and type(state.rollback_metadata) == "table"
        and type(state.rollback_metadata.players) == "table"
end

function SaveGuard.CanWrite(state)
    if not valid_state(state) then
        return false, "invalid or unsupported state"
    end
    if type(state.eligibility) ~= "table" or state.eligibility.explicit ~= true then
        return false, "career has no explicit eligibility marker"
    end
    if type(state.feature_flags) ~= "table"
        or state.feature_flags.database_writes ~= true then
        return false, "database writes are disabled"
    end
    return true, nil
end

function SaveGuard.MarkEligible(state, marker)
    if not valid_state(state) then
        return nil, "invalid or unsupported state"
    end
    if type(marker) ~= "table"
        or type(marker.source) ~= "string"
        or marker.source == ""
        or type(marker.marker) ~= "string"
        or marker.marker == "" then
        return nil, "invalid eligibility marker"
    end

    state.eligibility = {
        explicit = true,
        source = marker.source,
        marker = marker.marker,
        marked_at = marker.at or 0,
    }
    state.feature_flags.database_writes = true
    return state, nil
end

function SaveGuard.RecordPlayerSnapshot(state, snapshot)
    local can_write, write_error = SaveGuard.CanWrite(state)
    if not can_write then
        return nil, write_error
    end
    if type(snapshot) ~= "table"
        or snapshot.player_id == nil
        or type(snapshot.operation_id) ~= "string"
        or snapshot.operation_id == ""
        or type(snapshot.before) ~= "table"
        or type(snapshot.after) ~= "table" then
        return nil, "invalid player rollback snapshot"
    end

    local player_key = tostring(snapshot.player_id)
    local player_snapshots = state.rollback_metadata.players[player_key] or {}

    for _, existing in ipairs(player_snapshots) do
        if existing.operation_id == snapshot.operation_id then
            return existing, nil
        end
    end

    local entry = {
        operation_id = snapshot.operation_id,
        player_id = snapshot.player_id,
        recorded_at = snapshot.at or 0,
        before = copy(snapshot.before),
        after = copy(snapshot.after),
    }
    table.insert(player_snapshots, entry)
    state.rollback_metadata.players[player_key] = player_snapshots
    return entry, nil
end

return SaveGuard
