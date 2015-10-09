-- ****************************************************************************
-- ****************************************************************************
--
-- Plugin for real-time stat watching
--
-- ****************************************************************************
-- ****************************************************************************

debugging = true

-- ****************************************************************************

import "MaKoPlugins.Utils";
import "MaKoPlugins.StatWatch.Conversion";

local utils   = MaKoPlugins.Utils

-- ----------------------------------------------------------------------------
-- Obtain & extending player info, ready for using
-- ----------------------------------------------------------------------------

local player  = Turbine.Gameplay.LocalPlayer:GetInstance();
local attr    = player:GetAttributes()
local effects = player:GetEffects()
local equip   = player:GetEquipment()

local armortype = ArmorType[player:GetClass()]

-- ****************************************************************************
-- ****************************************************************************
--
-- Plugin settings (autoload settings at startup)
--
-- ****************************************************************************
-- ****************************************************************************

local DefaultSettings = {
	WindowPosition = {
		Left = 0,
		Top  = 0,
		Width = 200,
		Height = 200
	},
	WindowVisible = true,
	ExpandedGroups = { },
	ShowPercentages = true,
	ShareWindowPosition = {
	    Left = 0,
	    Top = 0,
	    Width = 200,
	    Height = 200,
	}
}

local Settings = plugin.LoadSettings(
    "StatWatchSettings",
    DefaultSettings
)

-- ****************************************************************************
-- ****************************************************************************

local function FormatNumber(number, decimals)

	if number < 1000 then
		return string.format("%." .. tostring(decimals or 0) .. "f", number)
	-- elseif number < 1000 then
	--	return string.format("%.0f", number)
	elseif number < 150000 then
		return string.format("%d,%03d", (number+0.5)/1000, (number+0.5)%1000)
	elseif number < 1000000 then
		return string.format("%.1fk", (number+0.5)/1000)
	elseif number < 1500000 then
		return string.format("%d,%03.1fk", (number+0.5)/1000000, ((number+0.5)%1000000)/1000)
	else
		return string.format("%.2fM", number/1e6)
	end

end

-- ****************************************************************************
-- ****************************************************************************
--
-- Stat retrieving, converting and formatting
--
-- ****************************************************************************
-- ****************************************************************************

-- ----------------------------------------------------------------------------
-- Stat class to obtain & format stats
-- ----------------------------------------------------------------------------

local Stat = class()
local stats = { }
local percentages = Settings.ShowPercentages
local ToPercent = ratingToPercentage

local function FormatPercentage(value) return string.format("%.1f %%", value) end
local function FormatPercentageInc(value) return string.format("%+.1f %%", value) end
local function FormatELM(value) return string.format("x %3.1f", value) end

-- ----------------------------------------------------------------------------

function Stat:Constructor(key, rawvalue, percentage, fmt)
	self.key = key
	self.rawvalue = rawvalue
	self.refvalue = nil
	self.percentage = percentage

	if fmt ~= nil then
		self.fmt = fmt
	else
		self.fmt = function(number) return FormatNumber(number) end
	end
	
	stats[key] = self
end

-- ----------------------------------------------------------------------------

function Stat:Rating() return self.rawvalue() end
function Stat:Percentage()
	return ToPercent( self.percentage, self:Rating(), player:GetLevel() )
	end

function Stat:RatingAsString()
    return self.fmt( self:Rating() )
end

function Stat:PercentAsString()
    return self.percentage and FormatPercentage(self:Percentage()) or ""
end

function Stat:AsString()
	if type(self.rawvalue) == "string" then
		return self.rawvalue
	elseif percentages and self.percentage then
		-- return FormatPercentage(self:AsPercent())
		return self:PercentAsString()
	else
		-- return self.fmt( self:Value() )
		return self:RatingAsString()
	end
end

function Stat:DiffAsString()
	if self.refvalue == nil then return "" end
	diff = self:Rating() - self.refvalue
	if math.abs(diff) < 0.1 then
		return ""
	elseif percentages and self.percentage then
		diff = self:Percentage() - ToPercent( self.percentage, self.refvalue, player:GetLevel() )
		return FormatPercentageInc(diff)
	else
		return self.fmt(diff)
	end
