-- ****************************************************************************
-- ****************************************************************************
--
-- Target manager: Plan is to get a plugin to help managing targets when
-- e.g. playing Loremaster.
--
-- ****************************************************************************
-- ****************************************************************************

-- ****************************************************************************
--
-- Import utils and bring some functions to local namespace
--
-- ****************************************************************************

import "MaKoPlugins.TargetManager.Bindings";

-- ****************************************************************************
-- ****************************************************************************
--
-- Settings: If you keep default settings separate (that is, not feeding
-- it directly to load method), you can fill up fields missing in the
-- settings file, for example when you add fields.
--
-- ****************************************************************************
-- ****************************************************************************

local DefaultSettings = {
	WindowPosition = {
		Left = 0,
		Top  = 0,
		Width = 200,
		Height = 200
	},
	WindowVisible = true,
}

local Settings = PlugIn:LoadSettings("TgtMgrSettings", DefaultSettings)

-- ****************************************************************************
-- ****************************************************************************
--
-- Main Window
--
-- ****************************************************************************
-- ****************************************************************************

MainWindow = class(Turbine.UI.Lotro.Window);

function MainWindow:Constructor()
	Turbine.UI.Lotro.Window.Constructor(self);

	-- ------------------------------------------------------------------------
	-- Window properties
	-- ------------------------------------------------------------------------

	self:SetText("Target Manager");

	self:SetResizable(true);

	-- ------------------------------------------------------------------------
	-- Place window
	-- ------------------------------------------------------------------------

	self:SetPosition(
		Settings.WindowPosition.Left,
		Settings.WindowPosition.Top
	)
	self:SetSize(
		Settings.WindowPosition.Width,
		Settings.WindowPosition.Height
	)

	-- ------------------------------------------------------------------------
	-- Window visibility on load: When plugin unload is called, window is
	-- already closed. So, we keep track of window show/hide, to be able
	-- store the visibility state before unloading.
	-- ------------------------------------------------------------------------

	self:SetVisible(Settings.WindowVisible);

    self.VisibleChanged = function(sender, args)
	    Settings.WindowVisible = self:IsVisible()
	end
end

-- ----------------------------------------------------------------------------
-- Layout elements
-- ----------------------------------------------------------------------------

function MainWindow:SizeChanged( sender, args )

end

-- ----------------------------------------------------------------------------
-- Save settings on unload
-- ----------------------------------------------------------------------------

function MainWindow:Unload()

	-- ------------------------------------------------------------------------
	-- Store window position & size
	-- ------------------------------------------------------------------------

	Settings.WindowPosition = {
	    Left = self:GetLeft(),
	    Top = self:GetTop(),
	    Height = self:GetHeight(),
	    Width = self:GetWidth()
	};

	-- ------------------------------------------------------------------------
	-- Save settings
	-- ------------------------------------------------------------------------

	PlugIn:SaveSettings("TgtMgrSettings", Settings)

end

-- ----------------------------------------------------------------------------
-- Create window
-- ----------------------------------------------------------------------------

local mainwnd = MainWindow()

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
	elseif ( args == "hide" ) then
		mainwnd:SetVisible( false );
	elseif ( args == "toggle" ) then
		mainwnd:SetVisible( not mainwnd:IsVisible() );
	else
		INFO("/%s [show | hide | toggle]", cmd)
	end
end

Turbine.Shell.AddCommand( "tgtmgr", _cmd );
atexit(function() Turbine.Shell.RemoveCommand(_cmd) end)

