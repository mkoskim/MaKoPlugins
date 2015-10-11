-- ****************************************************************************
-- ****************************************************************************
--
-- Undecorated window, with HUD repositioning feature.
--
-- ****************************************************************************
-- ****************************************************************************

import "Deusdictum.UI.Dragbar"

DraggableWindow = class(Turbine.UI.Window)

function DraggableWindow:Constructor()
    Turbine.UI.Window.Constructor(self)
    self.dragbar = Deusdictum.UI.DragBar(self)
end

function DraggableWindow:SetText(text)
    Turbine.UI.Window.SetText(self, text)
    self.dragbar.Label:SetText(text)
end

function DraggableWindow:SetSize(w, h)
    Turbine.UI.Window.SetSize(self, w, h)
    self.dragbar:RecalculateSize()
end

function DraggableWindow:SetPosition(x, y)
    Turbine.UI.Window.SetPosition(self, x, y)
    self.dragbar:RecalculatePosition()
end

function DraggableWindow:SetResizable(state)
    -- TODO: Something sensible?
end

