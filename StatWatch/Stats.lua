-- ****************************************************************************
-- ****************************************************************************
--
-- Character stats
--
-- ****************************************************************************
-- ****************************************************************************

import "MaKoPlugins.Utils"
import "MaKoPlugins.StatWatch.Conversion";

-- ****************************************************************************
-- ****************************************************************************
--
-- Armor classes (to calculate mitigation percentages)
--
-- ****************************************************************************
-- ****************************************************************************

ArmorType = {
	[Turbine.Gameplay.Class.Beorning]   = "MediumArmor",
	[Turbine.Gameplay.Class.Burglar]    = "MediumArmor",
	[Turbine.Gameplay.Class.Captain]    = "HeavyArmor",
	[Turbine.Gameplay.Class.Champion]   = "HeavyArmor",
	[Turbine.Gameplay.Class.Guardian]   = "HeavyArmor",
	[Turbine.Gameplay.Class.Hunter]     = "MediumArmor",
	[Turbine.Gameplay.Class.LoreMaster] = "LightArmor",
	[Turbine.Gameplay.Class.Minstrel]   = "LightArmor",
	[Turbine.Gameplay.Class.RuneKeeper] = "LightArmor",
	[Turbine.Gameplay.Class.Warden]     = "MediumArmor",
}

-- ****************************************************************************
-- ****************************************************************************
--
-- Ratings store just raw ratings. This can be used to store values for
-- later comparisons. Also, this can be used to store modifiers, and then
-- later add them to ratings.
--
-- Even thought certain stats are derived from same ratings, we store the
-- them as separate entries. This is because e.g. cap ratings are different.
--
-- ****************************************************************************
-- ****************************************************************************

Ratings = class()

function Ratings:Constructor(player)
    if player ~= nil then self:Refresh(player) end
end

function Ratings:Refresh(player)
    self["Morale"]     = player:GetMaxMorale()
    self["Power"]      = player:GetMaxPower()
    self["ICMR"]       = player.attr:GetInCombatMoraleRegeneration()
    self["ICPR"]       = player.attr:GetInCombatPowerRegeneration()

    self["Armor"]      = player.attr:GetArmor()
    self["Might"]      = player.attr:GetMight()
    self["Agility"]    = player.attr:GetAgility()
    self["Vitality"]   = player.attr:GetVitality()
    self["Will"]       = player.attr:GetWill()
    self["Fate"]       = player.attr:GetFate()

    self["CritRate"]   = player.attr:GetBaseCriticalHitChance()
    self["CritMag"]    = self.CritRate
    self["DevRate"]    = self.CritRate
    
    self["Finesse"]    = player.attr:GetFinesse()
    self["PhysMast"]   = math.max(player.attr:GetMeleeDamage(), player.attr:GetRangeDamage())
    self["TactMast"]   = player.attr:GetTacticalDamage()
    self["OutHeals"]   = player.attr:GetOutgoingHealing()

    self["Resistance"] = player.attr:GetBaseResistance()
    self["CritDef"]    = player.attr:GetBaseCriticalHitAvoidance()
    self["IncHeals"]   = player.attr:GetIncomingHealing()

    self["Block"]      = player.attr:CanBlock() and player.attr:GetBlock() or nil
    self["Parry"]      = player.attr:CanParry() and player.attr:GetParry() or nil
    self["Evade"]      = player.attr:CanEvade() and player.attr:GetEvade() or nil

    self["PartialBlock"] = self.Block
    self["PartialParry"] = self.Parry
    self["PartialEvade"] = self.Evade    

    self["PartialBlockMit"] = self.Block
    self["PartialParryMit"] = self.Parry
    self["PartialEvadeMit"] = self.Evade    

    self["CommonMit"]  = player.attr:GetCommonMitigation()
    self["PhysMit"]    = player.attr:GetPhysicalMitigation()
    self["TactMit"]    = player.attr:GetTacticalMitigation()

    self["ID"] = {
        Name      = player:GetName(),
        Class     = player:GetClass(),
        ArmorType = ArmorType[player:GetClass()],
        Level     = player:GetLevel(),
    }
