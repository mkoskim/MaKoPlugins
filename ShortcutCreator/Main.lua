-- ****************************************************************************
-- ****************************************************************************
--
-- Simple shortcut creator helper
--
-- ****************************************************************************
-- ****************************************************************************

import "MaKoPlugins.ShortcutCreator.Bindings";

-- ----------------------------------------------------------------------------
-- Create window
-- ----------------------------------------------------------------------------

ShortcutPanel = class(Turbine.UI.Control)

function ShortcutPanel:Constructor()

	Turbine.UI.Control.Constructor(self)

    -- ------------------------------------------------------------------------

    self:SetSize(200, 200)

    -- ------------------------------------------------------------------------

    self.textbox = Utils.UI.ScrolledTextBox()
    self.textbox:SetParent(self)
    self.textbox:SetMultiline(true)
    self.textbox:SetSelectable(true)
    self.textbox:SetReadOnly(false)

    -- ------------------------------------------------------------------------

	self.quickslot = Utils.UI.Quickslot();
	self.quickslot:SetParent( self );

    self.createbtn = Turbine.UI.Lotro.Button()
	self.createbtn:SetParent( self );
    self.createbtn:SetText("Create")
    self.createbtn.MouseClick = function(sender, args)
        self.quickslot:SetShortcut(Turbine.UI.Lotro.Shortcut(
            Turbine.UI.Lotro.ShortcutType.Alias,
            self.textbox:GetText()
        ))
    end
end

-- ----------------------------------------------------------------------------
-- Layouting
-- ----------------------------------------------------------------------------

function ShortcutPanel:SizeChanged( args )

    xDEBUG("Resize: %d x %d", self:GetWidth(), self:GetHeight())

	self.textbox:SetPosition( 5, 5 );
	self.textbox:SetSize(
	    self:GetWidth() - 2*5,
	    self:GetHeight() - (40 + 25)
    );

    -- ------------------------------------------------------------------------

    local btntop = self:GetHeight() - (5 + 45 + 5)

	self.createbtn:SetSize( 60, 18 );
	self.createbtn:SetPosition(
		self:GetWidth() - 60 - 40 - 10,
		btntop + 10
	);

	-- self.quickslot:SetSize( 40, 40 );
	self.quickslot:SetPosition(
	    self:GetWidth()  - 40 - 5,
		btntop
	);
end

-- ----------------------------------------------------------------------------

PlugIn:SetOptionsPanel(ShortcutPanel())

--[[
local optionsPanel = ShortcutPanel()

plugin.GetOptionsPanel = function(self)
    xDEBUG("GetOptionsPanel")
    return optionsPanel;
end
]]--

