-- ****************************************************************************
-- ****************************************************************************
--
-- BuffWatch: Track selected buffs at real time. This plugin has two parts:
-- (1) window to show tracked effects, to be used to choose the ones you
-- like to track, and (2) window to track selected effects.
--
-- ****************************************************************************
-- ****************************************************************************

debugging = true

-- ****************************************************************************
--
-- Idea:
--
-- - Have certain amounts of slots at screen
-- - Assign effects (buffs, debuffs) to each slot
-- - Maintain a database for effects, to be chosen to slots
--
-- ----------------------------------------------------------------------------
--
-- TODO:
-- - Slot editor
-- - GetSize() reports the original size, not stretched size
-- - Add Garan's debug interface when available
-- - Logs to separate, account-wide file: including defaults coming with
--   plugin
--
-- ----------------------------------------------------------------------------
--
-- DONE:
-- - DONE: Whole WatchWindow is stretched to get icons resized with text at top
-- - DONE: Timer for chosen effects

-- ****************************************************************************

import "MaKoPlugins.BuffWatch.Bindings"

-- ****************************************************************************

xDEBUG("Loading...");

import "MaKoPlugins.BuffWatch.Watch"

-- ----------------------------------------------------------------------------
-- Obtain & extending player info, ready for using
-- ----------------------------------------------------------------------------

local player  = Turbine.Gameplay.LocalPlayer:GetInstance();
local effects = player:GetEffects()

-- ****************************************************************************
-- ****************************************************************************
--
-- Plugin settings
--
-- ****************************************************************************
-- ****************************************************************************

local DefaultSettings = {
    LogWindow = {
        Left = 0,
        Top  = 0,
        Width = 200,
        Height = 200,
        Visible = true
    },
    WatchWindow = {
        Left = 0,
        Top  = 0,
        Width = 200,
        Height = 200,
        Visible = true
    },
    WatchedEffects = {
    },
    Logging = {
        Enabled = true,
        Effects = { }
    },
}

local Settings = PlugIn:LoadSettings("BuffWatchSettings", DefaultSettings)

-- ----------------------------------------------------------------------------
-- Converting old settings to new ones
-- ----------------------------------------------------------------------------

if Settings["SettingsVersion"] == nil then
    Settings = {
        LogWindow = {
            Left    = Settings.WindowPosition.Left,
            Top     = Settings.WindowPosition.Top,
            Width   = Settings.WindowPosition.Width,
            Height  = Settings.WindowPosition.Height,
            Visible = true,
        },

        WatchWindow = DefaultSettings.WatchWindow,
        WatchSlots = DefaultSettings.WatchSlots,
        WatchedEffects = DefaultSettings.WatchedEffects,

        Logging = Settings.Logging,
        SettingsVersion = 1,
    }
end

--[[ -- Debugging
Settings.Logging = { 
    ["Enabled"] = true,
    ["Effects"] = { }
}
-- ]]--

Settings.WatchedEffects = {
    {
        -- { name = "Defiance", icon = 1091830177 },
        { name = "Wall of Steel - Parry", icon = 1091471267 },
    },
    {
        { name = "Persevere Gambit Chain - Step 1", icon = 1091469964 },
        { name = "Finishing Blow - Persevere", icon = 1091830147 },
    },
    { },
    { { name = "Tier 2 Heal over Time", icon = 1091471259 } },
    { { name = "Tier 4 Heal over Time", icon = 1091471247 } },
    { { name = "Conviction", icon = 1091478183 } },
    { { name = "Never Surrender", icon = 1091682153 } },
    {
        { name = "Tactically Sound Immunity", icon = 1090541176 },
        { name = "Tactically Sound", icon = 1090541176 },
        { name = "Temporary State Immunity", icon = 1091423618 },
        { name = "Daze and Stun Immunity", icon = 1091423617 },
        { name = "Recovering", icon = 1091466886 },
        { name = "Stunned", icon = 1090552383 },
        { name = "Knocked Down", icon = 1090552383 },
        { name = "Dazed", icon = 1091404640 },
    },
}

-- ****************************************************************************
-- ****************************************************************************
--
-- Effect Watch Window: Watch window has specified number of slots to
-- show effects, so that certain effects always appear at specific location
-- in a screen. In future, we might have several different types of watch
-- windows.
--
-- ****************************************************************************
-- ****************************************************************************

WatchWindow = class(Utils.UI.Window.Draggable)

