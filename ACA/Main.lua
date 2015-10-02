-- ****************************************************************************
-- ****************************************************************************
--
-- Alternative Combat Analyzer: This analyzer concentrates on approximating
-- how much damage was avoided. Unlike CA, we don't treat all hits equal.
--
-- ****************************************************************************
-- ****************************************************************************

debugging = true

-- ****************************************************************************
--
-- Planning: First we need combat event line processing. We need logging so
-- that we can use the same data several times.
--
-- ****************************************************************************

import "MaKoPlugins.Utils";
import "MaKoPlugins.ACA.Parser";

local utils   = MaKoPlugins.Utils
local _plugin = utils.PlugIn()

local println = utils.println
local INFO    = function(str) _plugin:INFO(str) end
local DEBUG   = function(str) _plugin:DEBUG(str) end
local xDEBUG  = function(str) _plugin:xDEBUG(str) end

-- ****************************************************************************

-- ----------------------------------------------------------------------------
-- Obtain & extending player info, ready for using
-- ----------------------------------------------------------------------------

local player  = Turbine.Gameplay.LocalPlayer:GetInstance();
-- local effects = player:GetEffects()

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
    Logging = {
        ["Enabled"] = false,
        ["Events"] = { }
    }
}

-- ----------------------------------------------------------------------------

Settings = Turbine.PluginData.Load(
		Turbine.DataScope.Character,
		"ACASettings"
	) or Settings;

--[[ -- Debugging
Settings.Logging = { 
    ["Enabled"] = true,
    ["Events"] = { }
}
-- ]]--

-- ----------------------------------------------------------------------------

local function SaveSettings()
	INFO("Saving settings...")
	Turbine.PluginData.Save(
		Turbine.DataScope.Character,
		"ACASettings",
		Settings
	)
end

-- _plugin:atexit(SaveSettings);

-- ****************************************************************************
-- ****************************************************************************
--
-- Analyzer database line
--
-- ****************************************************************************
-- ****************************************************************************

local CombatEvent = class()

function CombatEvent:Constructor(line)
	self.eventtype, self.actor, self.target, self.skill,
	    self.var1, self.var2, self.var3, self.var4 = parse(line)
end

-- ----------------------------------------------------------------------------

local function MessageReceived(sender, args)
    if  args.ChatType ~= Turbine.ChatType.PlayerCombat and
        args.ChatType ~= Turbine.ChatType.EnemyCombat then
        return
    end

    if Settings.Logging.Enabled then
        table.insert(Settings.Logging.Events, args.Message)
    end

    event = CombatEvent(args.Message)

end

-- ----------------------------------------------------------------------------

function ProcessLog()
    for k, line in pairs(Settings.Logging.Events) do
        local event = CombatEvent(line)
        if event.eventtype ~= nil then
            DEBUG(event.eventtype .. ": " .. event.actor .. " -> " .. event.target)
        end
    end
end

ProcessLog()

-- ----------------------------------------------------------------------------
-- Listbox for logged effects
-- ----------------------------------------------------------------------------

--[[
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
-- ]]--

-- ----------------------------------------------------------------------------

--[[
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
-- ]]--

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
-- Window to browse tracked effects
--
-- ****************************************************************************
-- ****************************************************************************

--[[
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

-- ]]--

-- ----------------------------------------------------------------------------
-- Layout elements
-- ----------------------------------------------------------------------------

--[[
function LogBrowser:SizeChanged(sender, args)
	loggedlist:SetPosition(20, 40);
	loggedlist:SetSize(self:GetWidth()-40, self:GetHeight()-80);
end
-- ]]--

-- ----------------------------------------------------------------------------
-- Save settings on unload
-- ----------------------------------------------------------------------------

--[[
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
-- ]]--

-- ----------------------------------------------------------------------------
-- Create window
-- ----------------------------------------------------------------------------

-- local mainwnd = LogBrowser()
-- _plugin:atexit(function() mainwnd:Unload() end)

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
		-- mainwnd:SetVisible( true );
		-- mainwnd:Refresh()
	elseif ( args == "hide" ) then
		-- mainwnd:SetVisible( false );
	elseif ( args == "toggle" ) then
		-- mainwnd:SetVisible( not mainwnd:IsVisible() );
		-- mainwnd:Refresh()
	else
		INFO("/aca [show | hide | toggle]")
	end
end

Turbine.Shell.AddCommand( "aca", myCMD );
_plugin:atexit(function() Turbine.Shell.RemoveCommand(myCMD) end)

INFO("/aca [show | hide | toggle]" )

-- ****************************************************************************
-- ****************************************************************************
--
-- Event hooks
--
-- ****************************************************************************
-- ****************************************************************************

local _hooks = {
	{ object = Turbine.Chat, event = "Received", callback = MessageReceived },
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
