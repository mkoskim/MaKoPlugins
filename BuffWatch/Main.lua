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

-- Idea:
--
-- - Have certain amounts of slots at screen
-- - Assign effects (buffs, debuffs) to each slot
-- - Maintain a database for effects, to be chosen to slots
--

-- ****************************************************************************

import "MaKoPlugins.Utils";

local utils   = MaKoPlugins.Utils
local _plugin = utils.PlugIn()

local println = utils.println
local INFO    = function(str) _plugin:INFO(str) end
local DEBUG   = function(str) _plugin:DEBUG(str) end
local xDEBUG  = function(str) _plugin:xDEBUG(str) end

-- ****************************************************************************

xDEBUG("Loading...");

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

local Settings = {
	WatchWindowPosition = {
		Left = 0,
		Top  = 0,
		Width = 200,
		Height = 200
	},
	WatchWindowVisible = true,
    WatchSlots = 5,
    WatchedEffects = {
    },
    Logging = {
        Enabled = true,
        Effects = { }
    },
}

Settings = Turbine.PluginData.Load(
		Turbine.DataScope.Character,
		"BuffWatchSettings"
	) or Settings;

-- --[[ -- Debugging
Settings.Logging = { 
    ["Enabled"] = true,
    ["Effects"] = { }
}
-- ]]--

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

local LoggedListBox = class(utils.ScrolledListBox)

function LoggedListBox:AddLogged(logged)
    DEBUG(string.format("Logged: %s", logged.name))
    self:AddItem(LoggedNode(logged))
end

function LoggedListBox:Constructor()
    utils.ScrolledListBox.Constructor(self)
    
    for k, v in pairs(Settings.Logging.Effects) do
        self:AddLogged(v)
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

function checkIfLogged(effect)
	if Settings.Logging.Enabled and Settings.Logging.Effects[name] == nil then
        local logged = LoggedEffect(effect)
        Settings.Logging.Effects[logged.name] = logged
        loggedlist:AddLogged(logged)
        DEBUG(string.format("Logged: %s", effect:GetName()))
    end
end

local function EffectAdded(effect)
	xDEBUG(string.format("Added [%s]: %s", tostring(effect), effect:GetName()))
	xDEBUG(string.format("%s", effect:GetID()))
	xDEBUG(string.format("%s", effect:GetDescription()))
	xDEBUG(string.format("%s", effect:GetCategory()))

    checkIfLogged(effect)
end

-- ----------------------------------------------------------------------------

local function EffectRemoved(effect)
	DEBUG(string.format("Removed [%s]: %s", tostring(effect), effect:GetName()))
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
-- Effect Watch Window: Watch window has specified number of slots to
-- show effects, so that certain effects always appear at specific location
-- in a screen. In future, we might have several different types of watch
-- windows.
--
-- ****************************************************************************
-- ****************************************************************************

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
-- Window to browse tracked effects
--
-- ****************************************************************************
-- ****************************************************************************

LogBrowser = class(Turbine.UI.Lotro.Window);

function LogBrowser:Constructor()
	Turbine.UI.Lotro.Window.Constructor(self);

	-- ------------------------------------------------------------------------
	-- Window properties
	-- ------------------------------------------------------------------------
	
	self:SetText("BuffWatch");
	
	-- self:SetMinimumWidth(310);
	-- self:SetMaximumWidth(310);
	-- self:SetMinimumHeight(250);
	
	-- ------------------------------------------------------------------------

	loggedlist:SetParent(self)

	-- ------------------------------------------------------------------------

	self:SetPosition(
		Settings.WatchWindowPosition.Left,
		Settings.WatchWindowPosition.Top
	)
	self:SetSize(
		310, -- Settings.WindowPosition.Width,
		Settings.WatchWindowPosition.Height
	)
	
	self:SetResizable(true);

	-- ------------------------------------------------------------------------

	RefreshEffects();

	-- ------------------------------------------------------------------------

	self:SetVisible(Settings.WindowVisible);
	-- self:SetVisible(true);
end

function LogBrowser:VisibleChanged(sender, args)
	-- Settings.WindowVisible = self:IsVisible()
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

	Settings.WatchWindowPosition.Left = self:GetLeft();
	Settings.WatchWindowPosition.Top = self:GetTop();
	Settings.WatchWindowPosition.Height = self:GetHeight();
	Settings.WatchWindowPosition.Width = self:GetWidth();	
	-- Settings.WindowVisible = self:IsVisible();

	-- ------------------------------------------------------------------------
	-- Save settings
	-- ------------------------------------------------------------------------

	Turbine.PluginData.Save(
		Turbine.DataScope.Character,
		"BuffWatchSettings",
		Settings
	)
	self:SetVisible( false );
end

-- ----------------------------------------------------------------------------
-- Create window
-- ----------------------------------------------------------------------------

local mainwnd = LogBrowser()
_plugin:atexit(function() mainwnd:Unload() end)

-- ****************************************************************************
-- ****************************************************************************
--
-- Command line interface
--
-- ****************************************************************************
-- ****************************************************************************

local myCMD = Turbine.ShellCommand();

function myCMD:Execute(cmd, args)
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

Turbine.Shell.AddCommand( "buffwatch", myCMD );
_plugin:atexit(function() Turbine.Shell.RemoveCommand(myCMD) end)

INFO("/buffwatch [show | hide | toggle]" )

-- ****************************************************************************
-- ****************************************************************************
--
-- Event hooks
--
-- ****************************************************************************
-- ****************************************************************************

local _hooks = {
	{ object = effects, event = "EffectAdded", callback = function(sender, args) EffectAdded(effects:Get(args.Index)) end },
	{ object = effects, event = "EffectRemoved", callback = function(sender, args) EffectRemoved(args.Effect) end },
	{ object = effects, event = "EffectCleared", callback = function(sender, args) EffectRemoved(args.Effect) end },
}

function InstallHooks()
	for i = 1, table.getn(_hooks) do
		if _hooks[i].object ~= nil then
			utils.AddCallback(_hooks[i].object, _hooks[i].event, _hooks[i].callback)
		end
	end
end

function UninstallHooks()
	for i = 1, table.getn(_hooks) do
		if _hooks[i].object ~= nil then
			utils.RemoveCallback(_hooks[i].object, _hooks[i].event, _hooks[i].callback)
		end
	end
end

InstallHooks()
_plugin:atexit(UninstallHooks)
