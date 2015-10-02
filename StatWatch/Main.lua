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
local _plugin = utils.PlugIn()

local println = utils.println
local INFO    = function(str) _plugin:INFO(str) end
local DEBUG   = function(str) _plugin:DEBUG(str) end
local xDEBUG  = function(str) _plugin:xDEBUG(str) end

-- ****************************************************************************

xDEBUG("Loading...");

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

local Settings = {
	WindowPosition = {
		Left = 0,
		Top  = 0,
		Width = 200,
		Height = 200
	},
	WindowVisible = true,
	ExpandedGroups = { },
	ShowPercentages = true,
}

Settings = Turbine.PluginData.Load(
		Turbine.DataScope.Character,
		"StatWatchSettings"
	) or Settings;

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
		self.fmt = function(number) return utils.FormatNumber(number) end
	end
	
	stats[key] = self
end

-- ----------------------------------------------------------------------------

function Stat:Value() return self.rawvalue() end
function Stat:AsPercent()
	return ToPercent( self.percentage, self:Value(), player:GetLevel() )
	end

function Stat:AsString()
	if type(self.rawvalue) == "string" then
		return self.rawvalue
	elseif percentages and self.percentage then
		return FormatPercentage(self:AsPercent())
	else
		return self.fmt( self:Value() )
	end
end

function Stat:DiffAsString()
	if self.refvalue == nil then return "" end
	diff = self:Value() - self.refvalue
	if math.abs(diff) < 0.1 then
		return ""
	elseif percentages and self.percentage then
		diff = self:AsPercent() - ToPercent( self.percentage, self.refvalue, player:GetLevel() )
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

Stat("ICMR", function() return attr:GetInCombatMoraleRegeneration() end, nil, function(v) return utils.FormatNumber(v, 1) end)
Stat("ICPR", function() return attr:GetInCombatPowerRegeneration() end, nil, function(v) return utils.FormatNumber(v, 1) end)

Stat("Armor", function() return attr:GetArmor() end)
Stat("Might", function() return attr:GetMight() end)
Stat("Agility", function() return attr:GetAgility() end)
Stat("Vitality", function() return attr:GetVitality() end)
Stat("Will", function() return attr:GetWill() end)
Stat("Fate", function() return attr:GetFate() end)

Stat("CritRate", function() return attr:GetBaseCriticalHitChance() end, "CritRate")
Stat("CritMag", function() return ToPercent("CritMag", stats["CritRate"]:Value(), player:GetLevel()) end, nil, FormatPercentageInc)
Stat("DevRate", function() return ToPercent("DevRate", stats["CritRate"]:Value(), player:GetLevel()) end, nil, FormatPercentage)

Stat("Finesse", function() return attr:GetFinesse() end, "Finesse")
Stat("PhysMast", function() return math.max(attr:GetMeleeDamage(), attr:GetRangeDamage()) end, "Mastery")
Stat("TactMast", function() return attr:GetTacticalDamage() end, "Mastery")

Stat("Resistance", function() return attr:GetBaseResistance() end, "Resistance")
Stat("CritDef", function() return attr:GetBaseCriticalHitAvoidance() end, "CritDef")

Stat("HealOut", function() return attr:GetOutgoingHealing() end, "OutHeals")
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
		stats["Block"]:AsPercent() + 
		stats["Parry"]:AsPercent() +
		stats["Evade"]:AsPercent();
	end,
	nil,
	FormatPercentage
)

Stat("SelfHeal", function()
	return 100 *
		(1.0 + stats["HealIn"]:AsPercent()/100.0) *
		(1.0 + stats["HealOut"]:AsPercent()/100.0) - 100
	end,
	nil,
	FormatPercentageInc
)

Stat("CommonELM", function()
	return 1.0 / ( 
		-- (1 - stats["Avoidances"]:Value()/100.0) *
		(1 - stats["CommonMit"]:AsPercent()/100.0)
	)
	end,
	nil,
	FormatELM
)

Stat("TactELM", function()
	return 1.0 / ( 
		-- (1 - stats["Avoidances"]:Value()/100.0) *
		(1 - stats["TactMit"]:AsPercent()/100.0)
	)
	end,
	nil,
	FormatELM
)

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

local StatNode = class( Turbine.UI.TreeNode )

function StatNode:Constructor( text, key )

	Turbine.UI.TreeNode.Constructor( self );

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

local StatSep = class( Turbine.UI.TreeNode )

