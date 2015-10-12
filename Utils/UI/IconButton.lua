-- ****************************************************************************
-- ****************************************************************************
--
-- IconButton is a button that takes four icons (disabled, no focus, focus,
-- pressed). TODO: Unfinished implementation.
--
-- ****************************************************************************
-- ****************************************************************************

IconButton = class(Turbine.UI.Control)

function IconButton:Constructor(iconset)
    Turbine.UI.Control.Constructor(self)

    self.iconset = iconset
    self:SetBackground(iconset.NoFocus)

    -- ------------------------------------------------------------------------

    self.MouseEnter = function(sender, args)
        if not self:IsEnabled() then return end
        self:SetBackground(self.iconset.Focus)
    end

    self.MouseLeave = function(sender, args)
        if not self:IsEnabled() then return end
        self:SetBackground(self.iconset.NoFocus)
    end

    -- ------------------------------------------------------------------------

    self.MouseDown = function(sender, args)
        if not self:IsEnabled() then return end
        self:SetBackground(self.iconset.Pressed)
    end

    self.MouseUp = function(sender, args)
        if not self:IsEnabled() then return end
        self:SetBackground(self.iconset.Focus)
    end
end

function IconButton:SetEnabled(state)
    Turbine.UI.Control.SetEnabled(self, state)
    if state then
        self:SetBackground(self.iconset.NoFocus)
    else
        self:SetBackground(self.iconset.Disabled)
    end
end

