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
-- TreeView with ScrollBar, as well as tree view groups and separators
--
-- ****************************************************************************
-- ****************************************************************************

ScrolledTreeView = class(Turbine.UI.TreeView)

function ScrolledTreeView:Constructor()
	Turbine.UI.TreeView.Constructor(self);

	self:SetIndentationWidth( 20 );
	self:SetBackColor( bgColor );

	self.frame = Turbine.UI.Control()
	self.frame:SetBackColor( focusColor );
	-- self.frame:SetParent(self)
	-- self.frame:SetVisible(true)

	self.scrollbar = Turbine.UI.Lotro.ScrollBar();
    self.scrollbar:SetOrientation( Turbine.UI.Orientation.Vertical );
	self.scrollbar:SetBackColor( bgColor );
	-- self.scrollbar:SetParent(self)
	-- self.scrollbar:SetVisible(true)

	self:SetVerticalScrollBar( self.scrollbar );
end

function ScrolledTreeView:SetParent(parent)
    self.frame:SetParent(parent)
    Turbine.UI.TreeView.SetParent(self, parent)
    self.scrollbar:SetParent(parent)
end

function ScrolledTreeView:SizeChanged(sender, args)
	-- println("(%d, %d)", self:GetLeft(), self:GetTop())

	self.frame:SetPosition(self:GetLeft() - 2, self:GetTop() - 2)
	self.frame:SetSize(self:GetWidth() + 4, self:GetHeight() + 4 )

	self.scrollbar:SetPosition(self:GetLeft() + self:GetWidth() - 10, self:GetTop())
	self.scrollbar:SetSize(10, self:GetHeight())
end

function ScrolledTreeView:Expand(expanded)

    if expanded == nil then return end

	local nodes = self:GetNodes()
	local count = nodes:GetCount();

	for i = 1, count do
		local node = nodes:Get( i );
		if node["name"] ~= nil and expanded[node.name] then
	        -- xDEBUG(node.name .. " expanded: " .. tostring(expanded))
	        --node:Expand()
	        node:SetExpanded(true)
	        --node:MouseClick()
		end
	end
end

function ScrolledTreeView:ExpandedGroups()
	local nodes = self:GetNodes()
	local count = nodes:GetCount();
    local expanded = { }
	for i = 1, count do
		local node = nodes:Get( i );
		if node["name"] ~= nil then
		    expanded[node.name] = node:IsExpanded();
		end
	end
	return expanded
end

-- ----------------------------------------------------------------------------

TreeGroup = class(Turbine.UI.TreeNode)

function TreeGroup:Constructor()
	Turbine.UI.TreeNode.Constructor( self );

	self.iconExpand = Turbine.UI.Control();
	self.iconExpand:SetParent( self );
	self.iconExpand:SetSize( 16, 16 );
	self.iconExpand:SetBackground( IconExpand );
	self.iconExpand:SetBlendMode( Turbine.UI.BlendMode.AlphaBlend );
	self.iconExpand:SetMouseVisible( false );

	self:SetBackground( HeaderBackground );
end

function TreeGroup:MouseClick(args)
	self.iconExpand:SetBackground(
	    self:IsExpanded() and IconCollapse or IconExpand
    );
end

function TreeGroup:SetExpanded(status)
    Turbine.UI.TreeNode.SetExpanded(self, status)
    self:MouseClick()
end

-- ----------------------------------------------------------------------------

TreeNode = class(Turbine.UI.TreeNode)

function TreeNode:Constructor()
	Turbine.UI.TreeNode.Constructor( self );
end

-- ----------------------------------------------------------------------------

TreeSeparator = class(Turbine.UI.TreeNode)

function TreeSeparator:Constructor()

	Turbine.UI.TreeNode.Constructor( self );

	self:SetSize( 240, 1 );
	self:SetBackColorBlendMode( Turbine.UI.BlendMode.AlphaBlend );

	self:SetBackColor( focusColor );
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

