-- ****************************************************************************
-- ****************************************************************************
--
-- UI utilities
--
-- ****************************************************************************
-- ****************************************************************************

local function DEBUG(str)
	Turbine.Shell.WriteLine(str)
	end

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
