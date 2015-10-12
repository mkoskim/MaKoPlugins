-- ****************************************************************************
-- ****************************************************************************
--
-- Build swapper
--
-- ----------------------------------------------------------------------------
--
-- API restrictions:
--
-- * Cannot create shortcuts from items automatically, so can't populate
--   quickslots.
--
-- ****************************************************************************
-- ****************************************************************************

import "MaKoPlugins.BuildSwap.Bindings"

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

local Settings = PlugIn:LoadSettings("BuildSwapSettings", DefaultSettings)

-- ----------------------------------------------------------------------------
-- Obtain & extending player info, ready for using
-- ----------------------------------------------------------------------------

local player  = Turbine.Gameplay.LocalPlayer:GetInstance();
local equip   = player:GetEquipment()

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

	self:SetText("Build Swapper");

	self:SetResizable(true);

	-- ------------------------------------------------------------------------
    -- Slots in single list for easy access
	-- ------------------------------------------------------------------------
    
    self.slots = {
        Head     = Utils.UI.EquipmentSlot(Turbine.Gameplay.Equipment.Head),
        Shoulder = Utils.UI.EquipmentSlot(Turbine.Gameplay.Equipment.Shoulder),
        Back     = Utils.UI.EquipmentSlot(Turbine.Gameplay.Equipment.Back),
        Chest    = Utils.UI.EquipmentSlot(Turbine.Gameplay.Equipment.Chest),
        Hands    = Utils.UI.EquipmentSlot(Turbine.Gameplay.Equipment.Gloves),
        Legs     = Utils.UI.EquipmentSlot(Turbine.Gameplay.Equipment.Legs),
        Boots    = Utils.UI.EquipmentSlot(Turbine.Gameplay.Equipment.Boots),

        Ear1      = Utils.UI.EquipmentSlot(Turbine.Gameplay.Equipment.Earring1),
        Ear2      = Utils.UI.EquipmentSlot(Turbine.Gameplay.Equipment.Earring2),
        Neck      = Utils.UI.EquipmentSlot(Turbine.Gameplay.Equipment.Necklace),
        Bracelet1 = Utils.UI.EquipmentSlot(Turbine.Gameplay.Equipment.Bracelet1),
        Bracelet2 = Utils.UI.EquipmentSlot(Turbine.Gameplay.Equipment.Bracelet2),
        Ring1     = Utils.UI.EquipmentSlot(Turbine.Gameplay.Equipment.Ring1),
        Ring2     = Utils.UI.EquipmentSlot(Turbine.Gameplay.Equipment.Ring2),
        Pocket    = Utils.UI.EquipmentSlot(Turbine.Gameplay.Equipment.Pocket),

        MainHand  = Utils.UI.EquipmentSlot(Turbine.Gameplay.Equipment.PrimaryWeapon),
        OffHand   = Utils.UI.EquipmentSlot(Turbine.Gameplay.Equipment.SecondaryWeapon),
        Ranged    = Utils.UI.EquipmentSlot(Turbine.Gameplay.Equipment.RangedWeapon),
        Class     = Utils.UI.EquipmentSlot(Turbine.Gameplay.Equipment.Class)
    }

	-- ------------------------------------------------------------------------
    -- Layouting elements to screen, approximately following the layout when
    -- inspecting.
	-- ------------------------------------------------------------------------

    self.content = Utils.UI.Layout.Vertical(
        Utils.UI.Layout.Horizontal(
            Utils.UI.Layout.Vertical(
                self.slots.Ear1,
                self.slots.Neck,
                self.slots.Bracelet1,
                self.slots.Ring1
            ),
            Utils.UI.Layout.Vertical(
                self.slots.Ear2,
                self.slots.Pocket,
                self.slots.Bracelet2,
                self.slots.Ring2
            ),
            Utils.UI.Layout.Vertical(
                self.slots.Head,
                self.slots.Chest,
                self.slots.Hands,
                self.slots.Legs
            ),
            Utils.UI.Layout.Vertical(
                self.slots.Shoulder,
                self.slots.Back,
                Utils.UI.EquipmentSlot(nil),
                self.slots.Boots
            )
        ),
        Utils.UI.Layout.Horizontal(
            self.slots.MainHand,
            self.slots.OffHand,
            self.slots.Ranged,
            self.slots.Class
        ),
        Utils.UI.Layout.Horizontal(
            function()
                local button = Turbine.UI.Lotro.Button()
                button:SetSize(80, 20)
                button:SetText("Fill")
                button.MouseClick = function()
                    -- Utils.Unequip(Turbine.Gameplay.Equipment.Chest)
                    self:Fill()
                end
                return button
            end
        )
    )

    self.content:SetParent(self)
    self.content:SetPosition(20, 40)

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

	-- self:SetVisible(Settings.WindowVisible);
	self:SetVisible(true);

    self.VisibleChanged = function(sender, args)
	    Settings.WindowVisible = self:IsVisible()
	end
end

-- ----------------------------------------------------------------------------
-- Layout elements
-- ----------------------------------------------------------------------------

function MainWindow:SizeChanged(args)
    self.content:SetSize(
        self:GetWidth() - 40,
        self:GetHeight() - 60
    )
end

-- ----------------------------------------------------------------------------
-- Fill slots from equipments
-- ----------------------------------------------------------------------------

function MainWindow:Fill()
    for _, slot in pairs(self.slots) do
        equipped = equip:GetItem(slot.slot)
        slot:SetItem(equipped)
    end
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

	PlugIn:SaveSettings("BuildSwapSettings", Settings)

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

Turbine.Shell.AddCommand( "buildswap", _cmd );
atexit(function() Turbine.Shell.RemoveCommand(_cmd) end)

