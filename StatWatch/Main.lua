-- ****************************************************************************
-- ****************************************************************************
--
-- Plugin for real-time stat watching
--
-- ****************************************************************************
-- ****************************************************************************

-- ****************************************************************************
--
-- Import utils and bring some functions to local namespace
--
-- ****************************************************************************

import "MaKoPlugins.StatWatch.Bindings"
import "MaKoPlugins.StatWatch.Stats"
import "MaKoPlugins.StatWatch.Migration"
import "MaKoPlugins.StatWatch.ShareWindow"

-- ****************************************************************************
-- ****************************************************************************
--
-- Plugin settings (autoload settings at startup). When changing settings
-- (adding, modifying or removing entries), increase SettingsVersion, and add
-- correct migration to Migration.Migrate().
--
-- ****************************************************************************
-- ****************************************************************************

local Settings = Migrate(
    PlugIn:LoadSettings("StatWatchSettings"),
    {
        SettingsVersion = 3,

        ExpandedGroups = { },
        ShowPercentages = true,

        BrowseWindow = {
            Left = 0, Top  = 0,
            Width = 200, Height = 200,
            Visible = true,
            Toggle = {
                Left = 200, Top = 0, Visible = true
            }
        },

        ShareWindow = {
            Left = 0, Top = 0,
            Width = 200, Height = 200,
            Visible = false,
            Toggle = {
                Left = 230, Top = 0, Visible = true
            }
        },
        
        Modifiers = {
            Active = "T1",
        }
    }
)

-- ****************************************************************************
-- ****************************************************************************

local player  = Turbine.Gameplay.LocalPlayer:GetInstance();
player.attr   = player:GetAttributes();

-- ----------------------------------------------------------------------------

local stats = Stats(player)

local function SetReference()
    stats.reference = { }
    for key, value in pairs(stats.ratings) do
        stats.reference[key] = value
    end
end

local function SetCapReference()
    stats.reference = CapRatings(player:GetLevel(), ArmorType[player:GetClass()])
    Ratings.sub(stats.reference, stats.modifier.hidden)
    -- dumptable(stats.reference)
end

local function ClearReference()
    stats.reference = { }
end

local function SetModifierT1()
    stats.modifier.hidden = { }
end

local function SetModifierT2()
    stats.modifier.hidden = T2Modifiers(player:GetLevel())
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

local StatNode = class( Utils.UI.TreeNode )

function StatNode:Constructor( text, key )

	Utils.UI.TreeNode.Constructor( self );

	self.text  = text
    self.key   = key ~= nil and key or text

	self:SetSize( 240, 16 );

	self:SetBackColorBlendMode( Turbine.UI.BlendMode.AlphaBlend );
	self.labelText = Turbine.UI.Label();
	self.labelText:SetParent( self );
	self.labelText:SetSize( 120, 16 );
	self.labelText:SetTextAlignment( Turbine.UI.ContentAlignment.MiddleLeft );
    self.labelText:SetMultiline(false)
	self.labelText:SetText( self.text );
	
	self.labelValue = Turbine.UI.Label();
	self.labelValue:SetParent( self );
	self.labelValue:SetSize( 60, 16 );
	self.labelValue:SetLeft( 120 );
	self.labelValue:SetTextAlignment( Turbine.UI.ContentAlignment.MiddleRight );
    self.labelValue:SetMultiline(false)

	self.labelRef = Turbine.UI.Label();
	self.labelRef:SetParent( self );
	self.labelRef:SetSize( 60, 16 );
	self.labelRef:SetLeft( 180 );
	self.labelRef:SetTextAlignment( Turbine.UI.ContentAlignment.MiddleRight );
    self.labelRef:SetMultiline(false)
end

function StatNode:Refresh()
	xDEBUG("Updating: " .. self.key)

	local stat = stats[self.key]

	if stat ~= nil then
		self.labelValue:SetText( stat:AsString(Settings.ShowPercentages) );
		-- self.labelRef:SetText( stat:RefAsString(Settings.ShowPercentages) );
		local diff = stat:DiffAsString(Settings.ShowPercentages)
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

local StatSep = class( Utils.UI.TreeSeparator )

function StatSep:Refresh() end

-- ----------------------------------------------------------------------------
-- Stat Group
-- ----------------------------------------------------------------------------