end

-- ----------------------------------------------------------------------------

function Stat:SetRef()
	if type(self.rawvalue) ~= "string" then
		self.refvalue = self.rawvalue()
	end
end

function Stat:SetCapRef()
	if type(self.rawvalue) ~= "string" then
		self.refvalue = ratingCap(self.percentage, player:GetLevel())
	end
end

function Stat:ClrRef() self.refvalue = nil end

-- ----------------------------------------------------------------------------

local function SetReference()
	for key, stat in pairs(stats) do stat:SetRef() end
end

local function SetCapReference()
	for key, stat in pairs(stats) do stat:SetCapRef() end
end

local function ClearReference()
	for key, stat in pairs(stats) do stat:ClrRef() end
end

-- ----------------------------------------------------------------------------
-- Stats
-- ----------------------------------------------------------------------------

Stat("", "")
Stat("N/A", "N/A")

Stat("Morale", function() return player:GetMaxMorale() end)
Stat("Power", function() return player:GetMaxPower() end)

Stat("ICMR", function() return attr:GetInCombatMoraleRegeneration() end, nil, function(v) return FormatNumber(v, 1) end)
Stat("ICPR", function() return attr:GetInCombatPowerRegeneration() end, nil, function(v) return FormatNumber(v, 1) end)

Stat("Armor", function() return attr:GetArmor() end)
Stat("Might", function() return attr:GetMight() end)
Stat("Agility", function() return attr:GetAgility() end)
Stat("Vitality", function() return attr:GetVitality() end)
Stat("Will", function() return attr:GetWill() end)
Stat("Fate", function() return attr:GetFate() end)

Stat("CritRate", function() return attr:GetBaseCriticalHitChance() end, "CritRate")
Stat("CritMag", function() return ToPercent("CritMag", stats["CritRate"]:Rating(), player:GetLevel()) end, nil, FormatPercentageInc)
Stat("DevRate", function() return ToPercent("DevRate", stats["CritRate"]:Rating(), player:GetLevel()) end, nil, FormatPercentage)

Stat("Finesse", function() return attr:GetFinesse() end, "Finesse")
Stat("PhysMast", function() return math.max(attr:GetMeleeDamage(), attr:GetRangeDamage()) end, "Mastery")
Stat("TactMast", function() return attr:GetTacticalDamage() end, "Mastery")

Stat("Resistance", function() return attr:GetBaseResistance() end, "Resistance")
Stat("CritDef", function() return attr:GetBaseCriticalHitAvoidance() end, "CritDef")

-- Stat("HealOut", function() return attr:GetOutgoingHealing() end, "OutHeals")
Stat("HealOut", function() return ToPercent("OutHeals", attr:GetOutgoingHealing(), player:GetLevel()) end, nil, FormatPercentageInc)
Stat("HealIn", function() return attr:GetIncomingHealing() end, "IncHeals")

Stat("Block", function() return (attr:CanBlock() and attr:GetBlock()) or 0 end, "Avoidances")
Stat("Parry", function() return (attr:CanParry() and attr:GetParry()) or 0 end, "Avoidances")
Stat("Evade", function() return (attr:CanEvade() and attr:GetEvade()) or 0 end, "Avoidances")

Stat("CommonMit", function() return attr:GetCommonMitigation() end, armortype)
Stat("PhysMit", function() return attr:GetPhysicalMitigation() end, armortype)
Stat("TactMit", function() return attr:GetTacticalMitigation() end, armortype)

-- ----------------------------------------------------------------------------
-- Calculated stats
-- ----------------------------------------------------------------------------

Stat("Avoidances", function()
	return
		stats["Block"]:Percentage() + 
		stats["Parry"]:Percentage() +
		stats["Evade"]:Percentage();
	end,
	nil,
	FormatPercentage
)