function StatSep:Constructor()

	Turbine.UI.TreeNode.Constructor( self );

	self:SetSize( 240, 1 );
	self:SetBackColorBlendMode( Turbine.UI.BlendMode.AlphaBlend );

	-- self.frame = Turbine.UI.Control();
	-- self.frame:SetParent( self );
	-- self.frame:SetSize( self:GetSize() );
	self:SetBackColor( utils.focusColor );
	
end

function StatSep:Refresh()
end

-- ----------------------------------------------------------------------------
-- Stat Group
-- ----------------------------------------------------------------------------

local StatGroup = class( Turbine.UI.TreeNode )

function StatGroup:Constructor( name, nodes )

	Turbine.UI.TreeNode.Constructor( self );

	self.name = name;

	self:SetSize( 270, 16 );

	self.labelKey = Turbine.UI.Label();
	self.labelKey:SetParent( self );
	self.labelKey:SetLeft( 20 );
	self.labelKey:SetSize( 250, 16 );
	self.labelKey:SetTextAlignment( Turbine.UI.ContentAlignment.MiddleLeft );
	self.labelKey:SetText( name );
	-- self.labelKey:SetMouseVisible( false );

	self.iconExpand = Turbine.UI.Control();
	self.iconExpand:SetParent( self );
	self.iconExpand:SetSize( 16, 16 );
	self.iconExpand:SetBackground( utils.IconExpand );
	self.iconExpand:SetBlendMode( Turbine.UI.BlendMode.AlphaBlend );
	-- self.iconExpand:SetMouseVisible( false );

	self:SetBackground( utils.HeaderBackground );
		
	local childList = self:GetChildNodes();

	for i = 0, table.getn(nodes) do
		childList:Add( nodes[i] );
	end

	self.MouseClick = function( sender, args )
		local expanded = self:IsExpanded();
		if expanded then
			self.iconExpand:SetBackground( utils.IconCollapse );
		else
			self.iconExpand:SetBackground( utils.IconExpand );
		end
	end

	self:SetVisible( (visible and true) or false )

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

	self.frame = Turbine.UI.Control()
	self.frame:SetParent( self );
	self.frame:SetBackColor( utils.focusColor );	

	self.statlist = Turbine.UI.TreeView();
	self.statlist:SetParent( self );
	self.statlist:SetIndentationWidth( 20 );
	self.statlist:SetBackColor( utils.bgColor );

	self.scrollbar = Turbine.UI.Lotro.ScrollBar();
    self.scrollbar:SetOrientation( Turbine.UI.Orientation.Vertical );
    self.scrollbar:SetParent( self );
	self.scrollbar:SetBackColor( utils.bgColor );
	
	self.statlist:SetVerticalScrollBar( self.scrollbar );

	-- ------------------------------------------------------------------------
	-- Buttons
	-- ------------------------------------------------------------------------

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

	self.refreshbtn = Turbine.UI.Lotro.Button();
	self.refreshbtn:SetParent( self );
	self.refreshbtn:SetText( "Refresh" );
	self.refreshbtn.Click = function() 
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
				StatNode("Physical Mastery", "PhysMast"),
				StatNode("Tactical Mastery", "TactMast"),
				StatNode("Finesse", "Finesse"),
			}
		)
	);

	nodes:Add(
		StatGroup( "Healing",
			{
				StatNode("Outgoing", "HealOut"),
			}
		)
	);

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

	nodes:Add(
		StatGroup( "Experimental",
			{
				StatNode("Self-heal", "SelfHeal"),
				StatSep(),
				StatNode("Morale Mult.", ""),
				StatNode("- Common Damage", "CommonELM"),
				StatNode("- Tactical Damage", "TactELM"),
			}
		)
	);

	-- ------------------------------------------------------------------------
	-- Expand groups which were expanded last time
	-- ------------------------------------------------------------------------
	
	local count = nodes:GetCount();
	for i = 1, count do
		local node = nodes:Get( i );
		local expanded = (Settings.ExpandedGroups and Settings.ExpandedGroups[node.name]) or false;
		if expanded then
			xDEBUG(node.name .. " expanded: " .. tostring(expanded))
			node:Expand()
			node:MouseClick()
		end
	end

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
-- Resize and reposition elements after window resize
-- ----------------------------------------------------------------------------

