-- ****************************************************************************
-- ****************************************************************************
--
-- Alternative Combat Analyzer: This analyzer concentrates on approximating
-- how much damage was avoided. Unlike CA, we don't treat all hits equal.
--
-- ****************************************************************************
-- ****************************************************************************

debugging = true

-- ----------------------------------------------------------------------------

import "MaKoPlugins.Utils";

local utils   = MaKoPlugins.Utils
local _plugin = utils.PlugIn()

local println = utils.println
local INFO    = function(str) _plugin:INFO(str) end
local DEBUG   = function(str) _plugin:DEBUG(str) end
local xDEBUG  = function(str) _plugin:xDEBUG(str) end

-- ----------------------------------------------------------------------------

import "MaKoPlugins.ACA.Recording";
import "MaKoPlugins.ACA.RecordView";

-- ****************************************************************************
-- ****************************************************************************

-- ----------------------------------------------------------------------------
-- Obtain & extending player info, ready for using
-- ----------------------------------------------------------------------------

player  = Turbine.Gameplay.LocalPlayer:GetInstance();
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
    },
    ExpandedDamageRecordGroups = { },
}

-- ----------------------------------------------------------------------------

Settings = Turbine.PluginData.Load(
		Turbine.DataScope.Character,
		"ACASettings"
	) or Settings;

-- ****************************************************************************
-- ****************************************************************************
--
-- UI
--
-- ****************************************************************************
-- ****************************************************************************

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
-- Analyzer Window
--
-- ****************************************************************************
-- ****************************************************************************

AnalyzerWindow = class(Turbine.UI.Lotro.Window);

function AnalyzerWindow:Constructor()
	Turbine.UI.Lotro.Window.Constructor(self);

	-- ------------------------------------------------------------------------
	-- Window properties
	-- ------------------------------------------------------------------------

	self:SetText("Analyzer");

	-- self:SetMinimumWidth(310);
	-- self:SetMaximumWidth(310);
	-- self:SetMinimumHeight(250);

	-- ------------------------------------------------------------------------

    self.recordview = RecordView()
    self.recordview:SetParent(self)
    self.recordview:SetPosition(20, 40)
    -- self.recordview:SetSize(200, self:GetHeight() - 2*40)

    self.recordview:Expand(Settings.ExpandedDamageRecordGroups) 

	-- ------------------------------------------------------------------------

	self:SetPosition(
		Settings.WindowPosition.Left,
		Settings.WindowPosition.Top
	)
	self:SetSize(
		Settings.WindowPosition.Width,
		Settings.WindowPosition.Height
	)

	self:SetResizable(true);

	-- ------------------------------------------------------------------------

	self:SetVisible(Settings.WindowVisible);
	-- self:SetVisible(true);
end

function AnalyzerWindow:VisibleChanged(sender, args)
	Settings.WindowVisible = self:IsVisible()
end

function AnalyzerWindow:SetRecord(record)
    self.recordview:SetRecord(record)
end

-- ----------------------------------------------------------------------------
-- Layout elements
-- ----------------------------------------------------------------------------

function AnalyzerWindow:SizeChanged(sender, args)
	-- loggedlist:SetPosition(20, 40);
	self.recordview:SetSize(270, self:GetHeight() - 2*40);
end

-- ----------------------------------------------------------------------------
-- Save settings on unload
-- ----------------------------------------------------------------------------

function AnalyzerWindow:Unload()

	-- ------------------------------------------------------------------------
	-- Store window position & size
	-- ------------------------------------------------------------------------

	Settings.WindowPosition.Left = self:GetLeft();
	Settings.WindowPosition.Top = self:GetTop();
	Settings.WindowPosition.Height = self:GetHeight();
	Settings.WindowPosition.Width = self:GetWidth();

	Settings.ExpandedDamageRecordGroups = self.recordview:ExpandedGroups()

	-- ------------------------------------------------------------------------
	-- Save settings
	-- ------------------------------------------------------------------------

	Turbine.PluginData.Save(
		Turbine.DataScope.Character,
		"ACASettings",
		Settings
	)
	self:SetVisible( false );
end

-- ----------------------------------------------------------------------------
-- Create window
-- ----------------------------------------------------------------------------

local mainwnd = AnalyzerWindow()
_plugin:atexit(function() mainwnd:Unload() end)

ProcessLog(Settings.Logging.Events)
mainwnd:SetRecord(MergeDamage(nil, nil, { ["Tamien"] = 1 }))

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
		INFO("/aca [show | hide | toggle]")
	end
end

Turbine.Shell.AddCommand( "aca", myCMD );
_plugin:atexit(function() Turbine.Shell.RemoveCommand(myCMD) end)

INFO("/aca [show | hide | toggle]" )

