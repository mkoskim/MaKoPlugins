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

-- ----------------------------------------------------------------------------

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

-- ----------------------------------------------------------------------------

function Window:VisibleChanged(args)
    self._visible = self:IsVisible()
end

-- ----------------------------------------------------------------------------

function Window:Serialize()
    return {
        Left = self:GetLeft(),
        Top = self:GetTop(),
        Width = self:GetWidth(),
        Height = self:GetHeight(),
        Visible = self._visible,
    }
end

function Window:Deserialize(settings)
    self:SetPosition(settings.Left, settings.Top)
    self:SetSize(settings.Width, settings.Height)
    self:SetVisible(settings.Visible)
end

-- ****************************************************************************
--
-- Undecorated Window with event listener
--
-- ****************************************************************************

Window.Undecorated = class(Turbine.UI.Window)

function Window.Undecorated:Constructor()
    Turbine.UI.Window.Constructor(self)
    self:SetWantsKeyEvents(true)
end

Window.Undecorated.KeyDown = Window.KeyDown
Window.Undecorated.VisibleChanged = Window.VisibleChanged
Window.Undecorated.Serialize = Window.Serialize
Window.Undecorated.Deserialize = Window.Deserialize

-- ****************************************************************************
--
-- Window with Deusdictum dragbar
--
-- ****************************************************************************

local function LoadDragBar()
    import "Deusdictum.UI.Dragbar"
    WindowDragBar = Deusdictum.UI.DragBar
end

if pcall(LoadDragBar) then
    Window.Draggable = class(Turbine.UI.Window)

    function Window.Draggable:Constructor()
        Turbine.UI.Window.Constructor(self)
        self.dragbar = WindowDragBar(self)
    end

    function Window.Draggable:SetText(text)
        Turbine.UI.Window.SetText(self, text)
        if self.dragbar then self.dragbar.Label:SetText(text) end
    end

    function Window.Draggable:SetSize(w, h)
        Turbine.UI.Window.SetSize(self, w, h)
        if self.dragbar then self.dragbar:RecalculateSize() end
    end

    function Window.Draggable:SetPosition(x, y)
        Turbine.UI.Window.SetPosition(self, x, y)
        if self.dragbar then self.dragbar:RecalculatePosition() end
    end

    Window.Draggable.Serialize = Window.Serialize
    Window.Draggable.Deserialize = Window.Deserialize

    function Window.Draggable:SetResizable(state)
        -- TODO: Something sensible?
    end
end


