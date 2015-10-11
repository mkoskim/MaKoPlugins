-- ****************************************************************************
-- ****************************************************************************
--
-- Window, that handles ESC and F12.
--
-- ****************************************************************************
-- ****************************************************************************

-- ----------------------------------------------------------------------------

Window = class(Turbine.UI.Lotro.Window)

function Window:Constructor()
    Turbine.UI.Lotro.Window.Constructor(self)

    self:SetWantsKeyEvents(true)
end

function Window:KeyDown(args)
    if args.Action == Actions.ESC then
        if self:IsVisible() then
            self:SetVisible(false)
        end
    elseif args.Action == Actions.HUDToggle then
        if self.storedVisibility == nil then
            self.storedVisibility = self:IsVisible()
            self:SetVisible(false)
        else
            self:SetVisible(self.storedVisibility)
            self.storedVisibility = nil
        end
    end
end

