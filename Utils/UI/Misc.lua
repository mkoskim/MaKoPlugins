-- ****************************************************************************
-- ****************************************************************************
--
-- UI utilities
--
-- ****************************************************************************
-- ****************************************************************************

-- ****************************************************************************
-- ****************************************************************************
--
-- ListBox with ScrollBar (and frame). ScrollBar and Frame are parented to
-- ListBox parent (not in itself).
--
-- ****************************************************************************
-- ****************************************************************************

ScrolledListBox = class(Turbine.UI.ListBox)

function ScrolledListBox:Constructor()
	Turbine.UI.ListBox.Constructor(self)

	self.frame = Turbine.UI.Control()
	self.frame:SetBackColor( focusColor );

	self.scrollbar = Turbine.UI.Lotro.ScrollBar();
	-- self.scrollbar:SetParent(self);
	self.scrollbar:SetOrientation(Turbine.UI.Orientation.Vertical);
	self.scrollbar:SetVisible(true)

	self:SetVerticalScrollBar(self.scrollbar)
	self:SetBackColor( bgColor );
end

function ScrolledListBox:SetParent(parent)
    self.frame:SetParent(parent)
    Turbine.UI.ListBox.SetParent(self, parent)
    self.scrollbar:SetParent(parent)
end

function ScrolledListBox:SizeChanged(sender, args)
	self.frame:SetPosition(self:GetLeft() - 2, self:GetTop() - 2)
	self.frame:SetSize(self:GetWidth() + 4, self:GetHeight() + 4 )

	self.scrollbar:SetPosition(self:GetLeft() + self:GetWidth() - 10, self:GetTop())
	self.scrollbar:SetSize(10, self:GetHeight())
end

-- ----------------------------------------------------------------------------

ListNode = Turbine.UI.Control

-- ----------------------------------------------------------------------------

ListSeparator = class(Turbine.UI.Control)

function ListSeparator:Constructor()

	Turbine.UI.Control.Constructor( self );

	self:SetSize( 240, 1 );
	self:SetBackColorBlendMode( Turbine.UI.BlendMode.AlphaBlend );

	self:SetBackColor( focusColor );
	self:SetEnabled(false);
end

-- ****************************************************************************
-- ****************************************************************************
--
-- TextBox with ScrollBar (and frame)
--
-- ****************************************************************************
-- ****************************************************************************

ScrolledTextBox = class(Turbine.UI.TextBox)

function ScrolledTextBox:Constructor()
	Turbine.UI.TextBox.Constructor(self)

	self.frame = Turbine.UI.Control()
	self.frame:SetBackColor( focusColor );

	self.scrollbar = Turbine.UI.Lotro.ScrollBar();
	self.scrollbar:SetOrientation(Turbine.UI.Orientation.Vertical);
	self:SetVerticalScrollBar(self.scrollbar)

	self:SetBackColor( bgColor );
end

function ScrolledTextBox:SetParent(parent)
    self.frame:SetParent(parent)
    Turbine.UI.TextBox.SetParent(self, parent)
    self.scrollbar:SetParent(parent)
end

function ScrolledTextBox:SetPosition(x, y)
	Turbine.UI.TextBox.SetPosition(self, x, y)
	self.frame:SetPosition(self:GetLeft() - 2, self:GetTop() - 2)
	self.scrollbar:SetPosition(self:GetLeft() + self:GetWidth() - 10, self:GetTop())
end

function ScrolledTextBox:SetSize(w, h)
	Turbine.UI.TextBox.SetSize(self, w, h)

	self.frame:SetSize(self:GetWidth() + 4, self:GetHeight() + 4 )
	self.scrollbar:SetPosition(self:GetLeft() + self:GetWidth() - 10, self:GetTop())
	self.scrollbar:SetSize(10, self:GetHeight())
end

