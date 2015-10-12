-- ----------------------------------------------------------------------------
-- Experimental: EquipmentSlot
-- ----------------------------------------------------------------------------

EquipmentSlot = class(Turbine.UI.Control)

function EquipmentSlot:Constructor(slot)
	Turbine.UI.Control.Constructor( self );

    self.slot = slot
    self.shortcut = nil

    self:SetSize(44, 44)
    self:SetBackground(Icons.EquipmentSlot[slot])
    self:SetMouseVisible(false)

	self.qs = Quickslot();
	self.qs:SetParent( self );
	self.qs:SetPosition(3, 3);

	self.qs.DragDrop=function()
	    local player = Turbine.Gameplay.LocalPlayer:GetInstance();
	    local equipped = player:GetEquipment():GetItem(self.slot);
        local dropped = self.qs:GetShortcut():GetItem()

	    println("Equipped: %s, dropped: %s",
	        tostring(equipped),
	        tostring(dropped)
	    )
	    if dropped then
	        println("Dropped....: %s", dropped:GetName())
	        println("-Category..: %s", tostring(dropped:GetCategory()))
	    end
	    -- self:SetShortcut(self.shortcut)
	end

end

function EquipmentSlot:SetShortcut( shortcut )
    self.qs:SetShortcut(shortcut)
end

