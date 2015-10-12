-- ****************************************************************************
-- ****************************************************************************
--
-- Layouts
--
-- ****************************************************************************
-- ****************************************************************************

Layout = class(Turbine.UI.Control)

function Layout:Constructor(orientation, ...)
    Turbine.UI.Control.Constructor(self)

    self.orientation = orientation

    local sum = function(a, b) return a + b end
    local max = function(a, b) return (a > b) and a or b end

    self.opWidth =
        orientation == Turbine.UI.Orientation.Horizontal and sum or
        max;

    self.opHeight =
        orientation == Turbine.UI.Orientation.Horizontal and max or
        sum;

    for _, control in ipairs(arg) do
        -- println("Type: %s (%s)", type(control), tostring(control))
        if type(control) == "table" then
            self:Add(control)
        elseif type(control) == "function" then
            self:Add(control())
        else
        end
    end
end

-- ----------------------------------------------------------------------------

Layout.Vertical = function(...)
    return Layout(Turbine.UI.Orientation.Vertical, unpack(arg))
end

Layout.Horizontal = function(...)
    return Layout(Turbine.UI.Orientation.Horizontal, unpack(arg))
end

-- ----------------------------------------------------------------------------

function Layout:Add(control)
    control:SetParent(self)
end

-- ----------------------------------------------------------------------------

function Layout:GetWidth()
    local result = 0
    local childlist = self:GetControls()
    
    for i = 1, childlist:GetCount() do
        result = self.opWidth(result, childlist:Get(i):GetWidth())
    end
    return result
end

function Layout:GetHeight()
    local result = 0
    local childlist = self:GetControls()
    
    for i = 1, childlist:GetCount() do
        result = self.opHeight(result, childlist:Get(i):GetHeight())
    end
    return result
end

function Layout:GetSize() return self:GetWidth(), self:GetHeight() end

-- ----------------------------------------------------------------------------

function Layout:SetSize(w, h)
    local x, y = 0, 0

    local childlist = self:GetControls()

    for i = 1, childlist:GetCount() do
        local child = childlist:Get(i)

        child:SetPosition(x, y)
        child:SetSize(child:GetSize())
        
        if self.orientation == Turbine.UI.Orientation.Horizontal then
            x = x + child:GetWidth()
        else
            y = y + child:GetHeight()
        end
    end

    Turbine.UI.Control.SetSize(self, w, h)
end

