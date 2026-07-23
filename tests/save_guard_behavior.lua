package.path = "src/lua/?.lua;" .. package.path

package.preload["imports/external/json"] = function()
    return {
        decode = function(content)
            if content == "malformed-v2" then
                return _G.MALFORMED_V2_STATE
            end
            error("invalid json")
        end,
        encode = function() error("encoding is outside this behavior test") end,
    }
end

local Migrations = require "zarg4n_migrations"
local SaveGuard = require "zarg4n_save_guard"
local StateStore = require "zarg4n_state_store"

local function assert_equal(actual, expected, label)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", label, tostring(expected), tostring(actual)))
    end
end

local v1 = {
    schema_version = 1,
    save_uid = "existing-career",
    initialized = true,
    last_processed_date = 20260723,
    players = {
        ["17"] = { baseline_potential = 82, personality = "driven" },
    },
}

local migrated, migration_error = Migrations.Upgrade(v1, "existing-career", 20260723)
assert(migrated ~= nil and migration_error == nil, "schema v1 must migrate to v2")
assert_equal(migrated.schema_version, 2, "migrated schema")
assert_equal(migrated.players["17"].baseline_potential, 82, "v1 player data preservation")
assert_equal(migrated.last_processed_date, 20260723, "v1 season checkpoint preservation")
assert_equal(migrated.feature_flags.database_writes, false, "migration must default to read-only")
assert_equal(migrated.eligibility.explicit, false, "existing career must require explicit eligibility")
assert_equal(migrated.migration_journal[1].from_version, 1, "migration journal source")
assert_equal(migrated.migration_journal[1].to_version, 2, "migration journal target")

local allowed, reason = SaveGuard.CanWrite(migrated)
assert_equal(allowed, false, "unknown existing career must fail closed")
assert(type(reason) == "string" and reason ~= "", "write denial must explain itself")

local marked, marker_error = SaveGuard.MarkEligible(
    migrated,
    { source = "user_opt_in", marker = "existing-career-approved", at = 20260723 }
)
assert(marked ~= nil and marker_error == nil, "explicit eligibility marker must be accepted")
assert_equal(marked.feature_flags.database_writes, true, "explicit eligibility enables database writes")
assert_equal(SaveGuard.CanWrite(marked), true, "eligible state may write")

local snapshot, snapshot_error = SaveGuard.RecordPlayerSnapshot(marked, {
    operation_id = "season-2026-player-17",
    player_id = 17,
    at = 20260723,
    before = { potential = 82, strength = 70 },
    after = { potential = 84, strength = 71 },
})
assert(snapshot ~= nil and snapshot_error == nil, "valid rollback snapshot must be recorded")
assert_equal(marked.rollback_metadata.players["17"][1].before.potential, 82, "before snapshot")
assert_equal(marked.rollback_metadata.players["17"][1].after.potential, 84, "after snapshot")

local rejected = SaveGuard.RecordPlayerSnapshot(marked, {
    operation_id = "missing-after",
    player_id = 18,
    before = { potential = 70 },
})
assert_equal(rejected, nil, "incomplete rollback metadata must be rejected")

local wrong_uid, wrong_uid_error = Migrations.Upgrade(v1, "another-career", 20260723)
assert_equal(wrong_uid, nil, "mismatched save UID must fail closed")
assert(type(wrong_uid_error) == "string", "UID failure must be explicit")

local malformed_fields = {
    eligibility = false,
    feature_flags = "enabled",
    rollback_metadata = true,
    migration_journal = 42,
    players = "not-a-table",
}

for field, invalid_value in pairs(malformed_fields) do
    local malformed = {
        schema_version = 2,
        save_uid = "malformed-career",
        initialized = true,
        last_processed_date = 0,
        players = {},
        feature_flags = { database_writes = false },
        eligibility = { explicit = false },
        migration_journal = {},
        rollback_metadata = { players = {} },
    }
    malformed[field] = invalid_value

    local ok, state, state_error = pcall(
        Migrations.Upgrade,
        malformed,
        "malformed-career",
        20260723
    )
    assert_equal(ok, true, field .. " corruption must not raise a Lua error")
    assert_equal(state, nil, field .. " corruption must fail closed")
    assert(type(state_error) == "string" and state_error ~= "",
        field .. " corruption must return an explicit error")
end

local logger = {
    Warn = function() end,
}
local corrupt_uid = "corrupt-career"
LE_DATA_PATH = "memory-root"
local corrupt_path = LE_DATA_PATH .. "\\zarg4n_career_" .. corrupt_uid .. ".json"
local files = {
    [corrupt_path] = "{ definitely-not-json",
}
local original_open = io.open
local opened_paths = {}
io.open = function(path, mode)
    table.insert(opened_paths, path)
    if mode ~= "r" or files[path] == nil then
        return nil
    end
    return {
        read = function() return files[path] end,
        close = function() end,
    }
end

local store = StateStore.new(logger)
local corrupt_state, corrupt_error = store:Load(corrupt_uid)
assert_equal(corrupt_state, nil, "corrupted state must not become a fresh writable state")
assert(type(corrupt_error) == "string" and corrupt_error:find("corrupted", 1, true),
    "corrupted state must fail closed")

local fresh_state, fresh_error = store:Load("brand-new-career")
assert(fresh_state ~= nil and fresh_error == nil, "missing state may create an isolated state record")
assert_equal(fresh_state.schema_version, 2, "new state schema")
assert_equal(fresh_state.feature_flags.database_writes, false, "new state starts read-only")

_G.MALFORMED_V2_STATE = {
    schema_version = 2,
    save_uid = "malformed-load",
    players = {},
    feature_flags = false,
    eligibility = { explicit = false },
    migration_journal = {},
    rollback_metadata = { players = {} },
}
files[LE_DATA_PATH .. "\\zarg4n_career_malformed-load.json"] = "malformed-v2"
local load_ok, malformed_state, malformed_error = pcall(function()
    return store:Load("malformed-load")
end)
assert_equal(load_ok, true, "malformed state load must not raise a Lua error")
assert_equal(malformed_state, nil, "malformed state load must fail closed")
assert(type(malformed_error) == "string" and malformed_error ~= "",
    "malformed state load must return an explicit error")

local malicious_uids = {
    "../escape",
    "..\\escape",
    "folder/name",
    "folder\\name",
    "uid:stream",
    string.rep("a", 129),
}

for _, malicious_uid in ipairs(malicious_uids) do
    opened_paths = {}
    local rejected_state, rejected_error = store:Load(malicious_uid)
    assert_equal(rejected_state, nil, "malicious UID must be rejected")
    assert(type(rejected_error) == "string" and rejected_error:find("uid", 1, true),
        "malicious UID rejection must be explicit")
    assert_equal(#opened_paths, 0, "malicious UID must be rejected before path construction")

    local new_state, new_state_error = Migrations.NewState(malicious_uid)
    assert_equal(new_state, nil, "migration layer must reject malicious UID")
    assert(type(new_state_error) == "string", "migration UID rejection must be explicit")
end

io.open = original_open
_G.MALFORMED_V2_STATE = nil

print("PASS: save guard and schema v2 migration behavior.")
