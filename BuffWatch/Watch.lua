-- ****************************************************************************
-- ****************************************************************************
--
-- Effect Watch Engine
--
-- ****************************************************************************
-- ****************************************************************************

-- ----------------------------------------------------------------------------
--
-- In all simplicity, the idea is following:
--
-- EffectList -> EffectAdded    --> watchslots[name] --> WatchSlot:Add(effect)
--            -> EffectRemoved                       --> WatchSlot:Remove(effect)
--
-- Callbacks installed to player's effect list check, if effect is listed
-- in lookup table. If so, they call the WatchSlot attached to that name.
-- WatchSlot is window element, and it is separately layed out to a watch
-- window.
--
-- TODO:
--
-- - If we want to track duration, we need to put effects to a list, so that
--   if arbitrary effect is removed, duration can be recalculated.
--
-- - Slots tracking only count can have just count
--
-- ----------------------------------------------------------------------------

watchslots = { }

-- ****************************************************************************
-- ****************************************************************************
--
-- Watched effect display: To get label for showing remaining time at top
-- of icon, we can't use EffectDisplay nor stretched icons. Sadly. Because
-- of that, the whole window is stretched.
--
-- ****************************************************************************
-- ****************************************************************************

WatchSlot = class(Turbine.UI.Control)

function WatchSlot:Constructor()
    Turbine.UI.Control.Constructor(self)

    self.effect = nil

    self.slot = Turbine.UI.Control()
    self.slot:SetBackColorBlendMode(1)

    self.label = Turbine.UI.Label()
    self.label:SetMouseVisible(false)
    self.label:SetTextAlignment( Turbine.UI.ContentAlignment.MiddleCenter );
    self.label:SetFont(Turbine.UI.Lotro.Font.Verdana20);
    self.label:SetFontStyle( Turbine.UI.FontStyle.Outline );
    
    self.slot:SetParent(self)
    self.label:SetParent(self)
end

function WatchSlot:SetSize(w, h)
    Turbine.UI.Control.SetSize(self, w, h)
    self.label:SetSize(w, h)
    self.slot:SetSize(w, h)
end

function WatchSlot:SetText(text)
    self.label:SetText(text)
end

function WatchSlot:SetEffect(effect)
    self.effect = effect
    if effect ~= nil then
        self.slot:SetBackground(self.effect:GetIcon())
    end
    self:SetVisible(effect ~= nil)
end

function WatchSlot:GetEffect()
    return self.effect
end

function WatchSlot:Update(sender, args)
    local remaining = self.effect:GetStartTime() + self.effect:GetDuration() - Turbine.Engine.GetGameTime()
    if remaining < 10 then
        self.label:SetText(string.format("%u", remaining + 1))
    end
end

function WatchSlot:SetVisible(visible)
    Turbine.UI.Control.SetVisible(self, visible)

    if visible and self.effect:GetDuration() < 60 then
        self:SetWantsUpdates(true)
        self.label:SetText("...")
    else
        self:SetWantsUpdates(false)
        self.label:SetText("X")
    end
end

