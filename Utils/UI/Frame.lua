-- ****************************************************************************
-- ****************************************************************************
--
-- Generic control to make frames to listboxes, edit boxes, ...
--
-- ****************************************************************************
-- ****************************************************************************

Frame = class(Turbine.UI.Control)

function Frame:Constructor()
    Turbine.UI.Control.Constructor(self)

	self:SetBackColor(frameColor)
end

