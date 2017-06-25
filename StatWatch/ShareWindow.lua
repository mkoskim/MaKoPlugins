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

    self.channelbtn = Utils.UI.DropDown({"", "/f", "/ra", "/k" })
    self.channelbtn:SetParent( self );

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
        local channel = self.channelbtn:GetText()
        if channel == "" then
            channel = self.namebox:GetText()
        end

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

    self.channelbtn:SetWidth(60);
    self.channelbtn:SetPosition(20, btntop)

    self.namebox:SetSize(
        self:GetWidth() - (20 + 65) - (5 + 60 + 5 + 35) - 20,
        18
    );
    self.namebox:SetPosition(20 + 65, btntop + 1)

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
    self.groups["MoralePower"]:SetText(
        string.format("Morale..: %s", self.stats["Morale"]:AsString()) .. "\n" ..
        string.format("Power...: %s", self.stats["Power"]:AsString())
    )

    self.groups["Regen"]:SetText(
        string.format("ICMR...: %s (%s / s)",
            FormatNumber(self.stats["ICMR"]:Rating() * 60),
            self.stats["ICMR"]:AsString()
        )  .. "\n" ..
        string.format("ICPR....: %s (%s / s)",
            FormatNumber(self.stats["ICPR"]:Rating() * 60),
            self.stats["ICPR"]:AsString()
        )
    )

    self.groups["BasicStats"]:SetText(
        string.format("Might.....: %s", self.stats["Might"]:AsString())  .. "\n" ..
        string.format("Agility....: %s", self.stats["Agility"]:AsString())  .. "\n" ..
        string.format("Vitality...: %s", self.stats["Vitality"]:AsString())  .. "\n" ..
        string.format("Will........: %s", self.stats["Will"]:AsString())  .. "\n" ..
        string.format("Fate......: %s", self.stats["Fate"]:AsString())
    )

    self.groups["Offence"]:SetText(
        string.format("Critical Rating....: %s - %s",
            self.stats["CritRate"]:AsString(),
            self.stats["CritRate"]:AsString(true)
        ) .. "\n" ..
        string.format("Finesse.............: %s - %s",
            self.stats["Finesse"]:AsString(),
            self.stats["Finesse"]:AsString(true)
        ) .. "\n" ..
        string.format("Physical Mastery: %s - %s",
            self.stats["PhysMast"]:AsString(),
            self.stats["PhysMast"]:AsString(true)
        ) .. "\n" ..
        string.format("Tactical Mastery: %s - %s",
            self.stats["TactMast"]:AsString(),
            self.stats["TactMast"]:AsString(true)
        ) .. "\n" ..
        string.format("Outgoing Healing: %s",
            self.stats["OutHeals"]:AsString(true)
        )
    )

    self.groups["Defence"]:SetText(
        string.format("Resistance........: %s - %s",
            self.stats["Resistance"]:AsString(),
            self.stats["Resistance"]:AsString(true)
        ) .. "\n" ..
        string.format("Critical Defence.: %s - %s",
            self.stats["CritDef"]:AsString(),
            self.stats["CritDef"]:AsString(true)
        ) .. "\n" ..
        string.format("Incoming Healing: %s - %s",
            self.stats["IncHeals"]:AsString(),
            self.stats["IncHeals"]:AsString(true)
        )
    )

    self.groups["Avoidance"]:SetText(
        string.format("Block.: %s - %s",
            self.stats["Block"]:AsString(),
            self.stats["Block"]:AsString(true)
        ) .. "\n" ..
        string.format("Parry.: %s - %s",
            self.stats["Parry"]:AsString(),
            self.stats["Parry"]:AsString(true)
        ) .. "\n" ..
        string.format("Evade: %s - %s",
            self.stats["Evade"]:AsString(),
            self.stats["Evade"]:AsString(true)
        )
        --[[.. "\n\n" ..
        string.format("BPE (Full): %s", self.stats["Avoidances"]:AsString())
        .. "\n" ..
        string.format("BPE (Partial): %s", self.stats["Partials"]:AsString())
        .. "\n" ..
        string.format("Avoid Chance: %s",
            self.stats["AvoidChance"]:RatingAsString()
        )
        --]]
    )

    self.groups["Mitigations"]:SetText(
        string.format("Phys. Mitigation..: %s - %s",
            self.stats["CommonMit"]:AsString(),
            self.stats["CommonMit"]:AsString(true)
        ) .. "\n" ..
        string.format("Tact. Mitigation..: %s - %s",
            self.stats["TactMit"]:AsString(),
            self.stats["TactMit"]:AsString(true)
        ) .. "\n" ..
        string.format("OC/FW Mitigation: %s - %s",
            self.stats["PhysMit"]:AsString(),
            self.stats["PhysMit"]:AsString(true)
        )
    )
end