--[[
Stat("SelfHeal", function()
	return 100 *
		(1.0 + stats["HealIn"]:Percentage()/100.0) *
		(1.0 + stats["HealOut"]:Percentage()/100.0) - 100
	end,
	nil,
	FormatPercentageInc
)

Stat("CommonELM", function()
	return 1.0 / ( 
		-- (1 - stats["Avoidances"]:Value()/100.0) *
		(1 - stats["CommonMit"]:Percentage()/100.0)
	)
	end,
	nil,
	FormatELM
)

Stat("TactELM", function()
	return 1.0 / ( 
		-- (1 - stats["Avoidances"]:Value()/100.0) *
		(1 - stats["TactMit"]:Percentage()/100.0)
	)
	end,
	nil,
	FormatELM
)
]]--

-- ****************************************************************************
-- ****************************************************************************
--
-- Share window: This is bit hairy. We need to create a shortcut, which
-- contains alias, which contains command to send a line to correct
-- channel.
--
-- ****************************************************************************
-- ****************************************************************************

StatShareGroup = class(utils.TreeGroup)

function StatShareGroup:Constructor(name)
    utils.TreeGroup.Constructor(self);

	self:SetSize( 270, 16 );

	self.labelKey = Turbine.UI.Label();
	self.labelKey:SetParent( self );
	self.labelKey:SetLeft( 20 );
	self.labelKey:SetSize( 250, 16 );
	self.labelKey:SetTextAlignment( Turbine.UI.ContentAlignment.MiddleLeft );
	self.labelKey:SetText( name );

    self.node = utils.TreeNode()

    self.textbox = Turbine.UI.TextBox()
    self.textbox:SetParent(self.node)
	self.textbox:SetFont(Turbine.UI.Lotro.Font.Verdana14);
    self.textbox:SetMultiline(true)
    self.textbox:SetReadOnly(true)
    self.textbox:SetSelectable(true)

    self:GetChildNodes():Add(self.node)
end

function StatShareGroup:SetText(text)
    local lines = select(2, text:gsub('\n', '\n')) + 1

    self.node:SetSize(240, 14 * lines + 4)
    self.textbox:SetSize(self.node:GetWidth(), self.node:GetHeight())
    self.textbox:SetText(text)
end

function StatShareGroup:GetText()
    return self.textbox:GetText()
end

-- ----------------------------------------------------------------------------

StatShareWindow = class(Turbine.UI.Lotro.Window)

function StatShareWindow:Constructor()
	Turbine.UI.Lotro.Window.Constructor(self);

	self:SetText("Share stats");
	self:SetResizable(true);

    -- ------------------------------------------------------------------------

    self.chooser = utils.ScrolledTreeView()
    self.chooser:SetParent(self)

    self.groups = {
        ["MoralePower"] = StatShareGroup("Morale & Power"),
        ["Regen"] = StatShareGroup("In-combat Regen"),
        ["BasicStats"] = StatShareGroup("Basic Stats"),
        ["Offence"] = StatShareGroup("Offence"),
        ["Defence"] = StatShareGroup("Defence"),
        ["Avoidance"] = StatShareGroup("Avoidance"),
        ["Mitigations"] = StatShareGroup("Mitigations"),
    }

    self.order = {
        "MoralePower", "Regen",
        "BasicStats",
        "Offence",
        "Defence", "Avoidance", "Mitigations"
    }

    for _, key in pairs(self.order) do
        local group = self.groups[key]
        self.chooser:GetNodes():Add( group )
        group:SetExpanded(false)
    end

    -- ------------------------------------------------------------------------

	self.channelbtn = utils.DropDown({"/f", "/ra", "/k", "/say", "/tell" })
	self.channelbtn:SetParent( self );

    self.namebox = utils.ScrolledTextBox() -- Turbine.UI.TextBox()
    self.namebox:SetParent(self)
    self.namebox:SetMultiline(false)
	self.namebox:SetTextAlignment( Turbine.UI.ContentAlignment.MiddleLeft );
    self.namebox:SetText("")

	self.sendbtn = Turbine.UI.Lotro.Quickslot();
	self.sendbtn:SetParent( self );
	self.sendbtn:SetAllowDrop(false);

    self.createbtn = Turbine.UI.Lotro.Button()
	self.createbtn:SetParent( self );
    self.createbtn:SetText("Create")
    self.createbtn.MouseClick = function(sender, args)
        local channel = self.channelbtn:GetText()
        local target = (channel == "/tell") and self.namebox:GetText() or ""
        
        local text = { }
        for _, key in pairs(self.order) do
            local group = self.groups[key]
            if group:IsExpanded() then
                table.insert(text, group:GetText())
            end
        end

        text = table.concat(text, "\n- - - - - - - - - - - - - - - - - - -\n")

        self.sendbtn:SetShortcut(Turbine.UI.Lotro.Shortcut(
            Turbine.UI.Lotro.ShortcutType.Alias,
            string.format("%s %s Stats:\n%s", channel, target, text)
        ))
    end


    -- ------------------------------------------------------------------------

	if Settings["ShareWindowPosition"] == nil then
	    Settings["ShareWindowPosition"] = DefaultSettings["ShareWindowPosition"]
	end

	self:SetPosition(
		Settings.ShareWindowPosition.Left,
		Settings.ShareWindowPosition.Top
	)
	self:SetSize(
		310, -- Settings.WindowPosition.Width,
		Settings.ShareWindowPosition.Height
	)

    self:SetVisible(false)
