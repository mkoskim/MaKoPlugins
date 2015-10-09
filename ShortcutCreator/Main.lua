-- ****************************************************************************
-- ****************************************************************************
--
-- Simple shortcut creator helper
--
-- ****************************************************************************
-- ****************************************************************************

debugging = true

-- ****************************************************************************

import "MaKoPlugins.Utils";

local utils = MaKoPlugins.Utils

-- ----------------------------------------------------------------------------
-- Create window
-- ----------------------------------------------------------------------------

ShortcutPanel = class(Turbine.UI.Control)

function ShortcutPanel:Constructor()

	Turbine.UI.Control.Constructor(self)

    -- ------------------------------------------------------------------------

    self:SetSize(200, 200)

    -- ------------------------------------------------------------------------

    self.textbox = utils.ScrolledTextBox()
    self.textbox:SetParent(self)
    self.textbox:SetMultiline(true)
    self.textbox:SetSelectable(true)
    self.textbox:SetReadOnly(false)

    -- ------------------------------------------------------------------------

	self.quickslot = utils.Quickslot();
	self.quickslot:SetParent( self );
	self.quickslot:SetAllowDrop(true);

    self.quickslot.DragDrop = function(sender, args)
        DEBUG("DragDrop")
        -- dumptable(args)
        local shortcut = args.DragDropInfo:GetShortcut()
        -- dumptable(shortcut.__implementation)
        DEBUG("Shortcut: %d", shortcut:GetType())
    end

    self.quickslot.DragEnter = function(sender, args)
        DEBUG("DragEnter")
        dumptable(args)
        -- local shortcut = args.DragDropInfo:GetShortcut()
        -- dumptable(shortcut)
    end

    self.quickslot.DragLeave = function(sender, args)
        DEBUG("DragLeave")
        dumptable(args)
        -- local shortcut = args.DragDropInfo:GetShortcut()
        -- dumptable(shortcut)
    end

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

local optionsPanel = ShortcutPanel()

function plugin:GetOptionsPanel()
    if not _G.plugin then _G.plugin = self end
    DEBUG("GetOptionsPanel")
    return optionsPanel;
end

