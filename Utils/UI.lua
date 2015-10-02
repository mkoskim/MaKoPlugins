-- ****************************************************************************
-- ****************************************************************************
--
-- UI utilities
--
-- ****************************************************************************
-- ****************************************************************************

-- ----------------------------------------------------------------------------
-- Constants
-- ----------------------------------------------------------------------------

IconExpand = 0x41007E27; -- 16x16
IconCollapse = 0x41007E26; -- 16x16
HeaderBackground = 0x411105A6; -- 9x16

bgColor = Turbine.UI.Color( 0, 0, 0);
focusColor = Turbine.UI.Color(1, 0.15, 0.15, 0.15);

-- ----------------------------------------------------------------------------
-- ListBox with scrollbar
-- ----------------------------------------------------------------------------

ScrolledListBox = class(Turbine.UI.ListBox)

function ScrolledListBox:Constructor()
	Turbine.UI.ListBox.Constructor(self)

	self.scrollbar = Turbine.UI.Lotro.ScrollBar();
	self.scrollbar:SetParent(self);
	self.scrollbar:SetOrientation(Turbine.UI.Orientation.Vertical);
	self.scrollbar:SetVisible(true)

	self:SetVerticalScrollBar(self.scrollbar)
end

function ScrolledListBox:SizeChanged(sender, args)
	self.scrollbar:SetPosition(self:GetLeft() + self:GetWidth() - 10, self:GetTop())
	self.scrollbar:SetSize(10, self:GetHeight())
	end

function ScrolledListBox:SetParent(parent)
    Turbine.UI.ListBox.SetParent(self, parent)
    self.scrollbar:SetParent(parent)
end
