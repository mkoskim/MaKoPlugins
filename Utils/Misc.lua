-- ****************************************************************************
-- ****************************************************************************
--
-- Misc Utilities
--
-- ****************************************************************************
-- ****************************************************************************

import "MaKoPlugins.Utils.Class";

-- ****************************************************************************

function _G.println(fmt, ...)
	Turbine.Shell.WriteLine(string.format(fmt, unpack(arg)))
end

-- ****************************************************************************

function _G.INFO(fmt, ...)
	println( plugin:GetName() .. ": " .. fmt, unpack(arg))
end

function _G.DEBUG(fmt, ...)
	if debugging then
		INFO("DEBUG: " .. fmt, unpack(arg))
	end
end

function _G.xDEBUG(fmt, ...)
end

-- ****************************************************************************

function plugin.LoadSettings(filename, defaults)
    return Turbine.PluginData.Load(
	    Turbine.DataScope.Character,
	    filename
    ) or defaults;
end

function plugin.SaveSettings(filename, settings)
    Turbine.PluginData.Save(
		Turbine.DataScope.Character,
		filename,
		settings
	)
end

-- ****************************************************************************

plugin._atexittbl = { }

function _G.atexit(callback)
	table.insert(plugin._atexittbl, callback)
end

plugin.Unload = function(self)
    _G.plugin = self
    for _, callback in pairs(self._atexittbl) do
		callback()
	end
	_G.plugin = nil
	self._atexittbl = { }
end

-- ****************************************************************************
-- ****************************************************************************

function _G.dumptable(tbl)
	for k, v in pairs(tbl) do
		println("%s (%s)", k, tostring(v))
		end
	end

-- ****************************************************************************
-- ****************************************************************************
--
-- Hooking objects
--
-- ****************************************************************************
-- ****************************************************************************

_G.HookTable = class()

function HookTable:Constructor( hooks )
    self.hooks = hooks
end

function HookTable:Install()
	xDEBUG("Installing hooks...")
	for _, entry in pairs(self.hooks) do
		if entry.object ~= nil then
			AddCallback(entry.object, entry.event, entry.callback)
		end
	end
end

function HookTable:Uninstall()
	xDEBUG("Removing hooks...")
	for _, entry in pairs(self.hooks) do
		if entry.object ~= nil then
			AddCallback(entry.object, entry.event, entry.callback)
		end
	end
end

