-- ****************************************************************************
-- ****************************************************************************
--
-- Share window: This is bit hairy. We need to create a shortcut, which
-- contains alias, which contains command to send a line to correct
-- channel.
--
-- ****************************************************************************
-- ****************************************************************************

import "MaKoPlugins.StatWatch.Stats"
import "MaKoPlugins.StatWatch.Formatting"

StatShareGroup = class(Utils.UI.TreeGroup)

function StatShareGroup:Constructor(name)
    Utils.UI.TreeGroup.Constructor(self);

	self:SetSize( 270, 16 );

	self.labelKey = Turbine.UI.Label();
	self.labelKey:SetParent( self );
	self.labelKey:SetLeft( 20 );
	self.labelKey:SetSize( 250, 16 );
	self.labelKey:SetTextAlignment( Turbine.UI.ContentAlignment.MiddleLeft );
	self.labelKey:SetText( name );

    self.node = Utils.UI.TreeNode()

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

StatShareWindow = class(Utils.UI.Window)

function StatShareWindow:Constructor(Settings, stats)
	Utils.UI.Window.Constructor(self);

    -- ------------------------------------------------------------------------

    self.stats = stats

    -- ------------------------------------------------------------------------

	self:SetText("Share stats");

	self:SetMinimumWidth(310);
	self:SetMaximumWidth(310);

	self:SetResizable(true);

    -- ------------------------------------------------------------------------

    self.chooser = Utils.UI.TreeView()
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
        "Defence", "Avoidance",
        "Mitigations",
    }

    for _, key in pairs(self.order) do
        local group = self.groups[key]
        self.chooser:GetNodes():Add( group )
        group:SetExpanded(false)
    end

    -- ------------------------------------------------------------------------

    --[[
    self.channelbtn = Utils.UI.DropDown({"", "/f", "/ra", "/k" })
    self.channelbtn:SetParent( self );
    ]]--

    self.namebox = Utils.UI.ScrolledTextBox()
    self.namebox:SetParent(self)
    self.namebox:SetMultiline(false)
    self.namebox:SetTextAlignment( Turbine.UI.ContentAlignment.MiddleLeft );
    self.namebox:SetText("")

    self.sendbtn = Utils.UI.QuickslotButton(
        -- Utils.UI.IconButton(Utils.UI.Icons.ChatBubble)
    )
    -- self.sendbtn:SetSize(16, 16)
    self.sendbtn:SetText("Send")
    self.sendbtn:SetSize( 37, 20 );
    self.sendbtn:SetParent( self )
    self.sendbtn.quickslot.MouseClick = function(sender, args)
        self.sendbtn:SetEnabled(false)
    end
    -- self.sendbtn.quickslot:SetVisible(false)

    self.createbtn = Turbine.UI.Lotro.Button()
    self.createbtn:SetParent( self );
    self.createbtn:SetText("Create")
    self.createbtn.MouseClick = function(sender, args)

    --[[
        local channel = self.channelbtn:GetText()
        if channel == "" then
            channel = self.namebox:GetText()
        end
    ]]--
        local channel = self.namebox:GetText()

        local text = { }
        for _, key in pairs(self.order) do
            local group = self.groups[key]
            if group:IsExpanded() then
                table.insert(text, group:GetText())
            end
        end

        text = table.concat(text, "\n- - - - - - - - - - - - - - -\n")

        self.sendbtn:SetShortcut(Turbine.UI.Lotro.Shortcut(
            Turbine.UI.Lotro.ShortcutType.Alias,
            string.format("%s Stats %s (%s @ %d):\n%s",
                channel,
                self.stats.player:GetName(),
                Utils.ClassAsString[self.stats.player:GetClass()],
                self.stats.player:GetLevel(),
                text
            )
        ))
        -- self.sendbtn:SetEnabled.quickslot:SetVisible(true)
    end


    -- ------------------------------------------------------------------------

    self.toggle = Utils.UI.ToggleWindowButton("share", self)
    self.toggle:Deserialize(Settings.ShareWindow.Toggle)

    -- ------------------------------------------------------------------------

    self:Deserialize(Settings.ShareWindow)

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

    local btntop = self:GetHeight() - 45

    --[[
    self.channelbtn:SetWidth(60);
    self.channelbtn:SetPosition(20, btntop)
    ]]--

    self.namebox:SetSize(
        self:GetWidth() - (20) - (5 + 60 + 5 + 35) - 20,
        18
    );
    self.namebox:SetPosition(20, btntop + 1)

    -- ------------------------------------------------------------------------

    self.createbtn:SetSize( 60, 18 );
    self.createbtn:SetPosition(
        self:GetWidth() - 60 - 35 - 25,
        btntop
    );

    self.sendbtn:SetPosition(
        self:GetWidth()  - 35 - 20,
        btntop
    );
end

-- ----------------------------------------------------------------------------
-- 
-- ----------------------------------------------------------------------------

