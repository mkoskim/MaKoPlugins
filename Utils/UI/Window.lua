-- ****************************************************************************
-- ****************************************************************************
--
-- Window, that (1) handles ESC and F12, and (2) can be switched to
-- borderless, draggable window.
--
-- ****************************************************************************
-- ****************************************************************************

Window = class(Turbine.UI.Lotro.Window)

function Window:Constructor()
    Turbine.UI.Lotro.Window.Constructor(self)

    self:SetWantsKeyEvents(true)

    self.storedVisibility = nil

    self.KeyDown = function(sender, args)
        if args.Action == Actions.ESC then
            self:SetVisible(false)
        elseif args.Action == Actions.HUDToggle then
            if self.storedVisibility == nil then
                self.storedVisibility = self:IsVisible()
                self:SetVisible(false)
                println("Hide: %s", tostring(self.storedVisibility))
            else
                println("Show: %s", tostring(self.storedVisibility))
                self:SetVisible(self.storedVisibility)
                self.storedVisibility = nil
            end
        end
    end
end

