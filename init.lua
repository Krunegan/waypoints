local init = core.get_us_time()
local lane = core.get_modpath(core.get_current_modname())

dofile(lane.."/src/main.lua")

local done = (core.get_us_time() - init) / 1000000

core.log("action", "[Waypoints] loaded.. [" .. done .. "s]")