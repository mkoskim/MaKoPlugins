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

PlugIn = class()

function PlugIn:Constructor(plugin)
    self.plugin = plugin
    self.name = plugin:GetName()
    self._atexittbl = { }

    plugin.Unload = function() self:Unload() end
end

-- ----------------------------------------------------------------------------

function PlugIn:INFO(fmt, ...)
	println( self.name .. ": " .. fmt, unpack(arg))
end

function PlugIn:DEBUG(fmt, ...)
	self:INFO("DEBUG: " .. fmt, unpack(arg))
end

-- ----------------------------------------------------------------------------

function PlugIn:SetOptionsPanel(optpanel)
    self.optpanel = optpanel
    
    self.plugin.GetOptionsPanel = function()
        return self.optpanel
    end
end

-- ----------------------------------------------------------------------------

function PlugIn:atexit(callback)
    table.insert(self._atexittbl, callback)
end

function PlugIn:Unload()
    for _, callback in pairs(self._atexittbl) do
        callback()
    end
end

-- ----------------------------------------------------------------------------

function PlugIn:LoadSettings(filename, defaults)
    return Turbine.PluginData.Load(
        Turbine.DataScope.Character,
        filename
    ) or defaults;
end

function PlugIn:SaveSettings(filename, settings)
    Turbine.PluginData.Save(
	    Turbine.DataScope.Character,
	    filename,
	    settings
    )
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
-- Hooking callbacks to objects
--
-- ****************************************************************************
-- ****************************************************************************

HookTable = class()

function HookTable:Constructor( hooks )
    self.hooks = hooks
end

function HookTable:Install()
	for _, entry in pairs(self.hooks) do
		if entry.object ~= nil then
			AddCallback(entry.object, entry.event, entry.callback)
		end
	end
end

function HookTable:Uninstall()
	for _, entry in pairs(self.hooks) do
		if entry.object ~= nil then
			AddCallback(entry.object, entry.event, entry.callback)
		end
	end
end

