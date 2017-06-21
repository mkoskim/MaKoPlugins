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

    self["CommonMit"]  = player.attr:GetCommonMitigation()
    self["PhysMit"]    = player.attr:GetPhysicalMitigation()
    self["TactMit"]    = player.attr:GetTacticalMitigation()
end

-- ----------------------------------------------------------------------------
-- Adding ratings together. This does not add fields to original ratings
-- ----------------------------------------------------------------------------

function Ratings:add(ratings)
    for key, value in pairs(self) do
        if ratings[key] ~= nil then self[key] = value + ratings[key] end
    end
end

-- ----------------------------------------------------------------------------
-- Combine ratings by adding. This may add new fields to original.
-- ----------------------------------------------------------------------------

function Ratings:combine(ratings)
    for key, value in pairs(ratings) do
        if self[key] ~= nil then
            self[key] = value + ratings[key]
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
        if ratings[key] ~= nil then self[key] = value - ratings[key] end
    end
end

-- ----------------------------------------------------------------------------
-- Create ratings difference: remove fields that are not common to both.
-- ----------------------------------------------------------------------------

function Ratings:diff(ratings)
    for key, value in pairs(self) do
        if ratings[key] ~= nil then
            self[key] = value - ratings[key]
        else
            self[key] = nil
        end
    end
end

-- ****************************************************************************
-- ****************************************************************************

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
        Mastery    = ratingCap("Mastery", L),
    	OutHeal    = ratingCap("OutHeal", L),
    	Resistance = ratingCap("Resistance", L),
        IncHeal    = ratingCap("IncHeal", L),
        
        Block      = ratingCap("BPE", L),
        Parry      = ratingCap("BPE", L),
        Evade      = ratingCap("BPE", L),
        
        PartialBlock = ratingCap("PartialBPE", L),
        PartialParry = ratingCap("PartialBPE", L),
        PartialEvade = ratingCap("PartialBPE", L),

        CommonMit = ratingCap(armortype, L),
        PhysMit   = ratingCap(armortype, L),
        TactMit   = ratingCap(armortype, L),
    }
end

function T2Modifiers(L)
    return {
        CommonMit = -5 * math.floor(L * 13.5),
        PhysMit   = -5 * math.floor(L * 13.5),
        TactMit   = -5 * math.floor(L * 13.5),

        Resistance = -90 * L,
        
        Block      = -40 * L,
        Parry      = -40 * L,
        Evade      = -40 * L,
    }
end

-- ****************************************************************************
-- ****************************************************************************

local function FormatNumber(number, decimals)
    if number < 1000 then
        return string.format("%." .. tostring(decimals or 0) .. "f", number)
    elseif number < 150000 then
        return string.format("%d,%03d", (number+0.5)/1000, (number+0.5)%1000)
    elseif number < 1000000 then
        return string.format("%.1fk", (number+0.5)/1000)
    elseif number < 1500000 then
        return string.format("%d,%03.1fk", (number+0.5)/1000000, ((number+0.5)%1000000)/1000)
    else
        return string.format("%.2fM", number/1e6)
    end
end

local function FormatPercent(value) return string.format("%.1f %%", value) end
local function FormatPercentDiff(value) return string.format("%+.1f %%", value) end
local function FormatELM(value) return string.format("x %3.1f", value) end

-- ****************************************************************************
-- ****************************************************************************
--
-- Stats: This combines ratings, modifiers, conversions and such
--
-- ****************************************************************************
-- ****************************************************************************

-- ----------------------------------------------------------------------------
-- StatEntry holds information of how to fetch ratings, and how to convert
-- them to percentages.
-- ----------------------------------------------------------------------------

local StatEntry = class()

function StatEntry:Constructor(stats, key, rkey, pkey, rfmt)
    self.stats = stats
    self.stats[key] = self
    self.key  = key
    self.rkey = rkey and rkey or key
    self.pkey = pkey
    self.rfmt = rfmt and rfmt or function(self, R) return FormatNumber(R, 0) end
end

function StatEntry:GetRating(tbl, key, L)
    local R
    if type(key) == "function" then
        R = key(tbl, L)
    else
        R = tbl[key]
    end
    if R ~= nil and self.stats.modifier.visible[key] then R = R + self.stats.modifier.visible[key] end
    return R
end

function StatEntry:GetPercent(tbl, key, L)
    local R = self:GetRating(tbl, key, L)
    if R ~= nil and self.stats.modifier.hidden[key] then
        R = R + self.stats.modifier.hidden[key]
        R = math.max(R, 0.0)
    end
    return ratingToPercentage(self.pkey, R, L)