end

-- ----------------------------------------------------------------------------
-- Layouting
-- ----------------------------------------------------------------------------

function StatShareWindow:SizeChanged( args )

	self.chooser:SetPosition( 20, 40 );
	self.chooser:SetSize(
	    self:GetWidth() - 2*20,
	    self:GetHeight() - (40 + 60)
    );

    -- ------------------------------------------------------------------------

    local btntop = self:GetHeight() - (40 + 60) + 40 + 5

	self.channelbtn:SetWidth(60);
	self.channelbtn:SetPosition(20, btntop + 10)

	self.namebox:SetSize(
	    self:GetWidth() - (20 + 65) - (5 + 60 + 5 + 40) - 20,
	    18
	);
	self.namebox:SetPosition(20 + 65, btntop + 10)

    -- ------------------------------------------------------------------------

	self.createbtn:SetSize( 60, 18 );
	self.createbtn:SetPosition(
		self:GetWidth() - 60 - 40 - 25,
		btntop + 10
	);

	self.sendbtn:SetSize( 40, 40 );
	self.sendbtn:SetPosition(
	    self:GetWidth()  - 40 - 20,
		btntop
	);
end

-- ----------------------------------------------------------------------------
-- Creating string from stats: this is aimed to be used to share
-- builds with people
-- ----------------------------------------------------------------------------