function StatShareWindow:SetVisible(state)
    Utils.UI.Window.SetVisible(self, state)
    if state then self:Refresh() end
end

-- ----------------------------------------------------------------------------
-- Creating string from stats: this is aimed to be used to share
-- builds with people
-- ----------------------------------------------------------------------------

function StatShareWindow:Refresh()
    local L = self.stats.ratings.ID.Level

    self.groups["MoralePower"]:SetText(
        string.format("Morale..: %s", FormatNumber(self.stats:Rating("Morale"))) .. "\n" ..
        string.format("Power...: %s", FormatNumber(self.stats:Rating("Power")))
    )

    self.groups["Regen"]:SetText(
        string.format("ICMR...: %s (%s / s)",
            FormatNumber(self.stats:Rating("ICMR") * 60),
            FormatNumber(self.stats:Rating("ICMR"), 1)
        )  .. "\n" ..
        string.format("ICPR...: %s (%s / s)",
            FormatNumber(self.stats:Rating("ICPR") * 60),
            FormatNumber(self.stats:Rating("ICPR"), 1)
        )
    )

    self.groups["BasicStats"]:SetText(
        string.format("Might.....: %s",   FormatNumber(self.stats:Rating("Might"))) .. "\n" ..
        string.format("Agility...: %s",  FormatNumber(self.stats:Rating("Agility"))) .. "\n" ..
        string.format("Vitality..: %s",  FormatNumber(self.stats:Rating("Vitality"))) .. "\n" ..
        string.format("Will......: %s", FormatNumber(self.stats:Rating("Will")))  .. "\n" ..
        string.format("Fate......: %s",   FormatNumber(self.stats:Rating("Fate")))
    )

    self.groups["Offence"]:SetText(
        string.format("Critical Rating.: %s - %s",
            FormatNumber(self.stats:Rating("CritRate")),
            FormatPercent(self.stats:Percent("CritRate", L))
        ) .. "\n" ..
        string.format("Finesse.........: %s - %s",
            FormatNumber(self.stats:Rating("Finesse")),
            FormatPercent(self.stats:Percent("Finesse", L))
        ) .. "\n" ..
        string.format("Physical Mastery: %s - %s",
            FormatNumber(self.stats:Rating("PhysMast")),
            FormatPercent(self.stats:Percent("PhysMast", L)) or "xxx"
        ) .. "\n" ..
        string.format("Tactical Mastery: %s - %s",
            FormatNumber(self.stats:Rating("TactMast")),
            FormatPercent(self.stats:Percent("TactMast", L)) or "xxx"
        ) .. "\n" ..
        string.format("Outgoing Healing: %s",
            FormatPercent(self.stats:Percent("OutHeals", L))
        )
    )

    self.groups["Defence"]:SetText(
        string.format("Resistance.......: %s - %s",
            FormatNumber(self.stats:Rating("Resistance")),
            FormatPercent(self.stats:Percent("Resistance", L))
        ) .. "\n" ..
        string.format("Critical Defence.: %s - %s",
            FormatNumber(self.stats:Rating("CritDef")),
            FormatPercent(self.stats:Percent("CritDef", L))
        ) .. "\n" ..
        string.format("Incoming Healing.: %s - %s",
            FormatNumber(self.stats:Rating("IncHeals")),
            FormatPercent(self.stats:Percent("IncHeals", L)) or "xxx"
        )
    )

    self.groups["Avoidance"]:SetText(
        string.format("Block.: %s - %s",
            FormatNumber(self.stats:Rating("Block")),
            FormatPercent(self.stats:Percent("Block", L))
        ) .. "\n" ..
        string.format("Parry.: %s - %s",
            FormatNumber(self.stats:Rating("Parry")),
            FormatPercent(self.stats:Percent("Parry", L))
        ) .. "\n" ..
        string.format("Evade.: %s - %s",
            FormatNumber(self.stats:Rating("Evade")),
            FormatPercent(self.stats:Percent("Evade", L))
        )
--[[
        .. "\n\n" ..
        string.format("BPE (Full): %s", self.stats["Avoidances"]:AsString())
        .. "\n" ..
        string.format("BPE (Partial): %s", self.stats["Partials"]:AsString())
        .. "\n" ..
        string.format("Avoid Chance: %s",
            self.stats["AvoidChance"]:RatingAsString()
        )
]]--
    )

    self.groups["Mitigations"]:SetText(
        string.format("Phys. Mitigation..: %s - %s",
            FormatNumber(self.stats:Rating("CommonMit")),
            FormatPercent(self.stats:Percent("CommonMit", L))
        ) .. "\n" ..
        string.format("Tact. Mitigation..: %s - %s",
            FormatNumber(self.stats:Rating("TactMit")),
            FormatPercent(self.stats:Percent("TactMit", L))
        ) .. "\n" ..
        string.format("OC/FW Mitigation..: %s - %s",
            FormatNumber(self.stats:Rating("PhysMit")),
            FormatPercent(self.stats:Percent("PhysMit", L))
        )
    )
end

