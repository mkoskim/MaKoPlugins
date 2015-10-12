-- ****************************************************************************
-- ****************************************************************************
--
-- Quickslot combined with label, and automatic naming feature
--
-- ****************************************************************************
-- ****************************************************************************

-- ----------------------------------------------------------------------------
-- Load and patch moebius' skill data
-- ----------------------------------------------------------------------------

local function LoadSkillData()
    import "moebius92.SkillData"

    -- Promotional mounts
    moebius92.SkillData.shortcut["0x7002E78E"] = "Steed of the Eastemnet"

    -- Standard mounts
    moebius92.SkillData.shortcut["0x7001B4B7"] = "Bay Horse"

    -- Reputation mounts
    moebius92.SkillData.shortcut["0x70022C8B"] = "Prized Thorin's Hall Goat"
    moebius92.SkillData.shortcut["0x7001B4B8"] = "Prized Nimble Redhorn-goat"
    moebius92.SkillData.shortcut["0x7001B4B4"] = "Prized Tame Redhorn-goat"
    moebius92.SkillData.shortcut["0x700249EA"] = "Prized Angmar's Free Peoples Horse"

    -- Deed mounts
    moebius92.SkillData.shortcut["0x7001B4D9"] = "Grey Horse"

    -- Warsteeds
    moebius92.SkillData.shortcut["0x7003041B"] = "Warsteed: Medium"

    -- Festival & Event Mounts
    moebius92.SkillData.shortcut["0x70042C0E"] = "Faltharan's Steed"
end

local hasSkillData = pcall(LoadSkillData)

if not hasSkillData then
    println("WARNING: Skill data not installed.")
end

-- ----------------------------------------------------------------------------
-- Quickslot with label. If label text is not set, it is determined
-- automatically from shortcut dragged to slot.
-- ----------------------------------------------------------------------------

LabelledQuickslot = class(Turbine.UI.Control)

function LabelledQuickslot:Constructor()
    Turbine.UI.Control.Constructor(self)

    self:SetBackColor(Turbine.UI.Color.Blue)

    self.label = Turbine.UI.Label()
    self.label:SetParent(self)
    self.label:SetMultiline(true)
    self.label.auto = true

    self.slot = Quickslot()
    self.slot:SetParent(self)

    self.slot.ShortcutChanged = function(sender, args)
        if self.label.auto then self:AutoName() end
    end
end

function LabelledQuickslot:AutoName()
    local s = self.slot:GetShortcut()
    local t = s:GetType()
    if t == Turbine.UI.Lotro.ShortcutType.Alias then
        self.label:SetText("Alias")
    elseif t == Turbine.UI.Lotro.ShortcutType.Item then
        self.label:SetText(s:GetItem():GetName())
    elseif t == Turbine.UI.Lotro.ShortcutType.Skill then
        local data = hasSkillData and moebius92.SkillData.shortcut[s:GetData()] or nil
        if data == nil then
            self.label:SetText(s:GetData())
            -- println("%s", s:GetData())
        else
            self.label:SetText(data)
        end
    else
        self.label:SetText("Unknown")
    end
end

function LabelledQuickslot:SetSize(w, h)
    Turbine.UI.Control.SetSize(self, w, h)
    self.label:SetPosition(4, 4)
    self.label:SetSize(w - 40 - 4, h - 8)
    self.slot:SetPosition(w - 40, 0)
end

function LabelledQuickslot:SetText(text)
    self.label:SetText(text)
    self.label.auto = (text == nil)
    if self.label.auto then self:AutoName() end
end

