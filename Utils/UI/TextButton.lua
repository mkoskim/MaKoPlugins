-- ****************************************************************************
-- ****************************************************************************
--
-- TextButton is simple button, used as Quickslot skin and in desktop buttons.
--
-- ****************************************************************************
-- ****************************************************************************

TextButton = class(Turbine.UI.Button)

function TextButton:Constructor()
    Turbine.UI.Button.Constructor(self)

    self:SetBackColor(Turbine.UI.Color(1,0.1,0.1,0.1))
end

function TextButton:MouseEnter()
    self:SetBackColor(Turbine.UI.Color(1,0.3,0.3,0.3))
end

function TextButton:MouseDown()
    self:SetBackColor(Turbine.UI.Color(1,0.1,0.1,0.1))
end

function TextButton:MouseUp()
    self:SetBackColor(Turbine.UI.Color(1,0.3,0.3,0.3))
end

function TextButton:MouseLeave()
    self:SetBackColor(Turbine.UI.Color(1,0.1,0.1,0.1))
end

function TextButton:SetEnabled(state)
   	self:SetForeColor(
   	    state and Turbine.UI.Color(1, 1, 1) or
   	    Turbine.UI.Color(0.5, 0.5, 0.5)
   	)
end