function WatchWindow:Constructor()
    Utils.UI.Window.Draggable.Constructor(self);

    -- ------------------------------------------------------------------------

    self:SetText("BuffWatch");

    -- ------------------------------------------------------------------------

    local size = 24
    local numSlots = #Settings.WatchedEffects
    self.slots = watchslots

    self:SetSize(36 * numSlots, 36)
    self:SetStretchMode(1)

    for col=1,numSlots do 

        local background = Turbine.UI.Control()
        background:SetParent(self)
        background:SetPosition((34 + 2) * (col-1), 1)
        background:SetSize(34, 34)
        background:SetBackColor(Turbine.UI.Color(0.75, 0.15, 0.15, 0.15))
        background:SetVisible(true)
    
        local effects = Settings.WatchedEffects[col]
        for index=1, #effects do
            local slot = WatchSlot(effects[index].icon)
            slot:SetParent(self)
            slot:SetPosition((34 + 2) * (col-1) + 1, 1)
            slot:SetSize(32, 32)
            slot:SetEffect(nil)
            slot:SetVisible(false)
            -- slot:SetText(tostring(col))

            self.slots[effects[index].name] = slot
        end
    end
    
    -- ------------------------------------------------------------------------

    self:Deserialize(Settings.WatchWindow)
    self:SetSize(numSlots * size, size);
    xDEBUG("%d x %d = %d x %d", numSlots*size, size, self:GetWidth(), self:GetHeight())
end

-- ****************************************************************************
-- ****************************************************************************
--
-- Effect logging: gather information from all buffs and debuffs a character
-- has met on his travels, to be shown and chosen to be tracked.
--
-- ****************************************************************************
-- ****************************************************************************

local LoggedEffect = class()

function LoggedEffect:Constructor(effect)
    self.name = effect:GetName()
    self.icon = effect:GetIcon()
    self.category = effect:GetCategory()
    self.isDebuff = effect:IsDebuff()
    self.isCurable = effect:IsCurable()
    self.description = effect:GetDescription()
end

-- ----------------------------------------------------------------------------
-- Listbox for logged effects
-- ----------------------------------------------------------------------------

local LoggedNode = class(Turbine.UI.Control)

function LoggedNode:Constructor(logged)
    Turbine.UI.Control.Constructor(self);

    self.effect = logged

    self:SetSize(200, 34)

    self.icon = Turbine.UI.Control()
    self.icon:SetParent(self);
    self.icon:SetBackground( self.effect.icon );
    self.icon:SetSize(32, 32);

    self.name = Turbine.UI.Label();
    self.name:SetParent( self );
    self.name:SetLeft(34 + 5);
    self.name:SetSize( 200 - 34 - 5, 34 );
    self.name:SetTextAlignment( Turbine.UI.ContentAlignment.MiddleLeft );
    self.name:SetText( self.effect.name );
end

-- ----------------------------------------------------------------------------

local LoggedListBox = class(Utils.UI.ScrolledListBox)

function LoggedListBox:AddLogged(logged)
    xDEBUG(string.format("Logged: %s", logged.name))
    self:AddItem(LoggedNode(logged))
end

function LoggedListBox:Constructor()
    Utils.UI.ScrolledListBox.Constructor(self)
    
    for _, buff in pairs(Settings.Logging.Effects) do
        for _, category in pairs(buff) do
            for _, effect in pairs(category) do
                self:AddLogged(effect)
            end
        end
    end
end

local loggedlist = LoggedListBox()

-- ****************************************************************************
-- ****************************************************************************
--
-- Effect hooks: these are called separately to all individual effects,
-- for example, Warden's Defiant Challenge's effect 'Defiance' is called
-- up to five times.
--
-- ****************************************************************************
-- ****************************************************************************

function isLogged(effect)
    local log = Settings.Logging.Effects

    if log[effect:IsDebuff()] == nil then
        log[effect:IsDebuff()] = {}
    end
    if log[effect:IsDebuff()][effect:GetCategory()] == nil then
        log[effect:IsDebuff()][effect:GetCategory()] = {}
    end
    
    return Settings.Logging.Effects[effect:IsDebuff()][effect:GetCategory()][effect:GetName()] ~= nil
end

function checkIfLogged(effect)

    if Settings.Logging.Enabled and not isLogged(effect) then
        local logged = LoggedEffect(effect)
        Settings.Logging.Effects[logged.isDebuff][logged.category][logged.name] = logged
        loggedlist:AddLogged(logged)
        DEBUG(string.format("Logged: %s", effect:GetName()))
    end
end

