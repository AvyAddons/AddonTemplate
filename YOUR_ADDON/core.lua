-- Retrive addon folder name, and our local, private namespace.
---@type string, table
local addonName, addon = ...

-- Lua API
-----------------------------------------------------------
-- Upvalue any lua functions used here.
local tonumber = tonumber
local string_gsub = string.gsub
local string_find = string.find
local string_split = string.split

-- WoW API
-----------------------------------------------------------
-- Upvalue any WoW functions used here.
local _G = _G
---@type table<string, function>
local SlashCmdList = _G["SlashCmdList"]
local GetBuildInfo = _G.GetBuildInfo
local GetAddOnInfo = _G.GetAddOnInfo
local GetNumAddOns = _G.GetNumAddOns
local GetAddOnEnableState = _G.GetAddOnEnableState

-- Core API
-- This mostly contains methods we always want available
-----------------------------------------------------------

-- Create the event frame
addon.eventFrame = CreateFrame("Frame", addonName .. "EventFrame", UIParent)

local version, build, build_date, toc_version = GetBuildInfo()

-- Let's create some constants for faster lookups
local MAJOR, MINOR, PATCH = string_split(".", version)
MAJOR = tonumber(MAJOR)

-- These are defined in FrameXML/BNet.lua
-- *Using blizzard constants if they exist,
-- using string parsing as a fallback.
addon.IsEra = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) or (MAJOR == 1)
addon.IsTBC = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC) or (MAJOR == 2)
addon.IsWrath = (WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC) or (MAJOR == 3)
addon.IsClassic = (addon.IsEra or addon.IsTBC or addon.IsWrath)
addon.IsRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE) or (MAJOR >= 10)
addon.WoW10 = toc_version >= 100002

-- Store major, minor and build.
addon.ClientMajor = MAJOR
addon.ClientMinor = tonumber(MINOR)
addon.ClientBuild = tonumber(build)

-- Set a relative subpath to look for media files in.
local Path
function addon:SetMediaPath(path)
    Path = path
end

-- Should mostly be used for debugging
function addon:Print(...)
    print("|cff33ff99" .. addonName .. ":|r", ...)
end

-- Simple API calls to retrieve a media file.
-- Will honor the relative subpath set above, if defined,
-- and will default to the addon folder itself if not.
-- Note that we cannot check for file or folder existence
-- from within the WoW API, so you must make sure this is correct.
function addon:GetMedia(name, type)
    if (Path) then
        return ([[Interface\AddOns\%s\%s\%s.%s]]):format(addonName, Path, name, type or "tga")
    else
        return ([[Interface\AddOns\%s\%s.%s]]):format(addonName, name, type or "tga")
    end
end

-- Parse chat input arguments
local parse = function(msg)
    msg = string_gsub(msg, "^%s+", "") -- Remove spaces at the start.
    msg = string_gsub(msg, "%s+$", "") -- Remove spaces at the end.
    msg = string_gsub(msg, "%s+", " ") -- Replace all space characters with single spaces.
    if (string_find(msg, "%s")) then
        return string_split(" ", msg) -- If multiple arguments exist, split them into separate return values.
    else
        return msg
    end
end

-- This methods lets you register a chat command, and a callback function or private method name.
-- Your callback will be called as callback(addon, editBox, commandName, ...) where (...) are all the input parameters.
--- Register a chat command under the addon name
---@param command string
---@param callback fun(addon: table, editBox: number, commandName: string, ...: string): nil
addon.RegisterChatCommand = function(command, callback)
    command = string_gsub(command, "^\\", "") -- Remove any backslash at the start.
    command = string.lower(command) -- Make it lowercase, keep it case-insensitive.
    local name = string.upper(addonName .. "_CHATCOMMAND_" .. command) -- Create a unique uppercase name for the command.
    _G["SLASH_" .. name .. "1"] = "/" .. command -- Register the chat command, keeping it lowercase.
    SlashCmdList[name] = function(msg, editBox)
        local func = addon[callback] or addon.OnChatCommand or callback
        if (func) then
            func(addon, editBox, command, parse(string.lower(msg)))
        end
    end
end

