-- ****************************************************************************
-- ****************************************************************************
--
-- Alternative Combat Analyzer: Record viewing component
--
-- ****************************************************************************
-- ****************************************************************************

import "MaKoPlugins.Utils";

local utils = MaKoPlugins.Utils
local println = utils.println
local fmtnum = utils.FormatNumber

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------

local HitTypeName = {
    [HitType.Regular] = "Regular",
    [HitType.Critical] = "Critical",
    [HitType.Devastate] = "Devastating",
    [HitType.Miss] = "Miss",
    [HitType.Immune] = "Immune",
    [HitType.Resist] = "Resist",
    [HitType.Block] = "Block",
    [HitType.Parry] = "Parry",
    [HitType.Evade] = "Evade",
    [HitType.PartialBlock] = "Partial Block",
    [HitType.PartialParry] = "Partial Parry",
    [HitType.PartialEvade] = "Partial Evade",
    [HitType.Deflect] = "Deflect",
    [HitType.Unknown] = "Unknown",
}

DamageTypeName = {
    [DamageType.Common] = "Common",
    [DamageType.Fire] = "Fire",
    [DamageType.Lightning] = "Lightning",
    [DamageType.Frost] = "Frost",
    [DamageType.Acid] = "Acid",
    [DamageType.Shadow] = "Shadow",
    [DamageType.Light] = "Light",
    [DamageType.Beleriand] = "Beleriand",
    [DamageType.Westernesse] = "Westernesse",
    [DamageType.AncientDwarf] = "Ancient Dwarf",
    [DamageType.FellWrought] = "Fell-Wrought",
    [DamageType.OrcCraft] = "Orc-Craft",
    [DamageType.Unknown] = "Unknown",
}

-- ----------------------------------------------------------------------------
-- Stat Node (stat line in listbox)
-- ----------------------------------------------------------------------------

local StatNode = class( utils.TreeNode )

function StatNode:Constructor( text, fields, key )

	utils.TreeNode.Constructor( self );

	self.text = text

    if key ~= nil then fields[key] = self end

	self:SetSize( 240, 16 );

	self:SetBackColorBlendMode( Turbine.UI.BlendMode.AlphaBlend );
	self.labelText = Turbine.UI.Label();
	self.labelText:SetParent( self );
	self.labelText:SetSize( 120, 16 );
	self.labelText:SetTextAlignment( Turbine.UI.ContentAlignment.MiddleLeft );
	self.labelText:SetText( self.text );

	self.labelCount = Turbine.UI.Label();
	self.labelCount:SetParent( self );
	self.labelCount:SetSize( 60, 16 );
	self.labelCount:SetLeft( 120 );
	self.labelCount:SetTextAlignment( Turbine.UI.ContentAlignment.MiddleRight );

	self.labelDamage = Turbine.UI.Label();
	self.labelDamage:SetParent( self );
	self.labelDamage:SetSize( 60, 16 );
	self.labelDamage:SetLeft( 180 );
	self.labelDamage:SetTextAlignment( Turbine.UI.ContentAlignment.MiddleRight );

end

function StatNode:Set(count, damage)
    self.labelCount:SetText(count)
    self.labelDamage:SetText(damage)
end

--[[
function StatNode:Refresh()
	xDEBUG("Updating: " .. self.key)

	local stat = stats[self.key]

	if stat ~= nil then
		self.labelValue:SetText( stat:AsString() );
		local diff = stat:DiffAsString();
		if diff and diff ~= "" then
			if diff:sub(1,1) == '-' then
				self.labelRef:SetForeColor( Turbine.UI.Color(1.0, 0.6, 0.6) );
			else
				self.labelRef:SetForeColor( Turbine.UI.Color(0.6, 1.0, 0.6) );
				if diff:sub(1,1) ~= '+' then diff = "+" .. diff end
			end
		end
		self.labelRef:SetText( diff );
	else
		self.labelValue:SetText( "N/A" );
		self.labelRef:SetText( "" );
	end
end
-- ]]--

-- ----------------------------------------------------------------------------
-- Stat Node Separator
-- ----------------------------------------------------------------------------

local StatSep = class( utils.TreeSeparator )

function StatSep:Refresh() end

-- ----------------------------------------------------------------------------
-- Stat Group
-- ----------------------------------------------------------------------------

local StatGroup = class( utils.TreeGroup )

function StatGroup:Constructor( name, ... )

    utils.TreeGroup.Constructor(self);

	self.name = name;

	self:SetSize( 270, 16 );

	self.labelKey = Turbine.UI.Label();
	self.labelKey:SetParent( self );
	self.labelKey:SetLeft( 20 );
	self.labelKey:SetSize( 250, 16 );
	self.labelKey:SetTextAlignment( Turbine.UI.ContentAlignment.MiddleLeft );
	self.labelKey:SetText( name );

	local childList = self:GetChildNodes();

	for _, node in pairs(arg) do
		childList:Add( node )
	end
end

--[[
function StatGroup:Refresh()
	xDEBUG("Updating: " .. self.name)

	local childs = self:GetChildNodes();
	local count = childs:GetCount();

	for i = 1, count do
		child = childs:Get(i)
		child:Refresh()
	end
end	
-- ]]--

