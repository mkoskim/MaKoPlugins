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
	WindowPosition = {
		Left = 0,
		Top  = 0,
		Width = 200,
		Height = 200
	},
	WindowVisible = true,
    LoggedEffects = {
    },
}

Settings = Turbine.PluginData.Load(
		Turbine.DataScope.Character,
		"BuffWatchSettings"
	) or Settings;

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

-- ****************************************************************************
-- ****************************************************************************
--
-- Logged effect viewer
--
-- ****************************************************************************
-- ****************************************************************************

local effectlist = utils.ScrolledListBox()

-- ----------------------------------------------------------------------------

local EffectNode = class(Turbine.UI.Control)

function EffectNode:Constructor(effect)
	Turbine.UI.Control.Constructor(self);

	self.name = effect:GetName()
	self.icon = effect:GetIcon()

	self:SetSize(200, 34)

	-- self.iconWidget = Turbine.UI.Lotro.EffectDisplay()
	self.iconWidget = Turbine.UI.Control()
	self.iconWidget:SetParent(self);
	self.iconWidget:SetSize(32,32)
	self.iconWidget:SetBackground( self.icon );
	-- self.iconWidget:SetEffect(effect);

	self.nameWidget = Turbine.UI.Label();
	self.nameWidget:SetParent( self );
	self.nameWidget:SetLeft(34 + 5);
	self.nameWidget:SetSize( 200 - 34 - 5, 34 );
	self.nameWidget:SetTextAlignment( Turbine.UI.ContentAlignment.MiddleLeft );
	self.nameWidget:SetText( self.name );
	
	effectlist:AddItem(self)
end

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
	if not Settings.LoggedEffects[name] == nil then
	    return
	end

    Settings.LoggedEffects[effect:GetName()] = LoggedEffect(effect)
end

local function EffectAdded(effect)
	DEBUG(string.format("Added [%s]: %s", tostring(effect), effect:GetName()))
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
-- 
--
-- ****************************************************************************
-- ****************************************************************************

-- ----------------------------------------------------------------------------
-- Constants
-- ----------------------------------------------------------------------------

local IconExpand = 0x41007E27; -- 16x16
local IconCollapse = 0x41007E26; -- 16x16
local HeaderBackground = 0x411105A6; -- 9x16

local bgColor = Turbine.UI.Color( 0, 0, 0);
local focusColor = Turbine.UI.Color(1, 0.15, 0.15, 0.15);

-- ****************************************************************************
-- ****************************************************************************
--
-- Window to browse tracked effects
--
-- ****************************************************************************
-- ****************************************************************************

BuffBrowser = class(Turbine.UI.Lotro.Window);

function BuffBrowser:Constructor()
	Turbine.UI.Lotro.Window.Constructor(self);

	-- ------------------------------------------------------------------------
	-- Window properties
	-- ------------------------------------------------------------------------
	
	self:SetText("BuffWatch");
	
	-- self:SetMinimumWidth(310);
	-- self:SetMaximumWidth(310);
	-- self:SetMinimumHeight(250);
	
	-- ------------------------------------------------------------------------

	effectlist:SetParent(self);
	effectlist.scrollbar:SetParent(self);
	
	-- ------------------------------------------------------------------------

	self:SetPosition(
		Settings.WindowPosition.Left,
		Settings.WindowPosition.Top
	)
	self:SetSize(
		310, -- Settings.WindowPosition.Width,
		Settings.WindowPosition.Height
	)
	
	self:SetResizable(true);

	-- ------------------------------------------------------------------------

	RefreshEffects();

	-- ------------------------------------------------------------------------

	-- self:SetVisible(Settings.WindowVisible);
	self:SetVisible(true);
end

function BuffBrowser:VisibleChanged(sender, args)
	Settings.WindowVisible = self:IsVisible()
end

-- ----------------------------------------------------------------------------
-- Layout elements
-- ----------------------------------------------------------------------------

function BuffBrowser:SizeChanged(sender, args)
	effectlist:SetPosition(20, 40);
	effectlist:SetSize(self:GetWidth()-40, self:GetHeight()-80);
	-- effectlist:SizeChanged(sender, args)
end

-- ----------------------------------------------------------------------------
-- Save settings on unload
-- ----------------------------------------------------------------------------

function BuffBrowser:Unload()

	-- ------------------------------------------------------------------------
	-- Store window position & size
	-- ------------------------------------------------------------------------

	Settings.WindowPosition.Left = self:GetLeft();
	Settings.WindowPosition.Top = self:GetTop();
	Settings.WindowPosition.Height = self:GetHeight();
	Settings.WindowPosition.Width = self:GetWidth();	
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

local mainwnd = BuffBrowser()
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
		mainwnd:Refresh()
	elseif ( args == "hide" ) then
		mainwnd:SetVisible( false );
	elseif ( args == "toggle" ) then
		mainwnd:SetVisible( not mainwnd:IsVisible() );
		mainwnd:Refresh()
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
