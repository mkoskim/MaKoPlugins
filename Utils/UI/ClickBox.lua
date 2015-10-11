-- ****************************************************************************
-- ****************************************************************************
--
-- ClickBox is a button-like control. Providing four images (disabled,
-- no focus, focus and pressed) it acts like a button.
--
-- ****************************************************************************
-- ****************************************************************************

ClickBox = class(Turbine.UI.Control)

function ClickBox:Constructor(iconset)
    Turbine.UI.Control.Constructor(self)

    self.iconset = iconset
    self:SetBackground(iconset.NoFocus)

    self.MouseEnter = function(sender, args)
        if not self:IsEnabled() then return end
        self:SetBackground(self.iconset.Focus)
    end

    self.MouseLeave = function(sender, args)
        if not self:IsEnabled() then return end
        self:SetBackground(self.iconset.NoFocus)
    end

    self.MouseDown = function(sender, args)
        if not self:IsEnabled() then return end
        self:SetBackground(self.iconset.Pressed)
    end    

    self.MouseUp = function(sender, args)
        if not self:IsEnabled() then return end
        self:SetBackground(self.iconset.Focus)
    end
end

function ClickBox:SetEnabled(state)
    Turbine.UI.Control.SetEnabled(self, state)
    if state then
        self:SetBackground(self.iconset.NoFocus)
    else
        self:SetBackground(self.iconset.Disabled)
    end
end

