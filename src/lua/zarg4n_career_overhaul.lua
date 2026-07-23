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

    runtime.state_store = StateStore.new(Logger)
    local state, error_message = runtime.state_store:Load(save_uid)
    if state == nil then
        Logger:Error("State load failed: " .. tostring(error_message))
        return
    end

    state.save_uid = save_uid
    runtime.state = state
    runtime.player_development_manager = LE.player_development_manager
    runtime.events = Events.new(runtime)
    runtime.events:InitializePlayers()

    Logger:Info("Loaded " .. Config.author .. " runtime for " .. Config.target_title_update)
end

function Zarg4nCareerOnEvent(_, event_id, event)
    if runtime.events == nil then
        bootstrap()
    end
    if runtime.events ~= nil then
        runtime.events:OnCareerEvent(_, event_id, event)
        if runtime.state_store ~= nil and runtime.state ~= nil then
            local ok, error_message = runtime.state_store:Save(runtime.state)
            if not ok then
                Logger:Error("State save failed: " .. tostring(error_message))
            end
        end
    end
end

AddEventHandler("post__CareerModeEvent", Zarg4nCareerOnEvent)
bootstrap()
