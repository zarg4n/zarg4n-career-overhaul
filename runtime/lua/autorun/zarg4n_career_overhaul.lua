local source_path = debug.getinfo(1, "S").source
if string.sub(source_path, 1, 1) == "@" then
    local script_directory = string.match(string.sub(source_path, 2), "^(.*[\\/])")
    if script_directory ~= nil then
        local lua_root = string.match(script_directory, "^(.*[\\/])autorun[\\/]$")
        local module_directory = lua_root and (lua_root .. "scripts/") or script_directory
        package.path = module_directory .. "?.lua;" .. package.path
    end
end

require "imports/career_mode/helpers"
require "imports/other/helpers"
require "imports/core/live_editor"

local Config = require "zarg4n_config"
local Logger = require "zarg4n_logger"
local StateStore = require "zarg4n_state_store"
local Events = require "zarg4n_events"

local runtime = {
    author = Config.author,
    state = nil,
    state_store = nil,
    events = nil,
    player_development_manager = nil,
}

local function load_save(save_uid)
    runtime.state_store = runtime.state_store or StateStore.new(Logger)
    local state, error_message = runtime.state_store:Load(save_uid)
    if state == nil then
        Logger:Error("State load failed: " .. tostring(error_message))
        return false
    end

    state.save_uid = save_uid
    runtime.state = state
    runtime.player_development_manager = LE.player_development_manager
    local manager_loaded, manager_error = pcall(function()
        runtime.player_development_manager:Load()
    end)
    if not manager_loaded then
        Logger:Warn("Development manager load failed: " .. tostring(manager_error))
    end
    runtime.events = Events.new(runtime)
    runtime.events:InitializePlayers()
    Logger:Info("Loaded " .. Config.author .. " runtime for " .. Config.target_title_update)
    return true
end

local function bootstrap()
    if not IsInCM() then
        Logger:Info("Career mode not active; runtime disabled")
        return
    end

    local save_uid = GetSaveUID()
    if save_uid == nil or save_uid == "" then
        Logger:Error("No save UID; runtime disabled")
        return
    end

    load_save(save_uid)
end

function Zarg4nCareerOnEvent(_, event_id, event)
    if runtime.events == nil then
        bootstrap()
    end
    if runtime.events ~= nil and IsInCM() then
        local save_uid = GetSaveUID()
        if save_uid ~= nil and save_uid ~= ""
            and runtime.state ~= nil
            and runtime.state.save_uid ~= save_uid then
            if not load_save(save_uid) then
                return
            end
        end
        runtime.events:OnCareerEvent(_, event_id, event)
        if runtime.state_store ~= nil and runtime.state ~= nil then
            local ok, error_message = runtime.state_store:Save(runtime.state)
            if not ok then
                Logger:Error("State save failed: " .. tostring(error_message))
            end
        end
    end
end

if not _G.ZARG4N_CAREER_RUNTIME_LOADED then
    AddEventHandler("post__CareerModeEvent", Zarg4nCareerOnEvent)
    _G.ZARG4N_CAREER_RUNTIME_LOADED = true
    bootstrap()
end
