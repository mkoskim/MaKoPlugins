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

-- ----------------------------------------------------------------------------

local player = Turbine.Gameplay.LocalPlayer:GetInstance();

-- ****************************************************************************

TargetWidget = class(Turbine.UI.Control)

function TargetWidget:Constructor()
    Turbine.UI.Control.Constructor(self)

    self:SetMouseVisible(false)

    self.entity = Turbine.UI.Lotro.EntityControl()
    self.entity:SetParent(self)
    self.entity:SetSelectionEnabled(true)
    self.entity:SetMouseVisible(true)
    self.entity:SetBackColor(Turbine.UI.Color.Blue)
    --[[
    self.entity:SetContextMenuEnabled(true)
    ]]--
    self.entity.MouseClick = function()
        DEBUG("Clicked!")
    end

    self.label = Turbine.UI.Label()
    self.label:SetParent(self)
    self.label:SetMouseVisible(false)
    self.label:SetMultiline(false)

    self:SetTarget(nil)
end

function TargetWidget:SizeChanged()
    self.label:SetSize(self:GetWidth() - 20, self:GetHeight())
    self.entity:SetSize(self:GetWidth() - 20, self:GetHeight())
    --[[
    self.entity:SetPosition(self:GetWidth() - 20, 0)
    self.entity:SetSize(20, self:GetHeight())
    ]]--
end

function TargetWidget:SetTarget(entity)
    if entity ~= nil then
        self.label:SetText(entity:GetName())
    else
        self.label:SetText("- - -")
    end
    self.entity:SetEntity(entity)
end

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
	-- 
	-- ------------------------------------------------------------------------

    self.target = TargetWidget()
    self.target:SetParent(self)
    self.target:SetPosition(20, 40)
    self.target:SetSize(200, 20)

    self.target.MouseClick = function(sender, args)
        DEBUG("Clicked!")
    end

    -- player.TargetChanged = function(sender, args)
        -- self.targetlabel:SetText(player:GetTarget():GetName())
    -- end

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
	if (args == "show") then
		mainwnd:SetVisible( true );
	elseif (args == "hide") then
		mainwnd:SetVisible( false );
	elseif (args == "toggle") then
		mainwnd:SetVisible( not mainwnd:IsVisible() );
    elseif (args == "store") then
        mainwnd.target:SetTarget(player:GetTarget())
    elseif (args == "pick") then
        -- player:SetTarget(mainwnd.target.object)
	else
		INFO("/%s [show | hide | toggle]", cmd)
	end
end

Turbine.Shell.AddCommand( "tgtmgr", _cmd );
atexit(function() Turbine.Shell.RemoveCommand(_cmd) end)

