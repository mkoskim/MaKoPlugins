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
import "MaKoPlugins.ACA.Recording";

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
    }
}

-- ----------------------------------------------------------------------------

Settings = Turbine.PluginData.Load(
		Turbine.DataScope.Character,
		"ACASettings"
	) or Settings;

ProcessLog(Settings.Logging.Events)

totals = Walk(damageTaken, nil, nil, "Tamien")

--[[ **************************************************************************
-- ****************************************************************************

    What are we interested in?

    * We are interested about the estimated total amount of damage you would
      have taken, if you would not avoided anything

    * We are interested how much damage was negated by partial and full avoids

    * We are interested, how much partials have lowered crit rate

-- ****************************************************************************
-- ************************************************************************]]--

hits = totals:Hits()

partials = totals:Partials()
avoids   = totals:Avoids()
attempts = {
    ["count"] = totals.count,
    ["sum"] = totals.count * hits.average,
    ["average"] = hits.average
}

-- ----------------------------------------------------------------------------

println("- - -")
println("Summary..:")

println(".........: %6.2f%% - %6.2f%%",
    100.0 * (hits.sum + partials.sum) / attempts.sum,
    100.0 * (avoids.estimate + partials.estimate - partials.sum) / attempts.sum
)
println(".........: %6.2f%% - %6.2f%% / %6.2f%% - %6.2f%%",
    100.0 * hits.sum / attempts.sum,
    100.0 * partials.sum / attempts.sum,
    100.0 * (partials.estimate - partials.sum) / attempts.sum,
    100.0 * avoids.estimate / attempts.sum
)
println(".........: %6.2f%% - %6.2f%% - %6.2f%%",
    100.0 * hits.count / attempts.count,
    100.0 * partials.count / attempts.count,
    100.0 * avoids.count / attempts.count
)

--[[
-- ----------------------------------------------------------------------------

println("- - -")
noncrits   = totals:Summary(HitType.Regular)
crits      = totals:Summary(HitType.Critical)
devastates = totals:Summary(HitType.Devastate)
critdev    = totals:Summary(HitType.Critical, HitType.Devastate)

println("Crit&dev.: %8d %8d", critdev.count, critdev.sum)
println("- .......: %6.2f%% %6.2f%%",
    100.0 * critdev.count / hits.count,
    100.0 * critdev.sum / hits.sum
)
println("- Crit mgn: %6.2f%%", 100 * crits.average / noncrits.average)
println("- Dev mgn.: %6.2f%%", 100 * devastates.average / noncrits.average)

-- ]]--

-- ----------------------------------------------------------------------------

println("- - -")

println("Full avoids")

for _, key in pairs({HitType.Block, HitType.Parry, HitType.Evade, HitType.Resist}) do
    local summary = totals:Summary(key)
    println("- %-10s: %6.2f%% - %6.2f%%",
        HitTypeName[key],
        100 * summary.count / attempts.count,
        100 * summary.estimate / attempts.sum
    )
end

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

	-- self:SetVisible(Settings.WindowVisible);
	self:SetVisible(true);
end

function AnalyzerWindow:VisibleChanged(sender, args)
	-- Settings.WindowVisible = self:IsVisible()
end

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

function AnalyzerWindow:Unload()

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
		"ACASettings",
		Settings
	)
	self:SetVisible( false );
end

-- ----------------------------------------------------------------------------
-- Create window
-- ----------------------------------------------------------------------------

-- local mainwnd = AnalyzerWindow()
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
