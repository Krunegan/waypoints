local init = minetest.get_us_time()
local lane = minetest.get_modpath(minetest.get_current_modname())

dofile(lane.."/src/main.lua")

local done = (minetest.get_us_time() - init) / 1000000

minetest.log("action", "[Waypoints] loaded.. [" .. done .. "s]")