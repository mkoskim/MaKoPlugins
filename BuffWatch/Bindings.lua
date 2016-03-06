-- ****************************************************************************
--
-- Import utils and bring some functions to local namespace: Make a copy
-- of this file to force bindings being plugin specific.
--
-- ****************************************************************************

import "MaKoPlugins.Utils";

Utils = MaKoPlugins.Utils

PlugIn = Utils.PlugIn(plugin)
HookTable = Utils.HookTable

println = Utils.println
INFO = function(fmt, ...) PlugIn:INFO(fmt, unpack(arg)) end
DEBUG = function(fmt, ...) PlugIn:DEBUG(fmt, unpack(arg)) end
xDEBUG = function(fmt, ...) end
atexit = function(callback) PlugIn:atexit(callback) end


