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

-- ----------------------------------------------------------------------------
-- Stat data tables
-- ----------------------------------------------------------------------------

local segments = {
	["LightArmor"]  = {
	    Segment(104, 40,  0, 40, 1.6, 12800.0/100, 0),
	    Segment(105, 40,  0, 40, 1.6, 13600.0/105, 0),
	    Segment(nil, 40,  0, 40, 1.6, 13600.0/4.5, -13600*97/4.5),
	},
	["MediumArmor"] = {
	    Segment(104, 50,  0, 50, 10.0/7, 14867.0/100, 0),
	    Segment(105, 50,  0, 50, 10.0/7, 15714.25/105, 0),
	    Segment(nil, 50,  0, 50, 10.0/7, 15714.25/4.5, -15714.25*97/4.5),
	},
	["HeavyArmor"]  = {
	    Segment(104, 60,  0, 60, 1.2, 16650.00/100, 0),
	    Segment(105, 60,  0, 60, 1.2, 17519.75/105, 0),
	    Segment(nil, 60,  0, 60, 1.2, 17519.75/4.5, -17519.75*97/4.5),
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
	    --[[
	    Segment( 50, 60, 10, 50, 50, 121210.0 /  34, 0),
	    Segment(nil, 60, 10, 50, 50, 287750.0 / 105, 0),
	    ]]--
	    Segment( 20, 60, 10, 50, 50, 3500.0,      0.0),
	    Segment( 50, 60, 10, 50, 50, 3650.0,  -3000.0),
	    Segment(nil, 60, 10, 50, 50, 1969.0,  81050.0),
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

	["OutHeals"] = {
	    Segment( 20, 30,  0, 30, 0.43, 171.5,      0.0),
	    Segment( 50, 50,  0, 50, 1.00, 400.0,      0.0),
	    Segment(nil, 70,  0, 70, 1.40, 777.0, -10850.0),
	},

	["IncHeals"] = {
	    Segment( 50, 15,  0, 15, 1.00,        72.0,  0.0),
	    Segment(104, 25,  0, 25, 1.00,       243.0, -8550.0),
	    Segment(105, 25,  0, 25, 1.00, 17000.0/105,  0.0),
	    Segment(nil, 25,  0, 25, 1.00, 17000.0/4.5, -17000.0*97/4.5),
	},

	["Mastery"] = {
        Segment(100, 200, 0, 200, 1.0/9,    74166/100, 0),
        Segment(105, 400, 0, 400, 1.0/9,         42.0, 144090.0),
        Segment(nil, 400, 0, 400, 1.0/9, 222750.0/115, 0),
    },
    
--[[
	["IncHeals"] = {
		Segment(15, 100.0, 1190/3.0),
		Segment(10, 100.0, 2380/3.0)
	},
--]]
}

--[[
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
]]--

-- ----------------------------------------------------------------------------

local function findSegment(segments, L)
	if segments then
	    for _, segment in ipairs(segments) do
		    if segment.Lmax == nil or L <= segment.Lmax then
		        return segment
		    end
		end
	end
	return nil
end

function ratingToPercentage(key, R, L)
    if R ~= nil then
        local segment = findSegment(segments[key], L)
        if segment then return segment:p(R, L) end
    end
    return nil
end

function ratingCap(key, L)
    local segment = findSegment(segments[key], L)
    if segment and segment.Pcap then return segment:Rcap(L) end
    return nil
end