local StatGroup = class( Utils.UI.TreeGroup )

function StatGroup:Constructor( name, nodes )

    Utils.UI.TreeGroup.Constructor(self);

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

BrowseWindow = class(Utils.UI.Window);

function BrowseWindow:Constructor()
	Utils.UI.Window.Constructor(self);

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

    self.statlist = Utils.UI.TreeView()
    self.statlist:SetParent(self)

	-- ------------------------------------------------------------------------
	-- Elements to share builds
	-- ------------------------------------------------------------------------

    self.sharewindow = StatShareWindow(Settings, stats)

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

    self.modifiers = {
        ["T1"]       = SetModifierT1,
        ["T2"]       = SetModifierT2,
        ["T2 - 108"] = SetModifierT2,
    }
    self.references = {
        [""]      = ClearReference,
        ["Cap"]   = SetCapReference,
        ["Set 1"] = function() SetReference(1) end,
        ["Set 2"] = function() SetReference(2) end,
        ["Set 3"] = function() SetReference(3) end,
        ["Set 4"] = function() SetReference(4) end,
    }

	self.modbtn = Utils.UI.DropDown({"T1", "T2", "T2 - 108"});
	self.modbtn:SetParent( self );
	self.modbtn:SetText(Settings.Modifiers.Active);
	self.modbtn.ItemChanged = function(sender, args) 
		self.modifiers[args.Text]()
		if self.referencebtn.GetText() == "Cap" then SetCapReference() end
		Settings.Modifiers.Active = args.Text
		self:Refresh();
		if self.sharewindow:IsVisible() then
		    self.sharewindow:Refresh()
		end
	end

	self.formatbtn = Utils.UI.DropDown({"#", "%"});
	self.formatbtn:SetParent( self );
	self.formatbtn:SetText(Settings.ShowPercentages and "%" or "#");
	self.formatbtn.ItemChanged = function(sender, args) 
		Settings.ShowPercentages = (args.Index == 2)
		self:Refresh();
	end

	self.referencebtn = Utils.UI.DropDown({"", "Cap", "Set 1", "Set 2", "Set 3", "Set 4"});
	self.referencebtn:SetParent( self );
	self.referencebtn:SetText( "" );
	self.referencebtn.ItemChanged = function(sender, args)
		self.references[args.Text]()
		self:Refresh();
	end

    self.modifiers[Settings.Modifiers.Active]()
    self.references[""]()

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
				StatNode("- Outgoing Healing", "OutHeals"),
			}
		)
	);

	nodes:Add(
		StatGroup( "Defence",
			{
				StatNode("Resistance"),
				StatNode("Critical Defence", "CritDef"),
				StatNode("Incoming Healing", "IncHeals"),
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
				StatNode("", "BPEChance"),
				StatSep(),
				StatNode("Partial Block", "PartialBlock"),
				StatNode("Partial Parry", "PartialParry"),
				StatNode("Partial Evade", "PartialEvade"),
				StatSep(),
				StatNode("", "Partials"),
				StatSep(),
				StatNode("Avoid Chance", "AvoidChance"),
			}
		)
	);
	
	nodes:Add(
		StatGroup( "Partial Mitigations",
			{
				StatNode("Partial Block", "PartialBlockMit"),
				StatNode("Partial Parry", "PartialParryMit"),
				StatNode("Partial Evade", "PartialEvadeMit"),
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
				StatNode("Effective Morale", ""),
				StatNode("- Common Damage", "EffectiveMoraleCommon"),
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

    self.toggle = Utils.UI.ToggleWindowButton("stats", self)
    self.toggle:Deserialize(Settings.BrowseWindow.Toggle)

    self:Deserialize(Settings.BrowseWindow)

	-- ------------------------------------------------------------------------
	-- Update node values
	-- ------------------------------------------------------------------------

	-- self:Refresh()

    -- self.VisibleChanged = function(sender, args)
	--    Settings.WindowVisible = self:IsVisible()
	-- end
end

-- ----------------------------------------------------------------------------
-- Layout elements
-- ----------------------------------------------------------------------------

function BrowseWindow:SizeChanged( sender, args )

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

	self.modbtn:SetWidth(60);
	self.modbtn:SetPosition(
	    30 + 65,
	    self:GetHeight() - 32
	);
    
	self.referencebtn:SetWidth(60);
	self.referencebtn:SetPosition(
		40 + 120,
		self:GetHeight() - 32
	);

	self.formatbtn:SetWidth(60);
	self.formatbtn:SetPosition(
		40 + 180,
		self:GetHeight() - 32
	);

end

-- ----------------------------------------------------------------------------
-- Update stat node values
-- ----------------------------------------------------------------------------

function BrowseWindow:Refresh()

	--[[
	if not self:IsVisible() then
		return
	end
    ]]--

	xDEBUG("BrowseWindow:Refresh")

    stats:Refresh(player)

	local nodes = self.statlist:GetNodes()
	local count = nodes:GetCount();
	for i = 1, count do
		local node = nodes:Get( i );
		node:Refresh();
	end
end

function BrowseWindow:SetVisible(state)
    Utils.UI.Window.SetVisible(self, state)
    if state then self:Refresh() end
end

-- ----------------------------------------------------------------------------
-- Save settings on unload
-- ----------------------------------------------------------------------------

function BrowseWindow:Unload()
	Settings.BrowseWindow = self:Serialize()
    Settings.BrowseWindow.Toggle = self.toggle:Serialize()

	Settings.ShareWindow  = self.sharewindow:Serialize()
    Settings.ShareWindow.Toggle = self.sharewindow.toggle:Serialize()

	Settings.ExpandedGroups = self.statlist:ExpandedGroups()

	Settings.Modifiers.Active = self.modbtn:GetText()

	-- ------------------------------------------------------------------------
	-- Save settings
	-- ------------------------------------------------------------------------

	PlugIn:SaveSettings("StatWatchSettings", Settings)
end

-- ----------------------------------------------------------------------------
-- Create window
-- ----------------------------------------------------------------------------

local mainwnd = BrowseWindow()

atexit(function() mainwnd:Unload() end)

-- ****************************************************************************
-- ****************************************************************************
--
-- Options panel
--
-- ****************************************************************************
-- ****************************************************************************

OptionsPanel = class(Turbine.UI.Control)

function OptionsPanel:Constructor()
    Turbine.UI.Control.Constructor(self)
    
    self:SetSize(200, 300)

    local checkbox1 = Turbine.UI.Lotro.CheckBox()
    checkbox1:SetParent(self)
    checkbox1:SetPosition(10, 10)
    checkbox1:SetSize(280, 20)
    checkbox1:SetText("Browse window toggle button")

    checkbox1:SetChecked(mainwnd.toggle:IsVisible())
    checkbox1.CheckedChanged = function(sender, args)
        mainwnd.toggle:SetVisible(checkbox1:IsChecked())
    end

    local checkbox2 = Turbine.UI.Lotro.CheckBox()
    checkbox2:SetParent(self)
    checkbox2:SetPosition(10, 30)
    checkbox2:SetSize(280, 20)
    checkbox2:SetText("Share window toggle button")

    checkbox2:SetChecked(mainwnd.sharewindow.toggle:IsVisible())
    checkbox2.CheckedChanged = function(sender, args)
        mainwnd.sharewindow.toggle:SetVisible(checkbox2:IsChecked())
    end

end

PlugIn:SetOptionsPanel(OptionsPanel())

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
		-- mainwnd:Refresh()
	elseif ( args == "hide" ) then
		mainwnd:SetVisible( false );
	elseif ( args == "toggle" ) then
		mainwnd:SetVisible( not mainwnd:IsVisible() );
		-- mainwnd:Refresh()
	elseif ( args == "share" ) then
		mainwnd.sharewindow:SetVisible( not mainwnd.sharewindow:IsVisible() );
	else
		INFO("/%s [show | hide | toggle | share]", cmd)
	end
end

Turbine.Shell.AddCommand( "stats", _cmd );
_cmd:Execute("stats")
atexit(function() Turbine.Shell.RemoveCommand(_cmd) end)

-- ****************************************************************************
-- ****************************************************************************
--
-- Event hooks to refresh stats. TODO: Check if we can install hooks for
-- trait changes
--
-- ****************************************************************************
-- ****************************************************************************

function RefreshHandler(sender, args)
	if mainwnd:IsVisible() then mainwnd:Refresh() end
	end

local effects = player:GetEffects()
local equip   = player:GetEquipment()

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

