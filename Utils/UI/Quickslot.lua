-- ****************************************************************************
-- ****************************************************************************
--
-- Attempt to make quickslot with working Drag'n'Drop... Quickslot is a
-- component that holds Shortcut object.
--
-- ****************************************************************************
-- ****************************************************************************

Quickslot = class(Turbine.UI.Lotro.Quickslot)

Quickslot.DragSource    = nil   -- Where shortcut were taken?
Quickslot.DragShortcut  = nil   -- What shortcut?
Quickslot.SwapShortcut  = nil   -- What it is going to replace?

-- ----------------------------------------------------------------------------
--
-- (1) Track mouse button press on quickslot, so that we can empty the slot
-- when dragging starts. As we need to know that this specific quickslot is the
-- subject to be dragged, DragEnter/DragLeave don't work - they are fired every
-- time something is dragged over quickslot, no matter of the source.
--
-- NOTE: Dragging item too quickly out of the box will cancel dragging from
-- engine side, and leads loss of shortcut.
--
-- ----------------------------------------------------------------------------

function Quickslot:MouseDown(args)
    -- println("%s: MouseDown", tostring(self))
    if args.Button == Turbine.UI.MouseButton.Left then
        self.ispressed = true
    end
end

function Quickslot:MouseUp(args)
    -- println("%s: MouseUp", tostring(self))
    self.ispressed = false
end

function Quickslot:MouseLeave(args)
    -- println("%s: MouseLeave", tostring(self))
    if self.ispressed then
        Quickslot.DragSource = self
        Quickslot.DragShortcut = self:GetShortcut()
        self:SetShortcut(Turbine.UI.Lotro.Shortcut())
        self.ispressed = false
    end
end

-- ----------------------------------------------------------------------------
-- (2) When dragging things around, track potential swap shortcut: When drop
-- event is fired, quickslot's shortcut is already changed.
-- ----------------------------------------------------------------------------

function Quickslot:DragEnter(args)
    Quickslot.SwapShortcut = self:GetShortcut()
end

function Quickslot:DragLeave(args)
    Quickslot.SwapShortcut = nil
end

-- ----------------------------------------------------------------------------
-- (3) The quickslot receives drop event. Shortcut is already changed. We
-- check if the dropped shortcut has source somewhere, and if so, we place
-- previous shortcut there.
--
-- NOTE: Dragged aliases will always drop as nil. So, in any case, we
-- place the stored shortcut to this quickslot.
--
-- ----------------------------------------------------------------------------

function Quickslot:DragDrop(args)

    -- ------------------------------------------------------------------------
    -- Drop info is nil, which mostly means attempt to drop an alias. If
    -- we have previously stored shortcut, use that instead. If not, alias is
    -- probably coming from outside source, and as we can't know what it
    -- has been, we use empty shortcut.
    -- ------------------------------------------------------------------------
    
    local dropped = args.DragDropInfo:GetShortcut()
    if dropped == nil then
        if Quickslot.DragShortcut then
            self:SetShortcut(Quickslot.DragShortcut)
        else
            self:SetShortcut(Turbine.UI.Lotro.Shortcut())
        end
    end

    -- ------------------------------------------------------------------------

    if Quickslot.DragSource ~= nil and Quickslot.DragSource ~= self then
        if Quickslot.SwapShortcut then
            Quickslot.DragSource:SetShortcut(Quickslot.SwapShortcut)
        end
    end

    -- ------------------------------------------------------------------------

    Quickslot.DragSource = nil
    Quickslot.DragShortcut = nil
    Quickslot.SwapShortcut = nil
end

-- ****************************************************************************
-- ****************************************************************************
--
-- Inject some additional functionality to Quickslot class
--
-- ****************************************************************************
-- ****************************************************************************

-- ----------------------------------------------------------------------------
-- Quickslot sequence / grid: When growing, grid automatically creates
-- more quickslots with factory function. When shrinking, quickslots outside
-- the content area are hidden, but they still exist.
-- ----------------------------------------------------------------------------

Quickslot.Grid = class(Turbine.UI.Control)

function Quickslot.Grid:Constructor()
    Turbine.UI.Control.Constructor(self)

    self.factory = function()
        return Quickslot()
    end

    -- self:SetBackColor(Turbine.UI.Color.Blue)
end

function Quickslot.Grid:SetFactory(factory)
    self.factory = factory
end

function Quickslot.Grid:GetCount()
    return self:GetControls():GetCount()
end

function Quickslot.Grid:Get(index)
    local childs = self:GetControls()
    if index > childs:GetCount() then
        local child = self:factory()
        child:SetParent(self)
    end
    return childs:Get(index)
end

function Quickslot.Grid:SetSize(w, h)
    Turbine.UI.Control.SetSize(self, w, h)

    local padding = 0
    local x, y = 0, 0
    local childw, childh = self:Get(1):GetSize()
    local index = 1

    while y + childh < h do

        local child = self:Get(index)
        child:SetPosition(x, y)
        child:SetVisible(true)

        x = x + padding + childw

        if(x + childw > w) then
            x = 0
            y = y + padding + childh
        end
        index = index + 1
    end

    for i = index, self:GetCount() do
        self:Get(i):SetVisible(false)
    end
end