function StatShareWindow:Refresh()
    self.groups["MoralePower"]:SetText(
        string.format("Morale..: %s", stats["Morale"]:AsString()) .. "\n" ..
        string.format("Power...: %s", stats["Power"]:AsString())
    )

    self.groups["Regen"]:SetText(
        string.format("ICMR...: %s (%s / s)",
            FormatNumber(stats["ICMR"]:Rating() * 60),
            stats["ICMR"]:AsString()
        )  .. "\n" ..
        string.format("ICPR....: %s (%s / s)",
            FormatNumber(stats["ICPR"]:Rating() * 60),
            stats["ICPR"]:AsString()
        )
    )

    self.groups["BasicStats"]:SetText(
        string.format("Might.....: %s", stats["Might"]:RatingAsString())  .. "\n" ..
        string.format("Agility....: %s", stats["Agility"]:RatingAsString())  .. "\n" ..
        string.format("Vitality...: %s", stats["Vitality"]:RatingAsString())  .. "\n" ..
        string.format("Will........: %s", stats["Will"]:RatingAsString())  .. "\n" ..
        string.format("Fate......: %s", stats["Fate"]:RatingAsString())
    )

    self.groups["Offence"]:SetText(
        string.format("Critical Rating....: %s - %s",
            stats["CritRate"]:RatingAsString(),
            stats["CritRate"]:PercentAsString()
        ) .. "\n" ..
        string.format("Finesse.............: %s - %s",
            stats["Finesse"]:RatingAsString(),
            stats["Finesse"]:PercentAsString()
        ) .. "\n" ..
        string.format("Physical Mastery: %s - %s",
            stats["PhysMast"]:RatingAsString(),
            stats["PhysMast"]:PercentAsString()
        ) .. "\n" ..
        string.format("Tactical Mastery: %s - %s",
            stats["TactMast"]:RatingAsString(),
            stats["TactMast"]:PercentAsString()
        ) .. "\n" ..
        string.format("Outgoing Healing: %s",
            stats["HealOut"]:RatingAsString()
        )
    )

    self.groups["Defence"]:SetText(
        string.format("Resistance........: %s - %s",
            stats["Resistance"]:RatingAsString(),
            stats["Resistance"]:PercentAsString()
        ) .. "\n" ..
        string.format("Critical Defence.: %s - %s",
            stats["CritDef"]:RatingAsString(),
            stats["CritDef"]:PercentAsString()
        ) .. "\n" ..
        string.format("Incoming Healing: %s - %s",
            stats["HealIn"]:RatingAsString(),
            stats["HealIn"]:PercentAsString()
        )
    )

    self.groups["Avoidance"]:SetText(
        string.format("Block.: %s - %s",
            stats["Block"]:RatingAsString(),
            stats["Block"]:PercentAsString()
        ) .. "\n" ..
        string.format("Parry.: %s - %s",
            stats["Parry"]:RatingAsString(),
            stats["Parry"]:PercentAsString()
        ) .. "\n" ..
        string.format("Evade: %s - %s",
            stats["Evade"]:RatingAsString(),
            stats["Evade"]:PercentAsString()
        ) .. "\n" ..
        string.format("BPE...: %s", stats["Avoidances"]:RatingAsString())
    )

    self.groups["Mitigations"]:SetText(
        string.format("Phys. Mitigation..: %s - %s",
            stats["CommonMit"]:RatingAsString(),
            stats["CommonMit"]:PercentAsString()
        ) .. "\n" ..
        string.format("Tact. Mitigation..: %s - %s",
            stats["TactMit"]:RatingAsString(),
            stats["TactMit"]:PercentAsString()
        ) .. "\n" ..
        string.format("OC/FW Mitigation: %s - %s",
            stats["PhysMit"]:RatingAsString(),
            stats["PhysMit"]:PercentAsString()
        )
    )
end

-- ****************************************************************************
-- ****************************************************************************
--
-- UI: Stat group & node classes
--
-- ****************************************************************************
-- ****************************************************************************

-- ----------------------------------------------------------------------------
-- Stat Node (stat line in listbox)
-- ----------------------------------------------------------------------------

local StatNode = class( utils.TreeNode )

function StatNode:Constructor( text, key )

	utils.TreeNode.Constructor( self );

	self.text = text
	if key ~= nil then
		self.key = key
	else
		self.key = text
	end

	self:SetSize( 240, 16 );

	self:SetBackColorBlendMode( Turbine.UI.BlendMode.AlphaBlend );
	self.labelText = Turbine.UI.Label();
	self.labelText:SetParent( self );
	self.labelText:SetSize( 120, 16 );
	self.labelText:SetTextAlignment( Turbine.UI.ContentAlignment.MiddleLeft );
    self.labelText:SetMultiline(false)
	-- self.labelText:SetMouseVisible( false );
	self.labelText:SetText( self.text );
	
	self.labelValue = Turbine.UI.Label();
	self.labelValue:SetParent( self );
	self.labelValue:SetSize( 60, 16 );
	self.labelValue:SetLeft( 120 );
	self.labelValue:SetTextAlignment( Turbine.UI.ContentAlignment.MiddleRight );
	-- self.labelValue:SetMouseVisible( false );

	self.labelRef = Turbine.UI.Label();
	self.labelRef:SetParent( self );
	self.labelRef:SetSize( 60, 16 );
	self.labelRef:SetLeft( 180 );
	self.labelRef:SetTextAlignment( Turbine.UI.ContentAlignment.MiddleRight );

	-- self:SetMouseVisible( true );
