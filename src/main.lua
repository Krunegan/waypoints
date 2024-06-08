--[[

The MIT License (MIT)
Copyright (C) 2024 Flay Krunegan

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

local sto = minetest.get_mod_storage()

local function lod(n)
    local d = sto:get_string(n)
    if d ~= '' then
        return minetest.deserialize(d)
    else
        return {}
    end
end

local function sav(n, d)
    sto:set_string(n, minetest.serialize(d))
end

local way = {}

local function saf(f)
    return function(...)
        local s, o = pcall(f, ...)
        if s then
            return o
        else
            minetest.log('warning', 'Error: ' .. o)
            return nil
        end
    end
end

local function hid_s(n)
    local p = minetest.get_player_by_name(n)
    if not p then
        return
    end

    local m = p:get_meta()
    local h = m:get_string('h_s')
    if h == '' then
        return
    end

    local hu = minetest.deserialize(h)
    for _, hi in ipairs(hu) do
        p:hud_remove(hi)
    end

    m:set_string('h_s', '')
end

local function hid(n)
    local p = minetest.get_player_by_name(n)
    if not p then
        return
    end

    local m = p:get_meta()
    local h = m:get_string('h')
    if h == '' then
        return
    end
    
    local hu = minetest.deserialize(h)
    for _, hi in ipairs(hu) do
        p:hud_remove(hi)
    end
    m:set_string('h', '')
end

local function sho(n)
    local p = minetest.get_player_by_name(n)
    if not p then
        return
    end

    local m = p:get_meta()
    local hu = {}

    for w, d in pairs(way[n] or {}) do
        local c = d.color or 0xFFFFFF
        local h = p:hud_add({
            hud_elem_type = 'waypoint',
            name = w,
            number = c,
            world_pos = d.position,
            text = string.format("m | (%d, %d, %d)", d.position.x, d.position.y, d.position.z)
        })
        table.insert(hu, h)
    end

    m:set_string('h', minetest.serialize(hu))
end

minetest.register_on_joinplayer(function(p)
    local n = p:get_player_name()
    way[n] = lod(n)
end)

minetest.register_on_leaveplayer(function(p)
    local n = p:get_player_name()
    hid(n)
    hid_s(n)
    sav(n, way[n])
    way[n] = nil
end)

minetest.register_on_shutdown(function()
    for n, d in pairs(way) do
        sav(n, d)
    end
end)

minetest.register_chatcommand('wp_show', {
    params = '',
    description = 'Show all waypoints HUD',
    func = saf(function(n, _)
        hid(n)
        hid_s(n)
        sho(n)
        minetest.chat_send_player(n, 'Waypoints HUD shown.')
    end),
})

minetest.register_chatcommand('wp_hide', {
    params = '',
    description = 'Hide all waypoints HUD',
    func = saf(function(n, _)
        hid(n)
        hid_s(n)
        minetest.chat_send_player(n, 'Waypoints HUD hidden.')
    end),
})

minetest.register_chatcommand('wp_set', {
    params = '<name> <color>',
    description = 'Set a waypoint with color (format: RRGGBB)',
    func = saf(function(n, p)
        local pr = p:split(' ')
        if #pr < 2 then
            minetest.chat_send_player(n, 'Usage: /wp_set <name> <color>')
            return
        end

        local wn = pr[1]
        local wc = tonumber(pr[2], 16)
        if not wc then
            minetest.chat_send_player(n, 'Invalid color format. Please use RRGGBB format.')
            return
        end

        local pl = minetest.get_player_by_name(n)
        if not pl then
            return
        end

        local po = vector.round(pl:get_pos())

        if way[n] and way[n][wn] then
            minetest.chat_send_player(n, 'Waypoint name is already in use. Please choose a different name.')
            return
        end

        way[n] = way[n] or {}
        way[n][wn] = { position = po, color = wc }
        minetest.chat_send_player(
            n,
            ('Set waypoint "%s" to "%i %i %i" with color #%06X'):format(wn, po.x, po.y, po.z, wc)
        )

        hid_s(n)
        hid(n)
        sav(n, way[n])
        sho(n)
    end),
})


minetest.register_chatcommand('wp_unset', {
    params = '<name>',
    description = 'Remove a waypoint',
    func = saf(function(n, p)
        local wn = p:trim()
        if wn == '' then
            minetest.chat_send_player(n, 'Usage: /wp_unset <name>')
            return
        end

        if not way[n] or not way[n][wn] then
            minetest.chat_send_player(n, ('Waypoint "%s" not found.'):format(wn))
            return
        end

        hid_s(n)
        hid(n)

        way[n][wn] = nil
        minetest.chat_send_player(n, ('Removed waypoint "%s"'):format(wn))

        sav(n, way[n])
        sho(n)
    end),
})

minetest.register_chatcommand('wp_list', {
    params = '',
    description = 'List all waypoints',
    func = function(n, _)
        local w = lod(n)
        local m = 'Waypoints:\n'
        for wn, d in pairs(w) do
            local po = d.position or vector.new(0, 0, 0)
            local ns = minetest.colorize("#FFFFFF", "Name: ") .. minetest.colorize("#" .. string.format("%06X", d.color or 0xFFFFFF), wn)
            local cs = minetest.colorize("#FFFFFF", " | Color: ") .. minetest.colorize("#" .. string.format("%06X", d.color or 0xFFFFFF), "#" .. string.format("%06X", d.color or 0xFFFFFF))
            local cs2 = minetest.colorize("#FFFFFF", " | Position: (") .. minetest.colorize("#" .. string.format("%06X", d.color or 0xFFFFFF), string.format("%i, %i, %i", po.x, po.y, po.z)) .. minetest.colorize("#FFFFFF", ")")
            m = m .. string.format("%s%s%s\n", ns, cs, cs2)
        end
        minetest.chat_send_player(n, m)
    end,
})

minetest.register_chatcommand('wp_show_s', {
    params = '<name>',
    description = 'Show a specific waypoint HUD and hide others',
    func = saf(function(n, p)
        local wn = p:trim()
        if wn == '' then
            minetest.chat_send_player(n, 'Usage: /wp_show_s <name>')
            return
        end

        local pl = minetest.get_player_by_name(n)
        if not pl then
            return
        end

        hid_s(n)
        hid(n)

        local d = way[n][wn]
        if not d then
            minetest.chat_send_player(n, ('Waypoint "%s" not found.'):format(wn))
            return
        end

        local c = d.color or 0xFFFFFF
        local h = pl:hud_add({
            hud_elem_type = 'waypoint',
            name = wn,
            number = c,
            world_pos = d.position,
            text = string.format("m | (%d, %d, %d)", d.position.x, d.position.y, d.position.z)
        })

        local m = ('Waypoint "%s" HUD shown.'):format(wn)
        minetest.chat_send_player(n, m)

        local meta = pl:get_meta()
        local h_ids_str = meta:get_string('h_s')
        local h_ids = h_ids_str == '' and {} or minetest.deserialize(h_ids_str)
        table.insert(h_ids, h)
        meta:set_string('h_s', minetest.serialize(h_ids))
    end),
})

minetest.register_chatcommand('wp_set_coord', {
    params = '<name> <x,y,z> <color>',
    description = 'Set a waypoint at specific coordinates with color (format: RRGGBB)',
    func = saf(function(n, p)
        local pr = p:split(' ')
        if #pr < 3 then
            minetest.chat_send_player(n, 'Usage: /wp_set_coord <name> <x,y,z> <color>')
            return
        end

        local wn = pr[1]
        local pos_str = pr[2]
        local wc = tonumber(pr[3], 16)

        local pl = minetest.get_player_by_name(n)
        if not pl then
            return
        end

        local pos_vals = pos_str:split(',')
        if #pos_vals < 3 then
            minetest.chat_send_player(n, 'Invalid coordinates format. Please use <x,y,z>.')
            return
        end

        local px, py, pz = tonumber(pos_vals[1]), tonumber(pos_vals[2]), tonumber(pos_vals[3])
        if not px or not py or not pz then
            minetest.chat_send_player(n, 'Invalid coordinates format. Please use numbers for <x,y,z>.')
            return
        end

        local po = vector.round(vector.new(px, py, pz))

        if way[n] and way[n][wn] then
            minetest.chat_send_player(n, 'Waypoint name is already in use. Please choose a different name.')
            return
        end

        way[n] = way[n] or {}
        way[n][wn] = { position = po, color = wc }
        minetest.chat_send_player(
            n,
            ('Set waypoint "%s" at coordinates "%i %i %i" with color #%06X'):format(wn, po.x, po.y, po.z, wc)
        )
        
        hid_s(n)
        hid(n)
        sav(n, way[n])
        sho(n)
    end),
})

minetest.register_chatcommand('wp_move', {
    params = '<name> <x,y,z>',
    description = 'Move a waypoint to a new position',
    func = saf(function(n, p)
        local pr = p:split(' ')
        if #pr < 2 then
            minetest.chat_send_player(n, 'Usage: /wp_move <name> <x,y,z>')
            return
        end

        local wn = pr[1]
        local pos_str = pr[2]

        local pl = minetest.get_player_by_name(n)
        if not pl then
            return
        end

        local pos_vals = pos_str:split(',')
        if #pos_vals < 3 then
            minetest.chat_send_player(n, 'Invalid coordinates format. Please use <x,y,z>.')
            return
        end

        local px, py, pz = tonumber(pos_vals[1]), tonumber(pos_vals[2]), tonumber(pos_vals[3])
        if not px or not py or not pz then
            minetest.chat_send_player(n, 'Invalid coordinates format. Please use numbers for <x,y,z>.')
            return
        end

        local po = vector.round(vector.new(px, py, pz))

        if not way[n] or not way[n][wn] then
            minetest.chat_send_player(n, ('Waypoint "%s" not found.'):format(wn))
            return
        end

        way[n][wn].position = po
        minetest.chat_send_player(
            n,
            ('Moved waypoint "%s" to new coordinates "%i %i %i"'):format(wn, po.x, po.y, po.z)
        )

        hid_s(n)
        hid(n)
        sav(n, way[n])
        sho(n)
    end),
})

minetest.register_chatcommand('wp_cc', {
    params = '<name> <color>',
    description = 'Change color of an existing waypoint (format: RRGGBB)',
    func = saf(function(n, p)
        local pr = p:split(' ')
        if #pr < 2 then
            minetest.chat_send_player(n, 'Usage: /wp_cc <name> <color>')
            return
        end

        local wn = pr[1]
        local wc = tonumber(pr[2], 16)

        if not way[n] or not way[n][wn] then
            minetest.chat_send_player(n, ('Waypoint "%s" not found.'):format(wn))
            return
        end

        way[n][wn].color = wc
        minetest.chat_send_player(
            n,
            ('Changed color of waypoint "%s" to #%06X'):format(wn, wc)
        )

        hid_s(n)
        hid(n)
        sav(n, way[n])
        sho(n)
    end),
})

minetest.register_chatcommand('wp_dis', {
    params = '<name>',
    description = 'Show distance to a waypoint',
    func = saf(function(n, p)
        local pr = p:split(' ')
        if #pr < 1 then
            minetest.chat_send_player(n, 'Usage: /wp_dis <name>')
            return
        end

        local wn = pr[1]

        local pl = minetest.get_player_by_name(n)
        if not pl then
            return
        end

        if not way[n] or not way[n][wn] then
            minetest.chat_send_player(n, ('Waypoint "%s" not found.'):format(wn))
            return
        end

        local player_pos = vector.round(pl:get_pos())
        local wp_pos = way[n][wn].position
        local distance = vector.distance(player_pos, wp_pos)

        minetest.chat_send_player(
            n,
            ('Distance to waypoint "%s": %.2f meters'):format(wn, distance)
        )
    end),
})

minetest.register_chatcommand('wp_delete_all', {
    params = '',
    description = 'Delete all waypoints of the user',
    func = saf(function(n, _)
        if not way[n] then
            minetest.chat_send_player(n, 'You have no waypoints to delete.')
            return
        end

        way[n] = {}
        minetest.chat_send_player(n, 'All waypoints deleted.')
        sav(n, way[n])
        hid(n)
    end),
})

minetest.register_chatcommand('wp_info', {
    params = '<name>',
    description = 'Show detailed information about a waypoint',
    func = saf(function(player_name, param)
        local wp_name = param:trim()
        if wp_name == '' then
            minetest.chat_send_player(player_name, 'Usage: /wp_info <name>')
            return
        end

        local player_waypoints = way[player_name] or {}
        local wp_data = player_waypoints[wp_name]
        if not wp_data then
            minetest.chat_send_player(player_name, ('Waypoint "%s" not found.'):format(wp_name))
            return
        end

        local wp_pos = wp_data.position
        local wp_color = wp_data.color or 0xFFFFFF

        local pl = minetest.get_player_by_name(player_name)
        if not pl then
            return
        end

        local player_pos = vector.round(pl:get_pos())
        local distance = vector.distance(wp_pos, player_pos)

        local info_message = ('Waypoint "%s" Information:\n'):format(wp_name)
        info_message = info_message .. ('Position: %i, %i, %i\n'):format(wp_pos.x, wp_pos.y, wp_pos.z)
        info_message = info_message .. ('Color: %s\n'):format(minetest.colorize('#' .. string.format('%06X', wp_color), '#' .. string.format('%06X', wp_color)))
        info_message = info_message .. ('Distance: %.2f meters\n'):format(distance)

        minetest.chat_send_player(player_name, info_message)
    end),
})

minetest.register_chatcommand('wp_rename', {
    params = '<old_name> <new_name>',
    description = 'Rename a waypoint',
    func = saf(function(n, p)
        local pr = p:split(' ')
        if #pr < 2 then
            minetest.chat_send_player(n, 'Usage: /wp_rename <old_name> <new_name>')
            return
        end

        local old_name = pr[1]
        local new_name = pr[2]

        local player_waypoints = way[n] or {}
        local wp_data = player_waypoints[old_name]
        if not wp_data then
            minetest.chat_send_player(n, ('Waypoint "%s" not found.'):format(old_name))
            return
        end

        if player_waypoints[new_name] then
            minetest.chat_send_player(n, 'The new name is already in use. Please choose a different name.')
            return
        end

        player_waypoints[new_name] = wp_data
        player_waypoints[old_name] = nil

        minetest.chat_send_player(n, ('Waypoint "%s" renamed to "%s".'):format(old_name, new_name))
        hid_s(n)
        hid(n)
        sav(n, way[n])
        sho(n)
    end),
})

minetest.register_chatcommand('wp_toggle_hud', {
    params = '<name>',
    description = 'Toggle HUD for a specific waypoint',
    func = saf(function(n, p)
        local wn = p:trim()
        if wn == '' then
            minetest.chat_send_player(n, 'Usage: /wp_toggle_hud <name>')
            return
        end

        local pl = minetest.get_player_by_name(n)
        if not pl then
            return
        end

        -- hid_s(n)
        -- hid(n)

        local d = way[n][wn]
        if not d then
            minetest.chat_send_player(n, ('Waypoint "%s" not found.'):format(wn))
            return
        end

        local h_ids_str = pl:get_meta():get_string('h_s')
        local h_ids = h_ids_str == '' and {} or minetest.deserialize(h_ids_str)

        local found = false
        for _, h_id in ipairs(h_ids) do
            local hud = pl:hud_get(h_id)
            if hud and hud.name == wn then
                pl:hud_remove(h_id)
                found = true
                break
            end
        end

        if not found then
            local c = d.color or 0xFFFFFF
            local h = pl:hud_add({
                hud_elem_type = 'waypoint',
                name = wn,
                number = c,
                world_pos = d.position,
                text = string.format("m | (%d, %d, %d)", d.position.x, d.position.y, d.position.z)
            })

            table.insert(h_ids, h)
            minetest.chat_send_player(n, ('Waypoint "%s" HUD toggled.'):format(wn))
        else
            minetest.chat_send_player(n, ('Waypoint "%s" HUD hidden.'):format(wn))
        end

        pl:get_meta():set_string('h_s', minetest.serialize(h_ids))
    end),
})

minetest.register_privilege("waypoints_tp", {
    description = "Allows teleportation to waypoints",
    give_to_singleplayer = false,
})

minetest.register_chatcommand('wp_tp', {
    params = '<name> [optional_playername]',
    description = 'Teleport to a waypoint or teleport another player to a waypoint',
    privs = { waypoints_tp = true },
    func = saf(function(sender_name, param)
        local pr = param:split(' ')
        if #pr < 1 then
            minetest.chat_send_player(sender_name, 'Usage: /wp_tp <name> [optional_playername]')
            return
        end

        local wp_name = pr[1]
        local target_player_name = pr[2] or sender_name

        local player_waypoints = way[sender_name] or {}
        local wp_data = player_waypoints[wp_name]
        if not wp_data then
            minetest.chat_send_player(sender_name, ('Waypoint "%s" not found.'):format(wp_name))
            return
        end

        local target_player = minetest.get_player_by_name(target_player_name)
        if not target_player then
            minetest.chat_send_player(sender_name, ('Player "%s" not found.'):format(target_player_name))
            return
        end

        target_player:set_pos(wp_data.position)
        minetest.chat_send_player(sender_name, ('Teleported "%s" to waypoint "%s".'):format(target_player_name, wp_name))
    end),
})
