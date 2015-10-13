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
-- Basic conversion function
-- ----------------------------------------------------------------------------

local function r2p(K, RL)
	return 100 * (1 / (1 + K/RL))
	end

-- ----------------------------------------------------------------------------
-- Segments
-- ----------------------------------------------------------------------------

local Segment = class()

function Segment:Constructor(dP, K, dRL)
	self.dP = dP
	self.K = K
	self.dRL = dRL
end

local function r2p_segment(RL, segments)
	p = 0
	for key, segment in ipairs(segments) do
		if segment.dRL == 0 or segment.dRL > RL then
			return p + r2p(segment.K, RL)
		else
			p = p + segment.dP
			RL = RL - segment.dRL
		end
	end
	return p
end

-- ----------------------------------------------------------------------------
--
-- ----------------------------------------------------------------------------

local segments = {
	["CritRate"] = {
		Segment(15.0, 1190/3, 70),
		Segment( 5.0,  794.8, 794.8/19),
		Segment( 5.0, 1075.2, 1075.2/19)
	},
	["DevRate"] = { Segment(10.0, 1330, 1330/9) },
	["CritMag"] = { Segment(0, 300.0, 0) },
	["Finesse"] = {
		Segment(30, 1190/3, 170),
		Segment(20, 2380/3, 595/3)
	},
	["Mastery"] = {
		Segment(20, 300, 75),
		Segment(20, 300, 75),
		Segment(20, 300, 75),
		Segment(20, 300, 75),
		Segment(40, 300, 200),
		Segment(20, 300, 75),
		Segment(20, 300, 75),
		Segment(20, 300, 75),
		Segment(20, 300, 75)
	},
	["OutHeals"] = {
		Segment(30, 1190/3, 170),
		Segment(20, 2380/3, 595/3),
		Segment(20, 1190,   297.5)
	},
	["Resistance"] = {
		Segment(30, 1190/3, 170),
		Segment(20, 2380/3, 595/3)
	},
	["CritDef"] = { Segment(0, 100.0, 0) },
	["IncHeals"] = {
		Segment(15, 1190/3, 70),
		Segment(10, 2380/3, 2380/27)
	},
	["Avoidances"] = {
		Segment(15.0,  396.7, 1190.1/17),
		Segment( 2.0,  991.5,  991.5/49),
		Segment( 3.0, 1984.0, 5952.0/97),
		Segment( 5.0, 3968.0, 3968.0/19)
	},
	["Partials"] = { Segment(10, 1330, 1330/9) },
	["LightArmor"] = {
		Segment(20, 150, 37.5),
		Segment(20, 350, 87.5)
	},
	["MediumArmor"] = {
		Segment(20, 150, 37.5),
		Segment(30, 350, 150)
	},
	["HeavyArmor"] = {
		Segment(10, 5697/38, 633/38),
		Segment(50, 5697/38, 5697/38)
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
	"Finesse",
    "Mastery",
	"OutHeals",
	"Resistance",
	"IncHeals",
	"Avoidances",
	"Partials",
	"LightArmor",
	"MediumArmor",
	"HeavyArmor",
}

-- ----------------------------------------------------------------------------
--
-- ----------------------------------------------------------------------------

function ratingToPercentage(key, R, L)
	return (R and L and segments[key]) and r2p_segment(R/L, segments[key]) or 0;
end

function ratingCap(key, L)
	if L == 0 then return nil end;
	if hascap[key] == nil then return nil end;
	cap = 0
	for _, seg in pairs(segments[key]) do
		cap = cap + seg.dRL
	end
	return cap * L;
end

-- ****************************************************************************
-- ****************************************************************************
--
-- Armor classes (to calculate mitigation percentages)
--
-- ****************************************************************************
-- ****************************************************************************

ArmorType = {
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