end

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

-- ----------------------------------------------------------------------------
-- Stat Node Separator
-- ----------------------------------------------------------------------------

local StatSep = class( utils.TreeSeparator )

function StatSep:Refresh() end

-- ----------------------------------------------------------------------------
-- Stat Group
-- ----------------------------------------------------------------------------

local StatGroup = class( utils.TreeGroup )

function StatGroup:Constructor( name, nodes )

    utils.TreeGroup.Constructor(self);

	self.name = name;

	self:SetSize( 270, 16 );

	self.labelKey = Turbine.UI.Label();
	self.labelKey:SetParent( self );
	self.labelKey:SetLeft( 20 );
	self.labelKey:SetSize( 250, 16 );
	self.labelKey:SetTextAlignment( Turbine.UI.ContentAlignment.MiddleLeft );
	self.labelKey:SetText( name );
	self.labelKey:SetMouseVisible( false );

	local childList = self:GetChildNodes();

	for i = 0, table.getn(nodes) do
		childList:Add( nodes[i] );
	end
end

function StatGroup:Refresh()
	xDEBUG("Updating: " .. self.name)

	local childs = self:GetChildNodes();
	local count = childs:GetCount();

	for i = 1, count do
		child = childs:Get(i)
		child:Refresh()
	end
end	

-- ****************************************************************************
-- ****************************************************************************
--
-- Window to show stats
--
-- ****************************************************************************
-- ****************************************************************************

StatBrowser = class(Turbine.UI.Lotro.Window);

