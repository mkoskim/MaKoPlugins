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
import "MaKoPlugins.ACA.DamageRecordView";
import "MaKoPlugins.ACA.SkillView";

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

	-- ------------------------------------------------------------------------

    self.recordview = RecordView()
    self.recordview:SetParent(self)

    self.recordview:Expand(Settings.ExpandedDamageRecordGroups) 

    self.skillview = SkillView()
    self.skillview:SetParent(self)

	-- ------------------------------------------------------------------------

	self:SetMinimumWidth(300 + 5 + 270 + 40);
	self:SetMinimumHeight(250);

	-- self:SetMaximumWidth(310);

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

-- ----------------------------------------------------------------------------
-- Layout elements
-- ----------------------------------------------------------------------------

function AnalyzerWindow:SizeChanged(sender, args)
    self.skillview:SetPosition(20, 40)
    self.skillview:SetSize(300, self:GetHeight() - (40 + 30))
    self.skillview:SizeChanged(sender, args)

    self.recordview:SetPosition(self:GetWidth() - (270 + 20), 40)
    self.recordview:SetSize(270, self:GetHeight() - (40 + 30))
    self.recordview:SizeChanged(sender, args)
end

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------

function AnalyzerWindow:VisibleChanged(sender, args)
	Settings.WindowVisible = self:IsVisible()
end

function AnalyzerWindow:SetRecord(record)
    self.recordview:SetRecord(record)
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

utils.showfields(DamageDealers({ ["Tamien"] = 1 }))

-- mainwnd:SetRecord(MergeDamage(nil, nil, { ["Tamien"] = 1 }))
-- mainwnd:SetRecord(MergeDamage({ ["Tamien"] = 1 }, nil, nil))

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