local function EffectAdded(effect)
    local name = effect:GetName()

    xDEBUG(string.format("Added [%s]: %s", tostring(effect), name))
    xDEBUG(string.format("%s", effect:GetID()))
    xDEBUG(string.format("%s", effect:GetDescription()))
    xDEBUG(string.format("%s", effect:GetCategory()))

    checkIfLogged(effect)

    local slot = watchslots[name];
    if slot ~= nil then
        xDEBUG("Slot %s: added %s", tostring(slot), name)
        slot:SetEffect(effect)
    end
end

-- ----------------------------------------------------------------------------

local function EffectRemoved(effect)
    local name = effect:GetName()
    
    xDEBUG(string.format("Removed [%s]: %s", tostring(effect), name))

    local slot = watchslots[name];
    if slot ~= nil then
        xDEBUG("Slot %s: removed %s", tostring(slot), name)
        if slot:GetEffect() == effect then
            slot:SetEffect(nil)
        end
    end
end

-- ----------------------------------------------------------------------------

local function RefreshEffects()
    for i = 1, effects:GetCount() do
        EffectAdded(effects:Get(i))
        effect = effects:Get(i)
    end
end

-- ****************************************************************************
-- ****************************************************************************
--
-- 
--
-- ****************************************************************************
-- ****************************************************************************

-- ****************************************************************************
-- ****************************************************************************
--
-- Window to browse logged effects
--
-- ****************************************************************************
-- ****************************************************************************

-- ----------------------------------------------------------------------------

LogBrowser = class(Utils.UI.Window);

function LogBrowser:Constructor()
    Utils.UI.Window.Constructor(self);

    self.watchwnd = WatchWindow()

    -- ------------------------------------------------------------------------
    -- Window properties
    -- ------------------------------------------------------------------------
    
    self:SetText("Logged Effects");

    -- self:SetMinimumWidth(310);
    -- self:SetMaximumWidth(310);
    -- self:SetMinimumHeight(250);
    
    -- ------------------------------------------------------------------------

    loggedlist:SetParent(self)

    -- ------------------------------------------------------------------------

    self:SetResizable(true);

    -- ------------------------------------------------------------------------

    RefreshEffects();

    -- ------------------------------------------------------------------------

    self:Deserialize(Settings.LogWindow)
end

-- ----------------------------------------------------------------------------
-- Layout elements
-- ----------------------------------------------------------------------------

function LogBrowser:SizeChanged(sender, args)
    loggedlist:SetPosition(20, 40);
    loggedlist:SetSize(self:GetWidth()-40, self:GetHeight()-80);
end

-- ----------------------------------------------------------------------------
-- Save settings on unload
-- ----------------------------------------------------------------------------

function LogBrowser:Unload()

    -- ------------------------------------------------------------------------
    -- Store window position & size
    -- ------------------------------------------------------------------------

    Settings.LogWindow = self:Serialize()
    Settings.WatchWindow = self.watchwnd:Serialize()

    -- ------------------------------------------------------------------------
    -- Save settings
    -- ------------------------------------------------------------------------

    PlugIn:SaveSettings("BuffWatchSettings", Settings)
end

-- ----------------------------------------------------------------------------
-- Create window
-- ----------------------------------------------------------------------------

local mainwnd = LogBrowser()
atexit(function() mainwnd:Unload() end)

-- ****************************************************************************
-- ****************************************************************************
--
-- Command line interface
--
-- ****************************************************************************
-- ****************************************************************************

local _cmd = Turbine.ShellCommand();

function _cmd:Execute(cmd, args)
	if ( args == "show" ) then
		mainwnd:SetVisible( true );
		-- mainwnd:Refresh()
	elseif ( args == "hide" ) then
		mainwnd:SetVisible( false );
	elseif ( args == "toggle" ) then
		mainwnd:SetVisible( not mainwnd:IsVisible() );
		-- mainwnd:Refresh()
	else
		INFO("/buffwatch [show | hide | toggle]")
	end
end

Turbine.Shell.AddCommand( "buffwatch", _cmd)
_cmd:Execute("buffwatch")
atexit(function() Turbine.Shell.RemoveCommand(_cmd) end)

-- ****************************************************************************
-- ****************************************************************************
--
-- Event hooks
--
-- ****************************************************************************
-- ****************************************************************************

local hooks = HookTable({
	{ object = effects, event = "EffectAdded", callback = function(sender, args) EffectAdded(effects:Get(args.Index)) end },
	{ object = effects, event = "EffectRemoved", callback = function(sender, args) EffectRemoved(args.Effect) end },
	{ object = effects, event = "EffectCleared", callback = function(sender, args) EffectRemoved(args.Effect) end },
})

hooks:Install()
atexit(function() hooks:Uninstall() end)