-- ----------------------------------------------------------------------------
-- RecordView
-- ----------------------------------------------------------------------------

RecordView = class(utils.ScrolledTreeView)

function RecordView:Constructor()
    utils.ScrolledTreeView.Constructor(self)

    self.fields = { }

	local nodes = self:GetNodes()

	nodes:Add(
		StatGroup( "Received",
			StatNode("Non-crits", self.fields, "Received.NonCrits"),
			StatNode("Partials", self.fields, "Received.Partials"),
			StatSep(),
			StatNode("Crits & Devs", self.fields, "Received.CritNDevs"),
			StatNode("- Criticals", self.fields, "Received.Criticals"),
			StatNode("- Devastates", self.fields, "Received.Devastates"),
			StatSep(),
			StatNode("", self.fields, "Received.Total"),
			nil
		)
	);

	nodes:Add(
		StatGroup( "Peak",
			StatNode("Partials", self.fields, "Peak.Partials"),
			StatNode("Non-crits", self.fields, "Peak.NonCrits"),
			StatNode("Criticals", self.fields, "Peak.Criticals"),
			StatNode("Devastates", self.fields, "Peak.Devastates"),
			StatSep(),
			StatNode("", self.fields, "Peak.Summary"),
			nil
		)
	);

	nodes:Add(
		StatGroup( "Estimated",
		    StatNode("Received", self.fields, "Estimated.ReceivedFull"),
		    StatNode("Partial taken", self.fields, "Estimated.ReceivedPartial"),
		    StatNode("Partial avoid", self.fields, "Estimated.AvoidedPartial"),
		    StatNode("Avoided", self.fields, "Estimated.AvoidedFull"),
		    nil
		)
    );

    nodes:Add(
        StatGroup( "Avoidances",
		    StatNode("Partial Block", self.fields, "Avoided.PartialBlocks"),
		    StatNode("Partial Parry", self.fields, "Avoided.PartialParrys"),
		    StatNode("Partial Evade", self.fields, "Avoided.PartialEvades"),
		    StatSep(),
		    StatNode("Block", self.fields, "Avoided.Blocks"),
		    StatNode("Parry", self.fields, "Avoided.Parrys"),
		    StatNode("Evade", self.fields, "Avoided.Evades"),
		    StatSep(),
		    StatNode("Resist", self.fields, "Avoided.Resists"),
		    StatSep(),
		    StatNode("Other", self.fields, "Avoided.Others"),
		    -- StatNode("", self.fields, "Avoided.Estimated"),
		    nil
	    )
	);

    local DamageTypeNode = function(dmgtype)
        return StatNode(DamageTypeName[dmgtype], self.fields, dmgtype)
    end

	nodes:Add(
		StatGroup( "Damage types",
            DamageTypeNode(DamageType.Common),
            DamageTypeNode(DamageType.Fire),
            DamageTypeNode(DamageType.Lightning),
            DamageTypeNode(DamageType.Frost),
            DamageTypeNode(DamageType.Acid),
            DamageTypeNode(DamageType.Shadow),
            DamageTypeNode(DamageType.Light),
            DamageTypeNode(DamageType.Beleriand),
            DamageTypeNode(DamageType.Westernesse),
            DamageTypeNode(DamageType.AncientDwarf),
            DamageTypeNode(DamageType.FellWrought),
            DamageTypeNode(DamageType.OrcCraft),
            DamageTypeNode(DamageType.Unknown),
		    nil
		)
	);

end

-- ----------------------------------------------------------------------------

