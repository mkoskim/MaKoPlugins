-- ****************************************************************************
-- ****************************************************************************
--
-- Share window: This is bit hairy. We need to create a shortcut, which
-- contains alias, which contains command to send a line to correct
-- channel.
--
-- ****************************************************************************
-- ****************************************************************************

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

function StatShareWindow:Constructor(Settings)
	Utils.UI.Window.Constructor(self);

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
                player:GetName(), Utils.ClassAsString[player:GetClass()], player:GetLevel(),
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
        )
        .. "\n\n" ..
        string.format("BPE (Full): %s", stats["Avoidances"]:RatingAsString())
        .. "\n" ..
        string.format("BPE (Partial): %s", stats["Partials"]:RatingAsString())
        .. "\n" ..
        string.format("Avoid Chance: %s",
            stats["AvoidChance"]:RatingAsString()
        )
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

