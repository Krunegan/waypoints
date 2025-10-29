return function(storage, utils, hud, guilds_mod, way)
    local saf = utils.saf
    local lod = storage.lod
    local sav = storage.sav
    local guilds = guilds_mod._guilds

    core.register_chatcommand('wp_show', {
        params = '',
        description = 'Show all waypoints HUD',
        func = saf(function(n, _)
            hud.hid(n)
            hud.hid_s(n)
            hud.sho(n, way, guilds)
            core.chat_send_player(n, 'Waypoints HUD shown.')
        end),
    })

    core.register_chatcommand('wp_hide', {
        params = '',
        description = 'Hide all waypoints HUD',
        func = saf(function(n, _)
            hud.hid(n)
            hud.hid_s(n)
            core.chat_send_player(n, 'Waypoints HUD hidden.')
        end),
    })

    core.register_chatcommand('wp_set', {
        params = '<name> <color>',
        description = 'Set a waypoint with color (format: RRGGBB)',
        func = saf(function(n, p)
            local pr = p:split(' ')
            if #pr < 2 then core.chat_send_player(n, 'Usage: /wp_set <name> <color>'); return end
            local wn = pr[1]
            local wc = tonumber(pr[2], 16)
            if not wc then core.chat_send_player(n, 'Invalid color format. Please use RRGGBB format.'); return end
            local pl = core.get_player_by_name(n)
            if not pl then return end
            local po = vector.round(pl:get_pos())
            if way[n] and way[n][wn] then core.chat_send_player(n, 'Waypoint name is already in use. Please choose a different name.'); return end
            way[n] = way[n] or {}
            way[n][wn] = { position = po, color = wc }
            core.chat_send_player(n, ('Set waypoint "%s" to "%i %i %i" with color #%06X'):format(wn, po.x, po.y, po.z, wc))
            hud.hid_s(n)
            hud.hid(n)
            sav(n, way[n])
            hud.sho(n, way, guilds)
        end),
    })

    core.register_chatcommand('wp_unset', {
        params = '<name>',
        description = 'Remove a waypoint',
        func = saf(function(n, p)
            local wn = p:trim()
            if wn == '' then core.chat_send_player(n, 'Usage: /wp_unset <name>'); return end
            if not way[n] or not way[n][wn] then core.chat_send_player(n, ('Waypoint "%s" not found.'):format(wn)); return end
            hud.hid_s(n)
            hud.hid(n)
            way[n][wn] = nil
            core.chat_send_player(n, ('Removed waypoint "%s"'):format(wn))
            sav(n, way[n])
            hud.sho(n, way, guilds)
        end),
    })

    core.register_chatcommand('wp_list', {
        params = '',
        description = 'List all waypoints',
        func = function(n, _)
            local w = lod(n)
            local m = 'Waypoints:\n'
            for wn, d in pairs(w) do
                local po = d.position or vector.new(0, 0, 0)
                local ns = core.colorize("#FFFFFF", "Name: ") .. core.colorize("#" .. string.format("%06X", d.color or 0xFFFFFF), wn)
                local cs = core.colorize("#FFFFFF", " | Color: ") .. core.colorize("#" .. string.format("%06X", d.color or 0xFFFFFF), "#" .. string.format("%06X", d.color or 0xFFFFFF))
                local cs2 = core.colorize("#FFFFFF", " | Position: (") .. core.colorize("#" .. string.format("%06X", d.color or 0xFFFFFF), string.format("%i, %i, %i", po.x, po.y, po.z)) .. core.colorize("#FFFFFF", ")")
                m = m .. string.format("%s%s%s\n", ns, cs, cs2)
            end
            core.chat_send_player(n, m)
        end,
    })

    core.register_chatcommand('wp_show_s', {
        params = '<name>',
        description = 'Show a specific waypoint HUD and hide others',
        func = saf(function(n, p)
            local wn = p:trim()
            if wn == '' then core.chat_send_player(n, 'Usage: /wp_show_s <name>'); return end
            local pl = core.get_player_by_name(n)
            if not pl then return end
            hud.hid_s(n)
            hud.hid(n)
            local d = way[n] and way[n][wn]
            if not d then core.chat_send_player(n, ('Waypoint "%s" not found.'):format(wn)); return end
            local c = d.color or 0xFFFFFF
            local h = pl:hud_add({ hud_elem_type = 'waypoint', name = wn, number = c, world_pos = d.position, text = string.format("m | (%d, %d, %d)", d.position.x, d.position.y, d.position.z) })
            core.chat_send_player(n, ('Waypoint "%s" HUD shown.'):format(wn))
            local meta = pl:get_meta()
            local h_ids_str = meta:get_string('h_s')
            local h_ids = h_ids_str == '' and {} or core.deserialize(h_ids_str)
            table.insert(h_ids, h)
            meta:set_string('h_s', core.serialize(h_ids))
        end),
    })

    core.register_chatcommand('wp_set_coord', {
        params = '<name> <x,y,z> <color>',
        description = 'Set a waypoint at specific coordinates with color (format: RRGGBB)',
        func = saf(function(n, p)
            local pr = p:split(' ')
            if #pr < 3 then core.chat_send_player(n, 'Usage: /wp_set_coord <name> <x,y,z> <color>'); return end
            local wn, pos_str, wc = pr[1], pr[2], tonumber(pr[3], 16)
            local pl = core.get_player_by_name(n)
            if not pl then return end
            local pos_vals = pos_str:split(',')
            if #pos_vals < 3 then core.chat_send_player(n, 'Invalid coordinates format. Please use <x,y,z>.'); return end
            local px, py, pz = tonumber(pos_vals[1]), tonumber(pos_vals[2]), tonumber(pos_vals[3])
            if not px or not py or not pz then core.chat_send_player(n, 'Invalid coordinates format. Please use numbers for <x,y,z>.'); return end
            local po = vector.round(vector.new(px, py, pz))
            if way[n] and way[n][wn] then core.chat_send_player(n, 'Waypoint name is already in use. Please choose a different name.'); return end
            way[n] = way[n] or {}
            way[n][wn] = { position = po, color = wc }
            core.chat_send_player(n, ('Set waypoint "%s" at coordinates "%i %i %i" with color #%06X'):format(wn, po.x, po.y, po.z, wc))
            hud.hid_s(n)
            hud.hid(n)
            sav(n, way[n])
            hud.sho(n, way, guilds)
        end),
    })

    core.register_chatcommand('wp_move', {
        params = '<name> <x,y,z>',
        description = 'Move a waypoint to a new position',
        func = saf(function(n, p)
            local pr = p:split(' ')
            if #pr < 2 then core.chat_send_player(n, 'Usage: /wp_move <name> <x,y,z>'); return end
            local wn, pos_str = pr[1], pr[2]
            local pl = core.get_player_by_name(n)
            if not pl then return end
            local pos_vals = pos_str:split(',')
            if #pos_vals < 3 then core.chat_send_player(n, 'Invalid coordinates format. Please use <x,y,z>.'); return end
            local px, py, pz = tonumber(pos_vals[1]), tonumber(pos_vals[2]), tonumber(pos_vals[3])
            if not px or not py or not pz then core.chat_send_player(n, 'Invalid coordinates format. Please use numbers for <x,y,z>.'); return end
            local po = vector.round(vector.new(px, py, pz))
            if not way[n] or not way[n][wn] then core.chat_send_player(n, ('Waypoint "%s" not found.'):format(wn)); return end
            way[n][wn].position = po
            core.chat_send_player(n, ('Moved waypoint "%s" to new coordinates "%i %i %i"'):format(wn, po.x, po.y, po.z))
            hud.hid_s(n)
            hud.hid(n)
            sav(n, way[n])
            hud.sho(n, way, guilds)
        end),
    })

    core.register_chatcommand('wp_cc', {
        params = '<name> <color>',
        description = 'Change color of an existing waypoint (format: RRGGBB)',
        func = saf(function(n, p)
            local pr = p:split(' ')
            if #pr < 2 then core.chat_send_player(n, 'Usage: /wp_cc <name> <color>'); return end
            local wn, wc = pr[1], tonumber(pr[2], 16)
            if not way[n] or not way[n][wn] then core.chat_send_player(n, ('Waypoint "%s" not found.'):format(wn)); return end
            way[n][wn].color = wc
            core.chat_send_player(n, ('Changed color of waypoint "%s" to #%06X'):format(wn, wc))
            hud.hid_s(n)
            hud.hid(n)
            sav(n, way[n])
            hud.sho(n, way, guilds)
        end),
    })

    core.register_chatcommand('wp_dis', {
        params = '<name>',
        description = 'Show distance to a waypoint',
        func = saf(function(n, p)
            local pr = p:split(' ')
            if #pr < 1 then core.chat_send_player(n, 'Usage: /wp_dis <name>'); return end
            local wn = pr[1]
            local pl = core.get_player_by_name(n)
            if not pl then return end
            if not way[n] or not way[n][wn] then core.chat_send_player(n, ('Waypoint "%s" not found.'):format(wn)); return end
            local player_pos = vector.round(pl:get_pos())
            local wp_pos = way[n][wn].position
            local distance = vector.distance(player_pos, wp_pos)
            core.chat_send_player(n, ('Distance to waypoint "%s": %.2f meters'):format(wn, distance))
        end),
    })

    core.register_chatcommand('wp_delete_all', {
        params = '',
        description = 'Delete all waypoints of the user',
        func = saf(function(n, _)
            if not way[n] then core.chat_send_player(n, 'You have no waypoints to delete.'); return end
            way[n] = {}
            core.chat_send_player(n, 'All waypoints deleted.')
            sav(n, way[n])
            hud.hid(n)
        end),
    })

    core.register_chatcommand('wp_info', {
        params = '<name>',
        description = 'Show detailed information about a waypoint',
        func = saf(function(player_name, param)
            local wp_name = param:trim()
            if wp_name == '' then core.chat_send_player(player_name, 'Usage: /wp_info <name>'); return end
            local player_waypoints = way[player_name] or {}
            local wp_data = player_waypoints[wp_name]
            if not wp_data then core.chat_send_player(player_name, ('Waypoint "%s" not found.'):format(wp_name)); return end
            local wp_pos = wp_data.position
            local wp_color = wp_data.color or 0xFFFFFF
            local pl = core.get_player_by_name(player_name)
            if not pl then return end
            local player_pos = vector.round(pl:get_pos())
            local distance = vector.distance(wp_pos, player_pos)
            local info_message = ('Waypoint "%s" Information:\n'):format(wp_name)
            info_message = info_message .. ('Position: %i, %i, %i\n'):format(wp_pos.x, wp_pos.y, wp_pos.z)
            info_message = info_message .. ('Color: %s\n'):format(core.colorize('#' .. string.format('%06X', wp_color), '#' .. string.format('%06X', wp_color)))
            info_message = info_message .. ('Distance: %.2f meters\n'):format(distance)
            core.chat_send_player(player_name, info_message)
        end),
    })

    core.register_chatcommand('wp_rename', {
        params = '<old_name> <new_name>',
        description = 'Rename a waypoint',
        func = saf(function(n, p)
            local pr = p:split(' ')
            if #pr < 2 then core.chat_send_player(n, 'Usage: /wp_rename <old_name> <new_name>'); return end
            local old_name, new_name = pr[1], pr[2]
            local player_waypoints = way[n] or {}
            local wp_data = player_waypoints[old_name]
            if not wp_data then core.chat_send_player(n, ('Waypoint "%s" not found.'):format(old_name)); return end
            if player_waypoints[new_name] then core.chat_send_player(n, 'The new name is already in use. Please choose a different name.'); return end
            player_waypoints[new_name] = wp_data
            player_waypoints[old_name] = nil
            core.chat_send_player(n, ('Waypoint "%s" renamed to "%s".'):format(old_name, new_name))
            hud.hid_s(n)
            hud.hid(n)
            sav(n, way[n])
            hud.sho(n, way, guilds)
        end),
    })

    core.register_chatcommand('wp_toggle_hud', {
        params = '<name>',
        description = 'Toggle HUD for a specific waypoint',
        func = saf(function(n, p)
            local wn = p:trim()
            if wn == '' then core.chat_send_player(n, 'Usage: /wp_toggle_hud <name>'); return end
            local pl = core.get_player_by_name(n)
            if not pl then return end
            local d = way[n] and way[n][wn]
            if not d then core.chat_send_player(n, ('Waypoint "%s" not found.'):format(wn)); return end
            local h_ids_str = pl:get_meta():get_string('h_s')
            local h_ids = h_ids_str == '' and {} or core.deserialize(h_ids_str)
            local found = false
            for _, h_id in ipairs(h_ids) do
                local hudt = pl:hud_get(h_id)
                if hudt and hudt.name == wn then
                    pl:hud_remove(h_id)
                    found = true
                    break
                end
            end
            if not found then
                local c = d.color or 0xFFFFFF
                local h = pl:hud_add({ hud_elem_type = 'waypoint', name = wn, number = c, world_pos = d.position, text = string.format("m | (%d, %d, %d)", d.position.x, d.position.y, d.position.z) })
                table.insert(h_ids, h)
                core.chat_send_player(n, ('Waypoint "%s" HUD toggled.'):format(wn))
            else
                core.chat_send_player(n, ('Waypoint "%s" HUD hidden.'):format(wn))
            end
            pl:get_meta():set_string('h_s', core.serialize(h_ids))
        end),
    })

    core.register_privilege('waypoints_tp', { description = 'Allows teleportation to waypoints', give_to_singleplayer = false })

    core.register_chatcommand('wp_tp', {
        params = '<name> [optional_playername]',
        description = 'Teleport to a waypoint or teleport another player to a waypoint',
        privs = { waypoints_tp = true },
        func = saf(function(sender_name, param)
            local pr = param:split(' ')
            if #pr < 1 then core.chat_send_player(sender_name, 'Usage: /wp_tp <name> [optional_playername]'); return end
            local wp_name = pr[1]
            local target_player_name = pr[2] or sender_name
            local player_waypoints = way[sender_name] or {}
            local wp_data = player_waypoints[wp_name]
            if not wp_data then core.chat_send_player(sender_name, ('Waypoint "%s" not found.'):format(wp_name)); return end
            local target_player = core.get_player_by_name(target_player_name)
            if not target_player then core.chat_send_player(sender_name, ('Player "%s" not found.'):format(target_player_name)); return end
            target_player:set_pos(wp_data.position)
            core.chat_send_player(sender_name, ('Teleported "%s" to waypoint "%s".'):format(target_player_name, wp_name))
        end),
    })
end
