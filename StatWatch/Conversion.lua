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
-- New segment conversion function  for U20.1.2: Because of this, not
-- all conversions work yet.
-- ----------------------------------------------------------------------------

local function r2p(R, Pmax, C, Rcap)
    return Pmax * (C+1)/(C+Rcap/R)
end
    
-- ----------------------------------------------------------------------------
-- Segments
-- ----------------------------------------------------------------------------

local Segment = class()

function Segment:Constructor(Lmax, Pcap, Pmin, Pmax, C, RcapF, RcapC)
	self.Lmax  = Lmax
    self.Pcap  = Pcap
    self.Pmin  = Pmin
	self.Pmax  = Pmax
	self.C     = C
	self.RcapF = RcapF
    self.RcapC = RcapC
end

function Segment:Rcap(L)
    return L*self.RcapF + self.RcapC
end

function Segment:p(R, L)
    local p = self.Pmin + r2p(R, self.Pmax, self.C, self:Rcap(L))
    if self.Pcap then p = math.min(self.Pcap, p) end
    return p
end

local function r2p_segment(R, L, segments)
	for _, segment in ipairs(segments) do
		if segment.Lmax == nil or L <= segment.Lmax then
		    return segment:p(R, L)
		end
	end
	return nil;
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
	["LightArmor"]  = {
	    Segment(104, 40,  0, 40, 1.6, 12800.0/100, 0),
	    Segment(nil, 40,  0, 40, 1.6, 13600.0/105, 0),
	},
	["MediumArmor"] = {
	    Segment(104, 50,  0, 50, 10.0/7, 14867.0/100, 0),
	    Segment(nil, 50,  0, 50, 10.0/7, 15713.0/105, 0),
	},
	["HeavyArmor"]  = {
	    Segment(104, 60,  0, 60, 1.2, 16650.0/100, 0),
	    Segment(nil, 60,  0, 60, 1.2, 17520.0/105, 0),
	},

	["BPE"] = {
	    Segment( 20, 13,  0, 13, 2.0, 115,     0),
	    Segment( 50, 13,  0, 13, 2.0,  90,   500),
	    Segment(nil, 13,  0, 13, 2.0, 200, -5000),
	},
	["PartialBPE"] = {
	    Segment( 20, 15,  0, 15, 2.5, 112.5,      0),
	    Segment( 50, 15,  0, 15, 2.5,  75.0,    750),
	    Segment( 84, 17,  0, 17, 2.5, 775.0, -34250),
	    Segment( 95, 20,  0, 20, 2.5, 755.0, -32150),
	    Segment(nil, 35,  0, 35, 2.5, 850.0, -41750),
	},
	["PartialBPEMit"] = {
	    Segment( 50, 60, 10, 50, 50, 121210.0 /  34, 0),
	    Segment(nil, 60, 10, 50, 50, 287750.0 / 105, 0),
	},

	["Resistance"] = {
	    Segment( 50, 30,  0, 30, 1.0,  9000.0/ 50, 0),
	    Segment(nil, 50,  0, 50, 1.0, 39000.0/105, 0),
	},

	["CritRate"] = {
	    Segment( 50, 15,  0, 15, 0.66,  71.5,     0.0),
	    Segment( 84, 20,  0, 20, 1.00, 250.0, -6900.0),
	    Segment(nil, 25,  0, 25, 1.00, 175.0,  -625.0),
	},
	["DevRate"] = {
	    Segment( 50, 10,  0, 10, 2.00, 160.0,     0.0),
	    Segment( 95, 10,  0, 10, 2.00, 165.0,  -250.0),
	    Segment(nil, 10,  0, 10, 2.00, 180.0, -1700.0),
	},
	["CritMag"] = { Segment(nil, nil, 0, 50, 1.00, 300.0, 0.0), },
	["CritDef"] = { Segment(nil, nil, 0, 50, 1.00, 100.0, 0.0), },
	["Finesse"] = { Segment(nil, nil, 0, 50, 1.00, 400.0, 0.0), },

--[[
	["OutHeals"] = {
		Segment(30, 100.0, 1190/3.0, 50),
		Segment(20, 100.0, 2380/3.0),
		Segment(20, 100.0, 1190)
	},
	["IncHeals"] = {
		Segment(15, 100.0, 1190/3.0),
		Segment(10, 100.0, 2380/3.0)
	},
--]]
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
	"Mastery",
	"OutHeals",
	"Resistance",
	"IncHeals",
	"BPE",
	"PartialBPE",
	-- "PartialMit",
	"LightArmor",
	"MediumArmor",
	"HeavyArmor",
}

-- ----------------------------------------------------------------------------
-- Given the name of the stat (key), convert rating (R) to percentage
-- according to level (L)
-- ----------------------------------------------------------------------------

function ratingToPercentage(key, R, L)
    if R == nil then return nil end
	if segments[key] then return r2p_segment(R, L, segments[key]) end
	if linears[key] then return r2p_linear(R, L, linears[key]) end
    return nil
end

function ratingCap(key, L)
	if hascap[key] == nil then return nil end;
	if segments[key] then
	    for _, segment in ipairs(segments[key]) do
		    if segment.Lmax == nil or L <= segment.Lmax then
			    return segment:Rcap(L)
		    end
	    end
    elseif linears[key] then
	    for _, lin in pairs(linears[key]) do
		    if L <= lin.level then
                local cap = 1000.0 * (lin.cap - lin.C) / lin.factor(L)
                return cap
		    end
	    end
    end
end

