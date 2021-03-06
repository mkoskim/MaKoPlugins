-- ****************************************************************************
-- ****************************************************************************
--
-- Plugin main template
--
-- ****************************************************************************
-- ****************************************************************************

import "MaKoPlugins.SlotBag.Bindings"

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

local Settings = PlugIn:LoadSettings("SlotBagSettings", DefaultSettings)

-- ****************************************************************************
-- ****************************************************************************
--
-- Main Window
--
-- ****************************************************************************
-- ****************************************************************************

MainWindow = class(Utils.UI.Window);

function MainWindow:Constructor()
	Utils.UI.Window.Constructor(self);

	-- ------------------------------------------------------------------------
	-- Window properties
	-- ------------------------------------------------------------------------

	self:SetText("SlotBag");

	self:SetResizable(true);

	-- ------------------------------------------------------------------------

    self.grid = Utils.UI.Quickslot.Grid()
    self.grid:SetParent(self)
    self.grid:SetPosition(20, 30)
    -- self.grid:SetSize(200, 200)

    --[[
    self.slot = Utils.UI.Ext.LabelledQuickslot()
    self.slot:SetParent(self)
    self.slot:SetPosition(20, 40)
    self.slot:SetSize(200, 40)

    self.clickbox = Utils.UI.IconButton(
        -- Utils.UI.Bitmap.Edit.Start
        -- Utils.UI.Bitmap.Edit.Accept
        -- Utils.UI.Bitmap.Edit.Cancel
        -- Utils.UI.Bitmap.Lock.Open
        Utils.UI.Icons.Lock.Closed
    )
    self.clickbox:SetParent(self)
    self.clickbox:SetSize(16, 16)
    self.clickbox:SetPosition(20, 90)
    ]]--

	-- ------------------------------------------------------------------------
	-- Place window
	-- ------------------------------------------------------------------------

	self:SetPosition(
		Settings.WindowPosition.Left,
		Settings.WindowPosition.Top
	)
	self:SetSize(
		310, -- Settings.WindowPosition.Width,
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

function MainWindow:SizeChanged( args )
    self.grid:SetSize(
        self:GetWidth()  - 20 - 20,
        self:GetHeight() - 30 - 20
    )
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

	PlugIn:SaveSettings("SlotBagSettings", Settings)

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

Turbine.Shell.AddCommand( "slotbag", _cmd );
atexit(function() Turbine.Shell.RemoveCommand(_cmd) end)