function StatBrowser:Constructor()
	Turbine.UI.Lotro.Window.Constructor(self);

	-- ------------------------------------------------------------------------
	-- Window properties
	-- ------------------------------------------------------------------------
	
	self:SetText("Stats");
	
	self:SetMinimumWidth(310);
	self:SetMaximumWidth(310);
	self:SetMinimumHeight(250);

	self:SetResizable(true);
	
	-- ------------------------------------------------------------------------
	-- ListBox for stats
	-- ------------------------------------------------------------------------

    self.statlist = utils.ScrolledTreeView()
    self.statlist:SetParent(self)

	-- ------------------------------------------------------------------------
	-- Elements to share builds
	-- ------------------------------------------------------------------------

    self.sharewindow = StatShareWindow()

    self.sharebtn = Turbine.UI.Lotro.Button();
    self.sharebtn:SetParent(self)
	self.sharebtn:SetText( "Share" );
	self.sharebtn.MouseClick = function(sender, args)
        local exposing = not self.sharewindow:IsVisible()
        if exposing then self.sharewindow:Refresh() end
        self.sharewindow:SetVisible(exposing)
    end

	-- ------------------------------------------------------------------------
	-- Buttons
	-- ------------------------------------------------------------------------

	self.refreshbtn = Turbine.UI.Lotro.Button();
	self.refreshbtn:SetParent( self );
	self.refreshbtn:SetText( "Refresh" );
	self.refreshbtn.Click = function() 
		self:Refresh();
		if self.sharewindow:IsVisible() then
		    self.sharewindow:Refresh()
		end
	end

	self.formatbtn = utils.DropDown({"#", "%"});
	self.formatbtn:SetParent( self );
	self.formatbtn:SetText(percentages and "%" or "#");
	self.formatbtn.ItemChanged = function(sender, args) 
		percentages = (args.Index == 2)
		self:Refresh();
	end

	self.referencebtn = utils.DropDown({"", "Set", "Cap"});
	self.referencebtn:SetParent( self );
	self.referencebtn:SetText( "" );
	self.referencebtn.ItemChanged = function(sender, args)
		callbacks = { ClearReference, SetReference, SetCapReference };
		callbacks[args.Index]();
		self:Refresh();
	end

	-- ------------------------------------------------------------------------
	-- Fill in groups & stat nodes
	-- ------------------------------------------------------------------------

	local nodes = self.statlist:GetNodes()

	nodes:Add(
		StatGroup( "Morale & Power",
			{
				StatNode("Morale"),
				StatNode("Power"),
			}
		)
	);
	
	nodes:Add(
		StatGroup( "In-Combat Regen",
			{
				StatNode("ICMR"),
				StatNode("ICPR"),
			}
		)
	);
	
	nodes:Add(
		StatGroup( "Basic Stats",
			{
				StatNode("Armor"),
				StatSep(),
				StatNode("Might"),
				StatNode("Agility"),
				StatNode("Vitality"),
				StatNode("Will"),
				StatNode("Fate"),
			}
		)
	);
	
	nodes:Add(
		StatGroup( "Critical",
			{
				StatNode("Critical Rating", "CritRate"),
				StatNode("- Devastates", "DevRate"),
				StatNode("- Magnitude", "CritMag")
			}
		)
	);
	
	nodes:Add(
		StatGroup( "Offence",
			{
				StatNode("Finesse", "Finesse"),
				StatNode("Physical Mastery", "PhysMast"),
				StatNode("Tactical Mastery", "TactMast"),
				StatNode("- Outgoing Healing", "HealOut"),
			}
		)
	);

	--[[ nodes:Add(
		StatGroup( "Healing",
			{
				StatNode("Outgoing", "HealOut"),
			}
		)
	); ]]--

	nodes:Add(
		StatGroup( "Defences",
			{
				StatNode("Resistance"),
				StatNode("Critical Defence", "CritDef"),
				StatNode("Incoming Healing", "HealIn"),
			}
		)
	);
	
	nodes:Add(
		StatGroup( "Avoidances",
			{
				StatNode("Block"),
				StatNode("Parry"),
				StatNode("Evade"),
				StatSep(),
				StatNode("", "Avoidances"),
			}
		)
	);
	
	nodes:Add(
		StatGroup( "Mitigations",
			{
				StatNode("Common", "CommonMit"),
				StatNode("Tactical", "TactMit"),
				StatNode("OC/FW", "PhysMit"),
			}
		)
	);

	--[[ nodes:Add(
		StatGroup( "Experimental",
			{
				StatNode("Self-heal", "SelfHeal"),
				StatSep(),
				StatNode("Morale Mult.", ""),
				StatNode("- Common Damage", "CommonELM"),
				StatNode("- Tactical Damage", "TactELM"),
			}
		)
	); -- ]]--

	-- ------------------------------------------------------------------------
	-- Expand groups which were expanded last time
	-- ------------------------------------------------------------------------

    self.statlist:Expand(Settings.ExpandedGroups) 

	-- ------------------------------------------------------------------------
	-- Place window
	-- ------------------------------------------------------------------------

	self:SetPosition(
		Settings.WindowPosition.Left,
		Settings.WindowPosition.Top
	)
	self:SetSize(
		310, -- Settings.WindowPosition.Width,
		Settings.WindowPosition.Height
	)

	self:SetVisible(Settings.WindowVisible);

	-- ------------------------------------------------------------------------
	-- Update node values
	-- ------------------------------------------------------------------------

	self:Refresh()

    self.VisibleChanged = function(sender, args)
	    Settings.WindowVisible = self:IsVisible()
	end
end

-- ----------------------------------------------------------------------------
-- Layout elements
-- ----------------------------------------------------------------------------

function StatBrowser:SizeChanged( sender, args )

	self.statlist:SetPosition( 20, 40 );
	self.statlist:SetSize(
	    self:GetWidth() - 2*20,
	    self:GetHeight() - (40 + 40)
    );

    -- ------------------------------------------------------------------------

	self.refreshbtn:SetSize( 60, 20 );
	self.refreshbtn:SetPosition(
		30 + 0,
		self:GetHeight() - 32
	);

	if self["sharebtn"] ~= nil then
	    self.sharebtn:SetSize(60, 20);
	    self.sharebtn:SetPosition(
		    30 + 65,
		    self:GetHeight() - 32
	    );
    end

	self.referencebtn:SetWidth(60);
	self.referencebtn:SetPosition(
		40 + 120,
		self:GetHeight() - 32
	);

	self.formatbtn:SetWidth( 60 );
	self.formatbtn:SetPosition(
		40 + 180,
		self:GetHeight() - 32
	);

