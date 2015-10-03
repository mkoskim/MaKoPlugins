-- ****************************************************************************
-- ****************************************************************************
--
-- Misc Utilities
--
-- ****************************************************************************
-- ****************************************************************************

import "MaKoPlugins.Utils.Class";

-- ****************************************************************************

function println(fmt, ...)
	Turbine.Shell.WriteLine(string.format(fmt, unpack(arg)))
end

-- ****************************************************************************
-- Store Plug-in name: when unloading, global plugin is destroyed when Unload
-- is called.
-- ****************************************************************************

PlugIn = class()

function PlugIn:Constructor()
	self._atexit = {}
	self.name = plugin:GetName()
    self:INFO("Loading")
	plugin.Unload = function()
		self:INFO("Unloading...")
		self:atexit_execute()
	end
end

-- ****************************************************************************

function PlugIn:INFO(fmt, ...)
	println( self.name .. ": " .. fmt, unpack(arg))
	end

function PlugIn:DEBUG(fmt, ...)
	if debugging then
		self:INFO("DEBUG: " .. str, unpack(arg))
		end
	end

function PlugIn:xDEBUG(fmt, ...)
	end

-- ****************************************************************************

function PlugIn:atexit(callback)
	table.insert(self._atexit, callback)
end

function PlugIn:atexit_execute()
	local size = table.getn(self._atexit);
    for i = 1, size do
		self._atexit[i]()
	end
	self._atexit = { }
end

-- ****************************************************************************
-- ****************************************************************************

function showfields(tbl)
	for k, v in pairs(tbl) do
		println( "Name: %s, value: %s", tostring(k), tostring(v) )
		end
	end

-- ****************************************************************************
-- ****************************************************************************
--
--
--
-- ****************************************************************************
-- ****************************************************************************

-- ----------------------------------------------------------------------------
-- Use Galuhad's implementation instead (AddCallBack.lua)
-- ----------------------------------------------------------------------------

--[[
function AddCallback(object, event, callback)
	xDEBUG("AddCallback: " .. event)
    if (object[event] == nil) then
        object[event] = callback;
    else
        if (type(object[event]) == "table") then
            table.insert(object[event], callback);
        else
            object[event] = {object[event], callback};
        end
    end
    return callback;
end
]]

-- ----------------------------------------------------------------------------

function RemoveCallback(object, event, callback)
    if (object[event] == callback) then
        object[event] = nil;
    else
        if (type(object[event]) == "table") then
            local size = table.getn(object[event]);
            for i = 1, size do
                if (object[event][i] == callback) then
                    table.remove(object[event], i);
                    break;
                end
            end
        end
    end
end

-- ****************************************************************************

function FormatNumber(number, decimals)

	if number < 1000 then
		return string.format("%." .. tostring(decimals or 0) .. "f", number)
	-- elseif number < 1000 then
	--	return string.format("%.0f", number)
	elseif number < 900000 then
		return string.format("%d,%03d", (number+0.5)/1000, (number+0.5)%1000)
	else
		return string.format("%.3fM", number/1e6)
	end

end