function StatBrowser:SizeChanged( sender, args )

	self.frame:SetPosition(18, 38)
	self.frame:SetSize(self:GetWidth() - 2*18, self:GetHeight() - 2*38)

	self.statlist:SetPosition( 20, 40 );
	self.statlist:SetSize( self:GetWidth() - 2*20, self:GetHeight() - 2*40 );

    self.scrollbar:SetPosition( self:GetWidth() - 30, 40 );
    self.scrollbar:SetSize( 10, self:GetHeight() - 80 );

	self.refreshbtn:SetSize( 90, 20 );
	self.refreshbtn:SetPosition(
		40 + 0,
		self:GetHeight() - 32
	);

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

function StatBrowser:VisibleChanged(sender, args)
	Settings.WindowVisible = self:IsVisible()
end

-- ----------------------------------------------------------------------------
-- Save settings on unload
-- ----------------------------------------------------------------------------

function StatBrowser:Unload()

	-- ------------------------------------------------------------------------
	-- Store window position & size
	-- ------------------------------------------------------------------------

	Settings.WindowPosition.Left = self:GetLeft();
	Settings.WindowPosition.Top = self:GetTop();
	Settings.WindowPosition.Height = self:GetHeight();
	Settings.WindowPosition.Width = self:GetWidth();	
	-- Settings.WindowVisible = self:IsVisible();
	Settings.ShowPercentages = percentages;

	-- ------------------------------------------------------------------------
	-- Store groups' expand information
	-- ------------------------------------------------------------------------

	Settings.ExpandedGroups = { }
	
	local nodes = self.statlist:GetNodes()
	local count = nodes:GetCount();
	for i = 1, count do
		local node = nodes:Get( i );
		Settings.ExpandedGroups[node.name] = node:IsExpanded();
	end

	-- ------------------------------------------------------------------------
	-- Save settings
	-- ------------------------------------------------------------------------

	Turbine.PluginData.Save(
		Turbine.DataScope.Character,
		"StatWatchSettings",
		Settings
	)
	self:SetVisible( false );
end

-- ----------------------------------------------------------------------------
-- Create window
-- ----------------------------------------------------------------------------

local mainwnd = StatBrowser()

_plugin:atexit(function() mainwnd:Unload() end)

-- ****************************************************************************
-- ****************************************************************************
--
-- Command line interface
--
-- ****************************************************************************
-- ****************************************************************************

myCMD = Turbine.ShellCommand();

function myCMD:Execute(cmd, args)
	if ( args == "show" ) then
		mainwnd:SetVisible( true );
		mainwnd:Refresh()
	elseif ( args == "hide" ) then
		mainwnd:SetVisible( false );
	elseif ( args == "toggle" ) then
		mainwnd:SetVisible( not mainwnd:IsVisible() );
		mainwnd:Refresh()
	else
		INFO("/stats [show | hide | toggle]")
	end
end

Turbine.Shell.AddCommand( "stats", myCMD );
_plugin:atexit(function() Turbine.Shell.RemoveCommand(myCMD) end)

INFO("/stats [show | hide | toggle]" )

-- ****************************************************************************
-- ****************************************************************************
--
-- Event hooks to refresh stats. TODO: Check if we can install hooks for
-- trait changes
--
-- ****************************************************************************
-- ****************************************************************************

function RefreshHandler(sender, args)
	mainwnd:Refresh()
	end

local _hooks = {
	{ object = effects, event = "EffectAdded", callback = RefreshHandler },
	{ object = effects, event = "EffectRemoved", callback = RefreshHandler },
	{ object = effects, event = "EffectCleared", callback = RefreshHandler },

	{ object = equip, event = "ItemEquipped", callback = RefreshHandler },
	{ object = equip, event = "ItemUnequipped", callback = RefreshHandler },

	{ object = player, event = "MaxMoraleChanged", callback = RefreshHandler },
	{ object = player, event = "MaxPowerChanged", callback = RefreshHandler },
	{ object = player, event = "LevelChanged", callback = RefreshHandler },
}

function InstallHooks()
	for i = 1, table.getn(_hooks) do
		if _hooks[i].object ~= nil then
			utils.AddCallback(_hooks[i].object, _hooks[i].event, _hooks[i].callback)
		end
	end
end
	
function UninstallHooks()
	for i = 1, table.getn(_hooks) do
		if _hooks[i].object ~= nil then
			utils.RemoveCallback(_hooks[i].object, _hooks[i].event, _hooks[i].callback)
		end
	end
end

InstallHooks()
_plugin:atexit(UninstallHooks)
