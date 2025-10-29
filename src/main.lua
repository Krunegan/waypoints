--[[

The MIT License (MIT)
Copyright (C) 2025 Flay Krunegan

Permission is hereby granted, free of charge, to any person obtaining a copy of this
software and associated documentation files (the "Software"), to deal in the Software
without restriction, including without limitation the rights to use, copy, modify, merge,
publish, distribute, sublicense, and/or sell copies of the Software, and to permit
persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

]]

local modpath = core.get_modpath(core.get_current_modname()) .. "/src"
local storage = dofile(modpath .. "/storage.lua")
local utils = dofile(modpath .. "/utils.lua")
local hud = dofile(modpath .. "/hud.lua")
local guilds = dofile(modpath .. "/guilds.lua")(storage, hud)

local way = {}

core.register_on_joinplayer(function(p)
    local n = p:get_player_name()
    way[n] = storage.lod(n)
end)

core.register_on_leaveplayer(function(p)
    local n = p:get_player_name()
    hud.hid(n)
    hud.hid_s(n)
    storage.sav(n, way[n])
    way[n] = nil
end)

core.register_on_shutdown(function()
    for n, d in pairs(way) do
        storage.sav(n, d)
    end
    guilds.save_all()
end)

dofile(modpath .. "/commands_waypoints.lua")(storage, utils, hud, guilds, way)
dofile(modpath .. "/commands_guilds.lua")(storage, utils, hud, guilds, way)