end

-- ----------------------------------------------------------------------------
-- Update stat node values
-- ----------------------------------------------------------------------------

function StatBrowser:Refresh()

	if not self:IsVisible() then
		return
	end

	xDEBUG("Updating...")

	local nodes = self.statlist:GetNodes()
	local count = nodes:GetCount();
	for i = 1, count do
		local node = nodes:Get( i );
		node:Refresh();
	end
end

-- ----------------------------------------------------------------------------
-- Save settings on unload
-- ----------------------------------------------------------------------------

function StatBrowser:Unload()

	-- ------------------------------------------------------------------------
	-- Store window position & size
	-- ------------------------------------------------------------------------

	Settings.WindowPosition = {
	    Left = self:GetLeft(),
	    Top = self:GetTop(),
	    Height = self:GetHeight(),
	    Width = self:GetWidth()
	};

	Settings.ShareWindowPosition = {
	    Left = self.sharewindow:GetLeft(),
	    Top = self.sharewindow:GetTop(),
	    Height = self.sharewindow:GetHeight(),
	    Width = self.sharewindow:GetWidth()
	}

	Settings.ShowPercentages = percentages;

	-- ------------------------------------------------------------------------
	-- Store groups' expand information
	-- ------------------------------------------------------------------------

	Settings.ExpandedGroups = self.statlist:ExpandedGroups()

	-- ------------------------------------------------------------------------
	-- Save settings
	-- ------------------------------------------------------------------------

	plugin.SaveSettings(
		"StatWatchSettings",
		Settings
	)
	self:SetVisible( false );
end

-- ----------------------------------------------------------------------------
-- Create window
-- ----------------------------------------------------------------------------

local mainwnd = StatBrowser()

atexit(function(plugin) mainwnd:Unload() end)

-- ****************************************************************************
-- ****************************************************************************
--
-- Command line interface
--
-- ****************************************************************************
-- ****************************************************************************

local _cmd = Turbine.ShellCommand();

function _cmd:Execute(cmd, args)
	if ( args == "show" ) then
		mainwnd:SetVisible( true );
		mainwnd:Refresh()
	elseif ( args == "hide" ) then
		mainwnd:SetVisible( false );
	elseif ( args == "toggle" ) then
		mainwnd:SetVisible( not mainwnd:IsVisible() );
		mainwnd:Refresh()
	elseif ( args == "share" ) then
		mainwnd.sharebtn:MouseClick()
	else
		INFO("/stats [show | hide | toggle | share]")
	end
end

Turbine.Shell.AddCommand( "stats", _cmd );
_cmd:Execute()
atexit(function() Turbine.Shell.RemoveCommand(_cmd) end)

-- ****************************************************************************
-- ****************************************************************************
--
-- Event hooks to refresh stats. TODO: Check if we can install hooks for
-- trait changes
--
-- ****************************************************************************
-- ****************************************************************************

DEBUG("Setting hooks...")

function RefreshHandler(sender, args)
	mainwnd:Refresh()
	end

local hooks = HookTable({
	{ object = effects, event = "EffectAdded", callback = RefreshHandler },
	{ object = effects, event = "EffectRemoved", callback = RefreshHandler },
	{ object = effects, event = "EffectCleared", callback = RefreshHandler },

	{ object = equip, event = "ItemEquipped", callback = RefreshHandler },
	{ object = equip, event = "ItemUnequipped", callback = RefreshHandler },

	{ object = player, event = "MaxMoraleChanged", callback = RefreshHandler },
	{ object = player, event = "MaxPowerChanged", callback = RefreshHandler },
	{ object = player, event = "LevelChanged", callback = RefreshHandler },
})

hooks:Install()
atexit(function() hooks:Uninstall() end)

DEBUG("Done.")

