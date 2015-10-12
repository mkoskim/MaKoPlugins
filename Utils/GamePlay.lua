-- ****************************************************************************
-- ****************************************************************************
--
-- Gameplay helpers
--
-- ****************************************************************************
-- ****************************************************************************

-- ----------------------------------------------------------------------------
-- Unequiping items: Find an empty spot from backpack to drop an equipped
-- item.
-- ----------------------------------------------------------------------------

function Unequip(slot)
	local player = Turbine.Gameplay.LocalPlayer:GetInstance();
	local equipped = player:GetEquipment():GetItem(slot);

    if equipped ~= nil then
        local backpack=player:GetBackpack();

	    for index=1, backpack:GetSize() do
		    if backpack:GetItem(index) == nil then
		        backpack:PerformItemDrop(equipped, index, false)
		        return
            end
        end
        println("Backpack is full, item not unequipped.")
    end
end

