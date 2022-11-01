-- Retrive addon folder name, and our local, private namespace.
---@type string, table
local addonName, addon = ...

-- Fetch the localization table
---@type table<string, string>
local L = addon.L or {}


-- Lua API
-----------------------------------------------------------
-- Upvalue any lua functions used here.


-- WoW API
-----------------------------------------------------------
-- Upvalue any WoW functions used here.
local _G = _G


-- Your default settings.
-----------------------------------------------------------
-- Note that anything changed will be saved to disk when you reload the user
-- interface, or exit the game, and those saved changes will override your
-- defaults here.
-- * You should access saved settings by using `db[key]`
-- * Don't put frame handles or other widget references in here,
--   just strings, numbers, and booleans. Tables also work.
local db = (function(db) _G[addonName .. "_DB"] = db; return db end)({
	-- Put your default settings here
})


-- Utility Functions
-----------------------------------------------------------
-- Add utility functions like time formatting and similar here.


-- Callbacks
-----------------------------------------------------------
-- Add functions called multiple times by your reactive addon code here.


-- Addon API
-----------------------------------------------------------
-- Add any extra addon environment methods here.


-- Addon Core
-----------------------------------------------------------
-- Your event handler.
-- Any events you add should be handled here.
--- @param event string The name of the event that fired.
--- @param ... unknown Any payloads passed by the event handlers.
function addon:OnEvent(event, ...)
end

-- Your chat command handler.
---@param editBox table|frame The editbox the command was entered into.
---@param command string The name of the slash command type in.
---@param ... string Any additional arguments passed to your command, all as strings.
function addon:OnChatCommand(editBox, command, ...)
end

-- Initialization.
-- This fires when the addon and its settings are loaded.
function addon:OnInit()
	-- Do any parsing of saved settings here.
	-- This is also a good place to create your frames and objects.
end

-- Enabling.
-- This fires when most of the user interface has been loaded
-- and most data is available to the user.
function addon:OnEnable()
	-- Register your events here.
end