end

-- ----------------------------------------------------------------------------
-- Make a (shallow) copy from ratings: especially, ID block will be copied
-- as reference.
-- ----------------------------------------------------------------------------

function Ratings:copy()
    local r = { }
    for key, value in pairs(self) do
        r[key] = value
    end
    return r
end

-- ----------------------------------------------------------------------------
-- Adding ratings together. This does not add new fields to original ratings
-- ----------------------------------------------------------------------------

function Ratings:add(ratings)
    for key, value in pairs(self) do
        if ratings[key] ~= nil then
            if type(ratings[key]) == "number" then self[key] = value + ratings[key] end
        end
    end
end

-- ----------------------------------------------------------------------------
-- Combine ratings by adding. This may add new fields to original.
-- ----------------------------------------------------------------------------

function Ratings:combine(ratings)
    for key, value in pairs(ratings) do
        if self[key] ~= nil then
            if type(self[key]) == "number" then self[key] = value + ratings[key] end
        else
            self[key] = ratings[key]
        end
    end
end

-- ----------------------------------------------------------------------------
-- Subtract ratings without adding new fields
-- ----------------------------------------------------------------------------

function Ratings:sub(ratings)
    for key, value in pairs(self) do
        if ratings[key] ~= nil then
            if type(self[key]) == "number" then self[key] = value - ratings[key] end
        end
    end
end

-- ----------------------------------------------------------------------------
-- Create ratings difference: remove fields that are not common to both.
-- ----------------------------------------------------------------------------

function Ratings:diff(ratings)
    for key, value in pairs(self) do
        if ratings[key] ~= nil then
            if type(self[key]) == "number" then self[key] = value - ratings[key] end
        else
            self[key] = nil
        end
    end
end

-- ****************************************************************************
-- ****************************************************************************
--
-- Generated modifiers
--
-- ****************************************************************************
-- ****************************************************************************

function CapRatings(L, armortype)
    return {
        CritRate   = ratingCap("CritRate", L),
        DevRate    = ratingCap("DevRate", L),
        PhysMast   = ratingCap("Mastery", L),
        TactMast   = ratingCap("Mastery", L),
    	OutHeals   = ratingCap("OutHeal", L),

    	Resistance = ratingCap("Resistance", L),
        IncHeals   = ratingCap("IncHeal", L),
        
        Block      = ratingCap("BPE", L),
        Parry      = ratingCap("BPE", L),
        Evade      = ratingCap("BPE", L),
        
        PartialBlock = ratingCap("PartialBPE", L),
        PartialParry = ratingCap("PartialBPE", L),
        PartialEvade = ratingCap("PartialBPE", L),

        CommonMit = ratingCap(armortype, L),
        PhysMit   = ratingCap(armortype, L),
        TactMit   = ratingCap(armortype, L),

        ID = {
            ArmorType = armortype,
            Level     = L,
        },
    }
end

function T2Modifiers(L)
    return {
        Resistance = -90 * L,
        
        Block = -40 * L,
        Parry = -40 * L,
        Evade = -40 * L,

        PartialBlock = -40 * L,
        PartialParry = -40 * L,
        PartilaEvade = -40 * L,

        PartialBlockMit = -40 * L,
        PartialParryMit = -40 * L,
        PartilaEvadeMit = -40 * L,

        CommonMit = -5 * math.floor(L * 13.5),
        PhysMit   = -5 * math.floor(L * 13.5),
        TactMit   = -5 * math.floor(L * 13.5),

        ID = {
            Level = L,
        },
    }
end

-- ****************************************************************************
-- ****************************************************************************
--
-- Stats: This combines ratings, modifiers, conversions and such
--
-- ****************************************************************************
-- ****************************************************************************

Stats = class()

