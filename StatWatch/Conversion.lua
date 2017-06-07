-- ****************************************************************************
-- ****************************************************************************
--
-- Converting ratings to percentages
--
-- ****************************************************************************
-- ****************************************************************************

import "MaKoPlugins.Utils";

-- ****************************************************************************
-- ****************************************************************************
--
-- Rating to percentage conversions. Reference:
--
--     https://lotro-wiki.com/index.php/Rating_to_percentage_formula
--
-- ****************************************************************************
-- ****************************************************************************

-- ----------------------------------------------------------------------------
-- Basic conversion function (rating-to-percentage)
-- ----------------------------------------------------------------------------

local function r2p(A, B, RL)
	if B ~= nil then return A / (1 + B/RL) else return 0 end
	end

-- ----------------------------------------------------------------------------
-- Segments
-- ----------------------------------------------------------------------------

local Segment = class()

function Segment:Constructor(dP, A, B, level)
	self.A = A
	self.B = B
	self.dP = dP
	self.dRL = B/(A/dP-1)
    self.level = level
end

local function r2p_segment(R, L, segments)
	local RL = R/L
	local p = 0
	for key, segment in ipairs(segments) do
		if segment.dRL == nil or segment.dRL > RL then
			return p + r2p(segment.A, segment.B, RL)
		else
			p = p + segment.dP
			RL = RL - segment.dRL
		end
	    if segment.level and L < segment.level then break end
	end
	return p
end

-- ----------------------------------------------------------------------------

local Linear = class()

function Linear:Constructor(level, factor, C, cap)
    self.level = level
    self.factor = factor
    self.C = C
    self.cap = cap
end

local function r2p_linear(R, L, linears)
    for _, linear in pairs(linears) do
        if L <= linear.level then
            local p = linear.factor(L) * R/1000.0 + linear.C
            p = math.min(p, linear.cap)
            return p
        end
    end
    return nil
end

-- ----------------------------------------------------------------------------
-- Stat data tables
-- ----------------------------------------------------------------------------

local segments = {
	["CritRate"] = {
		Segment(15.0, 100.0, 1190/3.0, 50),
		Segment( 5.0, 100.0,    794.8, 84),
		Segment( 5.0, 100.0,   1075.2)
	},
	["DevRate"] = { Segment( 10.0, 100.0, 1330.0) },
	["CritMag"] = { Segment(100.0, 100.0,  300.0) },
	["Finesse"] = { Segment(100.0, 100.0, 1190/3.0) },
	["OutHeals"] = {
		Segment(30, 100.0, 1190/3.0, 50),
		Segment(20, 100.0, 2380/3.0),
		Segment(20, 100.0, 1190)
	},
	["Resistance"] = {
		Segment(30, 100.0, 1190/3.0, 50),
		Segment(20, 100.0, 2380/3.0)
	},
	["CritDef"] = { Segment(100.0, 100.0, 100.0) },
	["IncHeals"] = {
		Segment(15, 100.0, 1190/3.0),
		Segment(10, 100.0, 2380/3.0)
	},
	["Avoidances"] = { Segment(13.0, 100.0, 499.95) },
	["Partials"] = {
        Segment(15.0, 100.0, 396.66, 50),
        Segment( 2.0, 100.0, 991.66, 84),
        Segment( 3.0, 100.0, 1050.0, 95),
        Segment(15.0, 100.0, 1200.0)
    },
	["PartialMit"] = {
	    Segment(10.0, 100.0, 0.0),
	    Segment(50.0, 100.0, 396.66)
	},

	["LightArmor"] = {
	    Segment(40,  65.0,  80),
--		Segment(20, 100, 150, 37.5),
--		Segment(20, 100, 350, 87.5)
	},
	["MediumArmor"] = {
	    Segment(50,  85.0, 104.066667),
--		Segment(20, 100, 149.9175, 59967/1600.0),
--		Segment(30,	100, 253.003, 759009/7000.0)
	},
	["HeavyArmor"] = {
	    Segment(60, 110.0, 138.75),
--		Segment(10, 100, 5697/38, 633/38),
--		Segment(50, 100, 5697/38, 5697/38)
	},
}

local linears = {
    ["Mastery"] = {
        Linear( 20, function(L) return 14.6 end,        0,  40.0),
        Linear( 30, function(L) return 24.2-0.48*L end, 0,  40.0),
        Linear( 40, function(L) return 17-0.24*L end,   0,  40.0),
        Linear( 50, function(L) return 13.4-0.15*L end, 0,  40.0),
        Linear( 60, function(L) return 11.4-0.11*L end, 0, 200.0),
        Linear( 70, function(L) return 10.2-0.09*L end, 0, 200.0),
        Linear( 80, function(L) return 7.4-0.05*L end,  0, 200.0),
        Linear( 90, function(L) return 6.6-0.04*L end,  0, 200.0),
        Linear(100, function(L) return 5.7-0.03*L end,  0, 200.0),
        Linear(105, function(L) return 2.7 end,         0, 400.0),
    },
}

local function Set(list)
	local set = {}
	for _, l in ipairs(list) do set[l] = true end;
	return set
end

local hascap = Set{
	"CritRate",
	"DevRate",
	"OutHeals",
	"Resistance",
	"IncHeals",
	"Avoidances",
	"Partials",
	"PartialMit",
	"LightArmor",
	"MediumArmor",
	"HeavyArmor",
	"Mastery",
}

-- ----------------------------------------------------------------------------
-- Given the name of the stat (key), convert rating (R) to percentage
-- according to level (L)
-- ----------------------------------------------------------------------------

function ratingToPercentage(key, R, L)
	if R == 0 or L == 0 then return 0 end
	if segments[key] then return r2p_segment(R, L, segments[key]) end
	if linears[key] then return r2p_linear(R, L, linears[key]) end
    return 0
end

function ratingCap(key, L)
	if L == 0 then return nil end;
	if hascap[key] == nil then return nil end;
	if segments[key] then
	    local cap = 0
	    for _, seg in pairs(segments[key]) do
		    cap = cap + seg.dRL
	    end
	    return cap * L;
    elseif linears[key] then
	    for _, lin in pairs(linears[key]) do
		    if L <= lin.level then
                local cap = 1000.0 * (lin.cap - lin.C) / lin.factor(L)
                return cap
		    end
	    end
    end
end

-- ****************************************************************************
-- ****************************************************************************
--
-- Armor classes (to calculate mitigation percentages)
--
-- ****************************************************************************
-- ****************************************************************************

ArmorType = {
	[Turbine.Gameplay.Class.Beorning] = "MediumArmor",
	[Turbine.Gameplay.Class.Burglar] = "MediumArmor",
	[Turbine.Gameplay.Class.Captain] = "HeavyArmor",
	[Turbine.Gameplay.Class.Champion] = "HeavyArmor",
	[Turbine.Gameplay.Class.Guardian] = "HeavyArmor",
	[Turbine.Gameplay.Class.Hunter] = "MediumArmor",
	[Turbine.Gameplay.Class.LoreMaster] = "LightArmor",
	[Turbine.Gameplay.Class.Minstrel] = "LightArmor",
	[Turbine.Gameplay.Class.RuneKeeper] = "LightArmor",
	[Turbine.Gameplay.Class.Warden] = "MediumArmor",
}

-- BlackArrow
-- Chicken	192
-- Defiler	128
-- Ranger	191
-- Reaver	71
-- Stalker	126
-- Troll	190
-- Undefined	0
-- WarLeader	52
-- Weaver	127
