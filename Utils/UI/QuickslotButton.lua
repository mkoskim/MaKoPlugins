-- ****************************************************************************
-- ****************************************************************************
--
-- QuickslotButton is 'skinned' quickslot, modified from AliasButton
-- implemented in RTPlugin by MathWold), meant to create procedural
-- shortcuts. It does not allow dragging (no drag, no drop).
--
-- By default, the skin is Turbine.UI.Button.
--
-- ****************************************************************************
-- ****************************************************************************

QuickslotButton = class(Turbine.UI.Control)

function QuickslotButton:Constructor(skin)
	Turbine.UI.Control.Constructor( self );

    -- ------------------------------------------------------------------------
    -- We use Turbine's Quickslot instead of our own, as this quickslot is
    -- not dragged.
    -- ------------------------------------------------------------------------

	self.shortcut = nil
	self.quickslot = Turbine.UI.Lotro.Quickslot()
	self.quickslot:SetParent(self)
	self.quickslot:SetAllowDrop(false);
    self.quickslot.DragDrop = function(sender, args)
        self.quickslot:SetShortcut(self.shortcut)
    end
    
    -- ------------------------------------------------------------------------

    if not skin then
        skin = TextButton()
    else
        -- println("%d x %d", skin:GetSize())
        -- Turbine.UI.Control.SetSize(self, skin:GetSize())
    end

    -- ------------------------------------------------------------------------

    self.skin = skin
	self.skin:SetParent( self )
	self.skin:SetPosition(0, 0)
	self.skin:SetZOrder(self.quickslot:GetZOrder()+1)
	self.skin:SetMouseVisible(false)
    self.skin:SetEnabled(false)
	self.skin:SetBlendMode(Turbine.UI.BlendMode.Overlay)
end

-- ----------------------------------------------------------------------------
-- Redirect mouse events to skin
-- ----------------------------------------------------------------------------

function QuickslotButton:MouseEnter() self.skin:MouseEnter() end
function QuickslotButton:MouseLeave() self.skin:MouseLeave() end
function QuickslotButton:MouseDown() self.skin:MouseDown() end
function QuickslotButton:MouseUp() self.skin:MouseUp() end

-- ----------------------------------------------------------------------------

function QuickslotButton:SetText( text )
	self.skin:SetText( text )
end

function QuickslotButton:SetSize(w, h)
	Turbine.UI.Control.SetSize(self, w, h)
	self.quickslot:SetSize(w, h)
	self.skin:SetSize(w, h)
end

function QuickslotButton:SetShortcut( shortcut )
    self.quickslot:SetShortcut(shortcut)
    self.shortcut = shortcut
   	-- self.skin:SetEnabled(shortcut ~= nil)
   	self:SetEnabled(shortcut ~= nil)
end

function QuickslotButton:SetEnabled( state )
    self.skin:SetEnabled( state )
    self.quickslot:SetVisible( state )
end