function Stats:Constructor(player)
    self.player  = player
    self.ratings = Ratings(player)
    self.modifier = {
        visible = { },
        hidden  = { },
    }

    self.reference = { }

    -- ------------------------------------------------------------------------

    self.pkeys = {
        PhysMast = "Mastery",
        TactMast = "Mastery",
    
        Block = "BPE",
        Parry = "BPE",
        Evade = "BPE",

        PartialBlock = "PartialBPE",
        PartialParry = "PartialBPE",
        PartialEvade = "PartialBPE",

        PartialBlockMit = "PartialBPEMit",
        PartialParryMit = "PartialBPEMit",
        PartialEvadeMit = "PartialBPEMit",

        CommonMit = self.ratings.ID.ArmorType,
        PhysMit   = self.ratings.ID.ArmorType,
        TactMit   = self.ratings.ID.ArmorType,
    }
end

-- ----------------------------------------------------------------------------

function Stats:GetRating(tbl, key, L)
    local R = tbl[key]
    if R ~= nil and self.modifier.visible[key] then
        R = R + self.modifier.visible[key]
    end
    return R
end

function Stats:GetPercent(tbl, key, L)
    local R = self:GetRating(tbl, key, L)
    if R ~= nil and self.modifier.hidden[key] then
        R = R + self.modifier.hidden[key]
        R = math.max(R, 0.0)
    end
    local pkey = self.pkeys[key]
    return ratingToPercentage(pkey and pkey or key, R, L)
end

function Stats:Rating(key, L)     return self:GetRating(self.ratings,    key, L) end
function Stats:Percent(key, L)    return self:GetPercent(self.ratings,   key, L) end
function Stats:RefRating(key, L)  return self:GetRating(self.reference,  key, L) end
function Stats:RefPercent(key, L) return self:GetPercent(self.reference, key, L) end

-- ----------------------------------------------------------------------------

function Stats:GetLevel()
    if self.reference and self.reference.ID then
        return self.reference.ID.Level
    else
        return self.ratings.ID.Level
    end
end

function Stats:Refresh(player)
    self.ratings:Refresh(player)
end

-- ----------------------------------------------------------------------------

--[[
-- ----------------------------------------------------------------------------
-- Computed stats
-- ----------------------------------------------------------------------------

Stat("Avoidances", function()
	return
		stats["Block"]:Percentage() + 
		stats["Parry"]:Percentage() +
		stats["Evade"]:Percentage();
	end,
	nil,
	FormatPercentage
)

Stat("Partials", function()
	return
		stats["PartialBlock"]:Rating() + 
		stats["PartialParry"]:Rating() +
		stats["PartialEvade"]:Rating();
	end,
	nil,
	FormatPercentage
)

Stat("AvoidChance", function()
	return
	    100.0 - 100.0 * 
	    (1.0 - stats["Avoidances"]:Rating()/100.0) *
	    (1.0 - stats["Partials"]:Rating() / 100.0)
	end,
	nil,
	FormatPercentage
)
--]]

--[[
Stat("SelfHeal", function()
	return 100 *
		(1.0 + stats["HealIn"]:Percentage()/100.0) *
		(1.0 + stats["HealOut"]:Percentage()/100.0) - 100
	end,
	nil,
	FormatPercentageInc
)

Stat("EffectiveMoralePhys", function()
    return stats["Morale"] *
		(1 - stats["CommonMit"]:Percentage()/100.0)
    end,
    nil
)

Stat("CommonELM", function()
	return 1.0 / ( 
		-- (1 - stats["Avoidances"]:Value()/100.0) *
		(1 - stats["CommonMit"]:Percentage()/100.0)
	)
	end,
	nil,
	FormatELM
)

Stat("TactELM", function()
	return 1.0 / ( 
		-- (1 - stats["Avoidances"]:Value()/100.0) *
		(1 - stats["TactMit"]:Percentage()/100.0)
	)
	end,
	nil,
	FormatELM
)
]]--