--- Loads information on an addon based on the index
---@param index number
---@return string name
---@return string title
---@return string notes
---@return boolean enabled
---@return boolean loadable
---@return string reason
---@return string security
function addon:GetAddOnInfo(index)
    local name, title, notes, loadable, reason, security, newVersion = GetAddOnInfo(index)
    local enabled = not (GetAddOnEnableState(UnitName("player"), index) == 0)
    return name, title, notes, enabled, loadable, reason, security
end

--- Check if an addon exists in the addon listing and loadable on demand
---@param target string Target addon name
---@param ignoreLoD boolean Ignore addon that are "Load on Demand"
---@return boolean
function addon:IsAddOnLoadable(target, ignoreLoD)
    local targetName = string.lower(target)
    for i = 1, GetNumAddOns() do
        local name, title, notes, enabled, loadable, reason, security = self:GetAddOnInfo(i)
        if string.lower(name) == targetName then
            if loadable or ignoreLoD then
                return true
            end
        end
    end
    return false
end

---This method lets you check if an addon WILL be loaded regardless of whether or not it currently is.
---This is useful if you want to check if an addon interacting with yours is enabled.
---My philosophy is that it's best to avoid addon dependencies in the toc file,
---unless your addon is a plugin to another addon, that is.
---@param target string Target addon's name
---@return boolean
function addon:IsAddOnEnabled(target)
    local targetName = string.lower(target)
    for i = 1, GetNumAddOns() do
        local name, title, notes, enabled, loadable, reason, security = self:GetAddOnInfo(i)
        if string.lower(name) == targetName then
            if enabled and loadable then
                return true
            end
        end
    end
    return false
end

-- Event API
-----------------------------------------------------------
-- Proxy event registering to the addon namespace.
-- The 'self' within these should refer to our proxy frame,
-- which has been passed to this environment method as the 'self'.
addon.RegisterEvent = function(_, ...) addon.eventFrame:RegisterEvent(...) end
addon.RegisterUnitEvent = function(_, ...) addon.eventFrame:RegisterUnitEvent(...) end
addon.UnregisterEvent = function(_, ...) addon.eventFrame:UnregisterEvent(...) end
addon.UnregisterAllEvents = function(_, ...) addon.eventFrame:UnregisterAllEvents(...) end
addon.IsEventRegistered = function(_, ...) addon.eventFrame:IsEventRegistered(...) end

-- Event Dispatcher and Initialization Handler
-----------------------------------------------------------
-- Assign our event script handler,
-- which runs our initialization methods,
-- and dispatches event to the addon namespace.
addon.eventFrame:RegisterEvent("ADDON_LOADED")
addon.eventFrame:SetScript("OnEvent", function(self, event, ...)
    if (event == "ADDON_LOADED") then
        -- Nothing happens before this has fired for your addon.
        -- When it fires, we remove the event listener
        -- and call our initialization method.
        if ((...) == addonName) then
            -- Delete our initial registration of this event.
            -- Note that you are free to re-register it in any of the
            -- addon namespace methods.
            addon.eventFrame:UnregisterEvent("ADDON_LOADED")
            -- Call the initialization method.
            if (addon.OnInit) then
                addon:OnInit()
            end
            -- If this was a load-on-demand addon, then we might be logged in already.
            -- If that is the case, directly run the enabling method.
            if (IsLoggedIn()) then
                if (addon.OnEnable) then
                    addon:OnEnable()
                end
            else
                -- If this is a regular always-load addon,
                -- we're not yet logged in, and must listen for this.
                addon.eventFrame:RegisterEvent("PLAYER_LOGIN")
            end
            -- Return. We do not wish to forward the loading event
            -- for our own addon to the namespace event handler.
            -- That is what the initialization method exists for.
            return
        end
    elseif (event == "PLAYER_LOGIN") then
        -- This event only ever fires once on a reload,
        -- and anything you wish done at this event,
        -- should be put in the namespace enable method.
        addon.eventFrame:UnregisterEvent("PLAYER_LOGIN")
        -- Call the enabling method.
        if (addon.OnEnable) then
            addon:OnEnable()
        end
        -- Return. We do not wish to forward this
        -- to the namespace event handler.
        return
    end
    -- Forward other events than our two initialization events
    -- to the addon namespace's event handler.
    -- Note that you can always register more ADDON_LOADED
    -- if you wish to listen for other addons loading.
    if (addon.OnEvent) then
        addon:OnEvent(event, ...)
    end
end)
