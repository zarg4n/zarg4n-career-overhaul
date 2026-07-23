package.path = "src/lua/?.lua;" .. package.path

package.preload["imports/external/json"] = function()
    return {
        decode = function(content)
            if content == "legacy-v1" then return _G.LEGACY_V1_STATE end
            if content == "legacy-v2" then return _G.LEGACY_V2_STATE end
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

local legacy_v1 = {
    schema_version = 1,
    save_uid = "legacy-v1-career",
    initialized = true,
    players = {},
}
local rejected_v1, rejected_v1_error = Migrations.ValidateCurrent(
    legacy_v1,
    "legacy-v1-career"
)
assert_equal(rejected_v1, nil, "schema v1 must be rejected")
assert(rejected_v1_error:find("unsupported", 1, true), "schema v1 rejection must be explicit")

local legacy_v2 = {
    schema_version = 2,
    save_uid = "legacy-v2-career",
    initialized = false,
    last_processed_date = 0,
    players = {},
    feature_flags = { database_writes = false },
    eligibility = { explicit = false },
}
local rejected_v2, rejected_v2_error = Migrations.ValidateCurrent(
    legacy_v2,
    "legacy-v2-career"
)
assert_equal(rejected_v2, nil, "legacy schema v2 without fresh origin must be rejected")
assert(rejected_v2_error:find("fresh", 1, true), "legacy v2 rejection must explain fresh-save requirement")

local fresh = assert(Migrations.NewState("fresh-career"))
assert_equal(SaveGuard.CanWrite(fresh), false, "fresh state starts read-only")

local wrong_marker, wrong_marker_error = SaveGuard.MarkFreshCareer(
    fresh,
    "user_opt_in",
    20260723
)
assert_equal(wrong_marker, nil, "general opt-in marker must be rejected")
assert(type(wrong_marker_error) == "string", "marker rejection must be explicit")
assert_equal(SaveGuard.CanWrite(fresh), false, "rejected marker must not enable writes")

local marked, marker_error = SaveGuard.MarkFreshCareer(
    fresh,
    "initial_user_added",
    20260723
)
assert(marked ~= nil and marker_error == nil, "exact new-career event must activate fresh state")
assert_equal(marked.eligibility.source, "career_event", "eligibility source")
assert_equal(marked.eligibility.marker, "initial_user_added", "eligibility marker")
assert_equal(marked.lifecycle.awaiting_initial_user_added, false, "activation is one-shot")
assert_equal(SaveGuard.CanWrite(marked), true, "activated fresh state may write")

local activated_again = SaveGuard.MarkFreshCareer(marked, "initial_user_added", 20260724)
assert_equal(activated_again, nil, "activation must not be replayed")

local logger = { Warn = function() end }
local files = {}
local original_open = io.open
local opened_paths = {}
LE_DATA_PATH = "memory-root"

io.open = function(path, mode)
    table.insert(opened_paths, path)
    if mode ~= "r" or files[path] == nil then return nil end
    return {
        read = function() return files[path] end,
        close = function() end,
    }
end

local store = StateStore.new(logger)
local fresh_state, fresh_error = store:Load("brand-new-career")
assert(fresh_state ~= nil and fresh_error == nil, "missing state may create a fresh state")
assert_equal(fresh_state.state_origin, "fresh_v2", "fresh state origin")
assert_equal(fresh_state.lifecycle.awaiting_initial_user_added, true, "fresh state awaits event")

_G.LEGACY_V1_STATE = legacy_v1
files[LE_DATA_PATH .. "\\zarg4n_career_legacy-v1-career.json"] = "legacy-v1"
local loaded_v1, loaded_v1_error = store:Load("legacy-v1-career")
assert_equal(loaded_v1, nil, "state store must reject schema v1")
assert(loaded_v1_error:find("corrupted", 1, true), "legacy state must fail closed")

_G.LEGACY_V2_STATE = legacy_v2
files[LE_DATA_PATH .. "\\zarg4n_career_legacy-v2-career.json"] = "legacy-v2"
local loaded_v2, loaded_v2_error = store:Load("legacy-v2-career")
assert_equal(loaded_v2, nil, "state store must reject pre-fresh-marker schema v2")
assert(loaded_v2_error:find("corrupted", 1, true), "legacy v2 must fail closed")

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
end

io.open = original_open
_G.LEGACY_V1_STATE = nil
_G.LEGACY_V2_STATE = nil

print("PASS: fresh-save-only state guard behavior.")