function RecordView:SetRecord(record)

    local estimated = record:Estimated()    -- Estimated totals
    local received = record:Received()      -- Received (hits + partials)
    local hits = record:Hits()              -- Full success
    local partials = record:Partials()      -- Partial avoids
    local avoids = record:Avoids()          -- Full avoids

    local regular    = record:Summary(HitType.Regular)
    local crits      = record:Summary(HitType.Critical)
    local devastates = record:Summary(HitType.Devastate)
    local critndevs  = record:Summary(HitType.Critical, HitType.Devastate)

    -- Sanity checks

    local sanitycheck = function(namea, valuea, nameb, valueb)
        if valuea ~= valueb then
            println("WARNING: %s != %s (%d != %d)", namea, nameb, valuea, valueb)
        end
    end

    sanitycheck(
        "received.sum", received.sum,
        "damagetype.sum", record:SumDamageTypes()
    )

    sanitycheck(
        "estimated.sum", estimated.sum,
        "hits/partials/avoids", hits.sum + partials.estimate + avoids.estimate
    )

    -- Received damage info

    self.fields["Received.Total"]:Set(fmtnum(received.count), fmtnum(received.sum))
    self.fields["Received.NonCrits"]:Set(
        string.format("%s %%", fmtnum(100 * regular.count / received.count, 1)),
        string.format("%s %%", fmtnum(100 * regular.sum / received.sum, 1))
    )
    self.fields["Received.Partials"]:Set(
        string.format("%s %%", fmtnum(100 * partials.count / received.count, 1)),
        string.format("%s %%", fmtnum(100 * partials.sum / received.sum, 1))
    )
    self.fields["Received.CritNDevs"]:Set(
        string.format("%s %%", fmtnum(100 * critndevs.count / received.count, 1)),
        string.format("%s %%", fmtnum(100 * critndevs.sum / received.sum, 1))
    )
    self.fields["Received.Criticals"]:Set(
        string.format("%s %%", fmtnum(100 * crits.count / received.count, 1)),
        string.format("%s %%", fmtnum(100 * crits.sum / received.sum, 1))
    )
    self.fields["Received.Devastates"]:Set(
        string.format("%s %%", fmtnum(100 * devastates.count / received.count, 1)),
        string.format("%s %%", fmtnum(100 * devastates.sum / received.sum, 1))
    )

    -- Peak damage info
    
    self.fields["Peak.Partials"]:Set(fmtnum(partials.average), fmtnum(partials.max))
    self.fields["Peak.NonCrits"]:Set(fmtnum(regular.average), fmtnum(regular.max))
    self.fields["Peak.Criticals"]:Set(fmtnum(crits.average), fmtnum(crits.max))
    self.fields["Peak.Devastates"]:Set(fmtnum(devastates.average), fmtnum(devastates.max))
    self.fields["Peak.Summary"]:Set(fmtnum(received.average), fmtnum(received.max))

    -- Avoided damage info (estimations)

    --[[self.fields["Avoided.Estimated"]:Set(
        "", --fmtnum(estimated.count),
        fmtnum(estimated.sum)
    ) ]]--

    self.fields["Estimated.ReceivedFull"]:Set(
        string.format("%s %%", fmtnum(100 * hits.count / estimated.count, 1)),
        string.format("%s %%", fmtnum(100 * hits.sum / estimated.sum, 1))
    )
    self.fields["Estimated.ReceivedPartial"]:Set(
        string.format("%s %%", fmtnum(100 * partials.count / estimated.count, 1)),
        string.format("%s %%", fmtnum(100 * partials.sum / estimated.sum, 1))
    )
    self.fields["Estimated.AvoidedPartial"]:Set(
        "",
        string.format("%s %%", fmtnum(100 * (partials.estimate - partials.sum) / estimated.sum, 1))
    )
    self.fields["Estimated.AvoidedFull"]:Set(
        string.format("%s %%", fmtnum(100 * avoids.count / estimated.count, 1)),
        string.format("%s %%", fmtnum(100 * avoids.estimate / estimated.sum, 1))
    )

    -- Avoided hits info

    self.fields["Avoided.PartialBlocks"]:Set(
        string.format("%s %%", fmtnum(100 * record:HitCount(HitType.PartialBlock) / received.count, 1)),
        string.format("%s %%", fmtnum(100 * record:HitTotal(HitType.PartialBlock) / received.sum, 1))
    )
    self.fields["Avoided.PartialParrys"]:Set(
        string.format("%s %%", fmtnum(100 * record:HitCount(HitType.PartialParry) / received.count, 1)),
        string.format("%s %%", fmtnum(100 * record:HitTotal(HitType.PartialParry) / received.sum, 1))
    )
    self.fields["Avoided.PartialEvades"]:Set(
        string.format("%s %%", fmtnum(100 * record:HitCount(HitType.PartialEvade) / received.count, 1)),
        string.format("%s %%", fmtnum(100 * record:HitTotal(HitType.PartialEvade) / received.sum, 1))
    )

    self.fields["Avoided.Blocks"]:Set(
        string.format("%s %%", fmtnum(100 * record:HitCount(HitType.Block) / estimated.count, 1)),
        "" --string.format("%s %%", fmtnum(100 * record.HitTotal(HitType.PartialBlock) / received.sum, 1))
    )
    self.fields["Avoided.Parrys"]:Set(
        string.format("%s %%", fmtnum(100 * record:HitCount(HitType.Parry) / estimated.count, 1)),
        "" --string.format("%s %%", fmtnum(100 * record.HitTotal(HitType.PartialBlock) / received.sum, 1))
    )
    self.fields["Avoided.Evades"]:Set(
        string.format("%s %%", fmtnum(100 * record:HitCount(HitType.Evade) / estimated.count, 1)),
        "" --string.format("%s %%", fmtnum(100 * record.HitTotal(HitType.PartialBlock) / received.sum, 1))
    )

    self.fields["Avoided.Resists"]:Set(
        string.format("%s %%", fmtnum(100 * record:HitCount(HitType.Resist) / estimated.count, 1)),
        "" --string.format("%s %%", fmtnum(100 * record.HitTotal(HitType.PartialBlock) / received.sum, 1))
    )

    local others = record:Other()
    
    self.fields["Avoided.Others"]:Set(
        string.format("%s %%", fmtnum(100 * others.count / estimated.count, 1)),
        "" -- string.format("%s %%", fmtnum(100 * others.sum / received.sum, 1))
    )

    -- Received damage types

    for key, value in pairs(record.dmgtypes) do
        self.fields[key]:Set(
            string.format("%s %%", fmtnum(100 * value / received.sum, 1)),
            string.format("%s", fmtnum(value))
        )
    end
end

