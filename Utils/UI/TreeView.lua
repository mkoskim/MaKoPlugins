-- ****************************************************************************
-- ****************************************************************************
--
-- TreeView with ScrollBar, as well as tree view groups and separators
--
-- ****************************************************************************
-- ****************************************************************************

TreeView = class(Frame)

function TreeView:Constructor()
	Frame.Constructor(self)

    -- ------------------------------------------------------------------------

	self.tree = Turbine.UI.TreeView()
	self.tree:SetParent(self)
	self.tree:SetIndentationWidth( 20 );
	self.tree:SetBackColor( bgColor );

	self.scrollbar = Turbine.UI.Lotro.ScrollBar();
    self.scrollbar:SetParent(self)
    self.scrollbar:SetOrientation( Turbine.UI.Orientation.Vertical );
	self.scrollbar:SetBackColor( bgColor );

	self.tree:SetVerticalScrollBar( self.scrollbar );

    self.CollapseAll = function(sender) self.tree:CollapseAll() end
    self.ExpandAll = function(sender) self.tree:ExpandAll() end
    self.GetNodes = function(sender) return self.tree:GetNodes() end

    -- ------------------------------------------------------------------------

	self.iconExpandAll = Turbine.UI.Control();
	self.iconExpandAll:SetParent( self );
	self.iconExpandAll:SetSize( 16, 16 );
	self.iconExpandAll:SetBackground( Icons.Expand );
	self.iconExpandAll:SetBlendMode( Turbine.UI.BlendMode.AlphaBlend );
    self.iconExpandAll.MouseClick = function(sender, args)
        self:ExpandAll()
    end

	self.iconCollapseAll = Turbine.UI.Control();
	self.iconCollapseAll:SetParent( self );
	self.iconCollapseAll:SetSize( 16, 16 );
	self.iconCollapseAll:SetBackground( Icons.Collapse );
	self.iconCollapseAll:SetBlendMode( Turbine.UI.BlendMode.AlphaBlend );
    self.iconCollapseAll.MouseClick = function(sender, args)
        self:CollapseAll()
    end
end

function TreeView:SizeChanged(sender, args)
	self.tree:SetPosition(1, 1)
	self.tree:SetSize(self:GetWidth() - 2, self:GetHeight() - 2)

	self.scrollbar:SetPosition(self:GetWidth() - 10, 1 + 16)
	self.scrollbar:SetSize(10, self:GetHeight() - 2 - 16)

    self.iconExpandAll:SetPosition(self:GetWidth()-16-16, 1)
    self.iconCollapseAll:SetPosition(self:GetWidth()-16, 1)
end

function TreeView:Expand(expanded)

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

function TreeView:ExpandedGroups()
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
	self.iconExpand:SetBackground( Icons.Expand );
	self.iconExpand:SetBlendMode( Turbine.UI.BlendMode.AlphaBlend );
	self.iconExpand:SetMouseVisible( false );

	self:SetBackground( Icons.HeaderBackground.Blue );
end

function TreeGroup:SetExpanded(status)
    Turbine.UI.TreeNode.SetExpanded(self, status)
    self:MouseClick()
end

function TreeGroup:MouseClick(args)
	self.iconExpand:SetBackground(
	    self:IsExpanded() and Icons.Collapse or Icons.Expand
    );
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
	-- self:SetBackColorBlendMode( Turbine.UI.BlendMode.AlphaBlend );

	self:SetBackColor( focusColor );
end

