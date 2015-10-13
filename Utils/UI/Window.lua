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

    self:HideOnEsc(true)
    self:SetWantsKeyEvents(true)

    self.VisibleChanged = function(sender, args)
        self._visible = self:IsVisible()
    end
end

-- ----------------------------------------------------------------------------

function Window:HideOnEsc(state)
    self.hideOnEsc = state
end

-- ----------------------------------------------------------------------------

function Window:KeyDown(args)
    if args.Action == Actions.ESC and self.hideOnEsc then
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

    -- By default, undecorated windows like quickslot grids and such, dont
    -- hide on Esc.

    self:HideOnEsc(false)
    self:SetWantsKeyEvents(true)

    self.VisibleChanged = function(sender, args)
        self._visible = self:IsVisible()
    end
end

Window.Undecorated.HideOnEsc = Window.HideOnEsc
Window.Undecorated.KeyDown = Window.KeyDown
Window.Undecorated.Serialize = Window.Serialize
Window.Undecorated.Deserialize = Window.Deserialize

-- ****************************************************************************
--
-- Window with Deusdictum dragbar: I might need to melt the implementation
-- here, so that I can add resizing widget to resizable undecorated windows.
--
-- ****************************************************************************

local function LoadDragBar()
    import "Deusdictum.UI.Dragbar"
    WindowDragBar = Deusdictum.UI.DragBar
end

if pcall(LoadDragBar) then
    Window.Draggable = class(Turbine.UI.Window.Undecorated)

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

    Window.Draggable.Serialize = Window.Undecorated.Serialize
    Window.Draggable.Deserialize = Window.Undecorated.Deserialize

    function Window.Draggable:SetResizable(state)
        -- TODO: Something sensible?
    end
end


