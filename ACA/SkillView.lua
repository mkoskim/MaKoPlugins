-- ****************************************************************************
-- ****************************************************************************
--
-- Alternative Combat Analyzer: Skill viewing component
--
-- ****************************************************************************
-- ****************************************************************************

import "MaKoPlugins.Utils";

local utils = MaKoPlugins.Utils
local println = utils.println
local fmtnum = utils.FormatNumber

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Skill Node
-- ----------------------------------------------------------------------------

local SkillNode = class(Turbine.UI.Control)

function SkillNode:Constructor(name)
	Turbine.UI.Control.Constructor(self);

	self:SetSize(200, 14)

	self.name = Turbine.UI.Label();
	self.name:SetParent( self );
	self.name:SetLeft(5);
	self.name:SetSize( 200 - 5, 14 );
	self.name:SetTextAlignment( Turbine.UI.ContentAlignment.MiddleLeft );
	self.name:SetText( name );
end

-- ----------------------------------------------------------------------------

SkillView = class(utils.ScrolledListBox)

function SkillView:Constructor()
    utils.ScrolledListBox.Constructor(self)

    self:AddItem(SkillNode("Total"))
    self:AddItem(utils.ListSeparator())
    self:AddItem(SkillNode("Skill 1"))
    self:AddItem(SkillNode("Skill 2"))
end

function SkillView:SelectedIndexChanged(sender, args)
    -- utils.ScrolledListBox.SelectedIndexChanged(self, sender, args)
    println("Selection changed: %d", self:GetSelectedIndex())
    -- utils.showfields(args)
end