end

function StatEntry:Rating(L)     return self:GetRating(self.stats.ratings, self.rkey, L) end
function StatEntry:Percent(L)    return self:GetPercent(self.stats.ratings, self.rkey, L) end
function StatEntry:RefRating(L)  return self:GetRating(self.stats.reference, self.key, L) end
function StatEntry:RefPercent(L) return self:GetPercent(self.stats.reference, self.key, L) end

function StatEntry:RatingAsString(L, R)
    if R ~= nil then
        return self:rfmt(R)
    else
        return "N/A"
    end
end

function StatEntry:PercentAsString(L, p)
    if p ~= nil then
        return FormatPercent(p)
    else
        return nil
    end
end

function StatEntry:AsString(L, aspercent)
    if aspercent and self.pkey ~= nil then
        p = self:Percent(L)
        if p ~= nil then return self:PercentAsString(L, p) end
    end
    return self:RatingAsString(L, self:Rating(L))
end

-- ----------------------------------------------------------------------------

function StatEntry:RefAsString(L, aspercent)
    if self:Rating(L) and self:RefRating(L) then
        if aspercent and self.pkey ~= nil then
            return self:PercentAsString(L, self:RefPercent(L))
        else
            return self:RatingAsString(L, self:RefRating(L))
        end
    else
        return nil
    end
end

function StatEntry:DiffAsString(L, aspercent)
    local a, b
    if aspercent and self.pkey ~= nil then
        a = self:Percent(L)
        b = self:RefPercent(L)
    else
        a = self:Rating(L)
        b = self:RefRating(L)
        aspercent = false
    end
    if a ~= nil and b ~= nil and (math.abs(a - b) > 0.05) then
        return aspercent and self:PercentAsString(L, a - b) or self:RatingAsString(L, a - b)
    else
        return nil
    end
end

-- ----------------------------------------------------------------------------

Stats = class()

function Stats:Constructor(player)
    self.ratings = Ratings(player)
    self.modifier = {
        visible = { },
        hidden  = { },
    }

    self.reference = { }
    self.ckey = { }

    -- ------------------------------------------------------------------------

    StatEntry(self, "Morale")
    StatEntry(self, "Power")
    StatEntry(self, "ICMR", nil, nil, function(self, R) return FormatNumber(R, 1) end)
    StatEntry(self, "ICPR", nil, nil, function(self, R) return FormatNumber(R, 1) end)

    StatEntry(self, "Armor")
    StatEntry(self, "Might")
    StatEntry(self, "Agility")
    StatEntry(self, "Vitality")
    StatEntry(self, "Will")
    StatEntry(self, "Fate")
    
    StatEntry(self, "CritRate", nil, "CritRate")
    StatEntry(self, "CritMag",  "CritRate", "CritMag")
    StatEntry(self, "DevRate",  "CritRate", "DevRate")

    StatEntry(self, "Finesse",  nil, "Finesse")
    StatEntry(self, "PhysMast", nil, "Mastery")
    StatEntry(self, "TactMast", nil, "Mastery")
    StatEntry(self, "OutHeals", nil, "OutHeals")

    StatEntry(self, "Resistance", nil, "Resistance")
    StatEntry(self, "CritDef", nil, "CritDef")
    StatEntry(self, "IncHeals", nil, "IncHeals")

    StatEntry(self, "Block", nil, "BPE")
    StatEntry(self, "Parry", nil, "BPE")
    StatEntry(self, "Evade", nil, "BPE")

    StatEntry(self, "PartialBlock", "Block", "PartialBPE")
    StatEntry(self, "PartialParry", "Parry", "PartialBPE")
    StatEntry(self, "PartialEvade", "Evade", "PartialBPE")

    StatEntry(self, "PartialBlockMit", "Block", "PartialBPEMit")
    StatEntry(self, "PartialParryMit", "Parry", "PartialBPEMit")
    StatEntry(self, "PartialEvadeMit", "Evade", "PartialBPEMit")

    local armortype = ArmorType[player:GetClass()]

    StatEntry(self, "CommonMit", nil, armortype)
    StatEntry(self, "PhysMit", nil, armortype)
    StatEntry(self, "TactMit", nil, armortype)

    -- ------------------------------------------------------------------------

    -- self["BPEChance"] = StatEntry(self, self.FullBPERate, nil, function(self, R) return FormatPercent(R) end)
end

function Stats:FullBPERate(L)
    return
        self["Block"]:Percent(L) +
        self["Parry"]:Percent(L) +
        self["Evade"]:Percent(L)
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


