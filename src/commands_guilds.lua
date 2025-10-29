return function(storage, utils, hud, guilds_mod, way)
    local saf = utils.saf
    local guilds = guilds_mod._guilds
    local save_guilds = guilds_mod.save_all

    core.register_chatcommand('guild_wp_set', {
        params = '<guild_name> <wp_name> <x,y,z|here> [color]',
        description = 'Create or move a guild waypoint. Color optional (RRGGBB).',
        func = saf(function(sender, p)
            local pr = p:split(' ')
            if #pr < 3 then
                core.chat_send_player(sender, 'Usage: /guild_wp_set <guild_name> <wp_name> <x,y,z|here> [color]')
                return
            end
            local guild_name, wn, pos_str = pr[1], pr[2], pr[3]
            local color_str = pr[4] or ''
            local wc = tonumber(color_str, 16)
            if color_str ~= '' and not wc then core.chat_send_player(sender, 'Invalid color format. Use RRGGBB.'); return end

            local g = guilds[guild_name]
            if not g then core.chat_send_player(sender, ('Guild "%s" not found.'):format(guild_name)); return end
            if g.leader ~= sender then core.chat_send_player(sender, 'Only the guild leader can create/move waypoints.'); return end
            if g.waypoints and g.waypoints[wn] then
                core.chat_send_player(sender, ('Guild waypoint "%s/%s" already exists. Use /guild_wp_move to move it or /guild_wp_unset to remove it.'):format(guild_name, wn))
                return
            end

            local px, py, pz
            if type(pos_str) == 'string' and pos_str:lower() == 'here' then
                local pl = core.get_player_by_name(sender)
                if not pl then core.chat_send_player(sender, 'Player not online to resolve "here".'); return end
                local po = vector.round(pl:get_pos())
                px, py, pz = po.x, po.y, po.z
            else
                local pos_vals = pos_str:split(',')
                if #pos_vals < 3 then core.chat_send_player(sender, 'Invalid coordinates format. Use <x,y,z> or "here".'); return end
                px,py,pz = tonumber(pos_vals[1]), tonumber(pos_vals[2]), tonumber(pos_vals[3])
                if not px or not py or not pz then core.chat_send_player(sender, 'Invalid coordinates format. Use numbers for <x,y,z>.'); return end
            end

            g.waypoints = g.waypoints or {}
            g.waypoints[wn] = g.waypoints[wn] or {}
            g.waypoints[wn].position = vector.round(vector.new(px,py,pz))
            if wc then g.waypoints[wn].color = wc end
            save_guilds()
            core.chat_send_player(sender, ('Guild waypoint "%s/%s" set to %i %i %i'):format(guild_name, wn, px,py,pz))

            for member,_ in pairs(g.members or {}) do
                hud.add_guild_waypoint_hud_for_player(member, guild_name, wn, g.waypoints[wn])
            end
        end),
    })

    core.register_chatcommand('guild_create', {
        params = '<guild_name> [member1,member2,...]',
        description = 'Create a guild (you are leader) and optionally invite members (invitations expire).',
        func = saf(function(leader, p)
            local pr = p:split(' ')
            if #pr < 1 then core.chat_send_player(leader, 'Usage: /guild_create <guild_name> [member1,member2,...]'); return end
            local guild_name = pr[1]
            local members_str = pr[2] or ''
            if guilds[guild_name] then core.chat_send_player(leader, 'Guild name already exists. Choose a different name.'); return end
            if guilds_mod.create_guild then
                local ok, err = guilds_mod.create_guild(leader, guild_name, members_str)
                if not ok then core.chat_send_player(leader, err or 'Failed to create guild.'); return end
                core.chat_send_player(leader, ('Guild "%s" created. You are the leader.'):format(guild_name))
            else
                guilds[guild_name] = { leader = leader, members = { [leader] = true }, waypoints = {} }
                save_guilds()
                core.chat_send_player(leader, ('Guild "%s" created. You are the leader.'):format(guild_name))
                if members_str and members_str:trim() ~= '' then
                    for _, nm in ipairs(members_str:split(',')) do
                        local t = nm:trim()
                        if t ~= '' and t ~= leader then guilds_mod.create_guild_request(leader, guild_name, t, 60) end
                    end
                end
            end
        end),
    })

    core.register_chatcommand('guild_requests', {
        params = '',
        description = 'List your pending guild invitations.',
        func = saf(function(player, _)
            local prs = guilds_mod.list_pending_for(player) or {}
            local m = 'Pending guild invitations:\n'
            for key, v in pairs(prs) do m = m .. v.leader .. ' invites to guild: ' .. v.guild .. '\n' end
            if next(prs) == nil then m = 'No pending invitations.' end
            core.chat_send_player(player, m)
        end),
    })

    core.register_chatcommand('guild_leave', {
        params = '<guild_name>',
        description = 'Leave a guild you are member of.',
        func = saf(function(player, p)
            local guild_name = p:trim()
            if guild_name == '' then core.chat_send_player(player, 'Usage: /guild_leave <guild_name>'); return end
            local g = guilds[guild_name]
            if not g or not g.members or not g.members[player] then core.chat_send_player(player, ('You are not a member of guild "%s".'):format(guild_name)); return end
            if g.leader == player then core.chat_send_player(player, 'Leader cannot leave the guild. Transfer leadership or delete the guild.'); return end
            g.members[player] = nil
            save_guilds()
            core.chat_send_player(player, ('You left guild "%s".'):format(guild_name))
        end),
    })

    core.register_chatcommand('guild_wp_cc', {
        params = '<guild_name> <wp_name> <color>',
        description = 'Change color of a guild waypoint (RRGGBB).',
        func = saf(function(sender, p)
            local pr = p:split(' ')
            if #pr < 3 then core.chat_send_player(sender, 'Usage: /guild_wp_cc <guild_name> <wp_name> <color>'); return end
            local guild_name, wn, color_str = pr[1], pr[2], pr[3]
            local wc = tonumber(color_str, 16)
            if not wc then core.chat_send_player(sender, 'Invalid color format.'); return end
            local g = guilds[guild_name]
            if not g then core.chat_send_player(sender, ('Guild "%s" not found.'):format(guild_name)); return end
            if g.leader ~= sender then core.chat_send_player(sender, 'Only the guild leader can change waypoint colors.'); return end
            if not g.waypoints or not g.waypoints[wn] then core.chat_send_player(sender, ('Waypoint "%s" not found in guild "%s".'):format(wn, guild_name)); return end
            g.waypoints[wn].color = wc
            save_guilds()
            core.chat_send_player(sender, ('Changed color of "%s/%s" to #%06X'):format(guild_name, wn, wc))
            for member,_ in pairs(g.members or {}) do
                hud.update_guild_waypoint_hud_for_player(member, guild_name, wn, g.waypoints[wn])
            end
        end),
    })

    core.register_chatcommand('guild_wp_unset', {
        params = '<guild_name> <wp_name>',
        description = 'Remove a guild waypoint.',
        func = saf(function(sender, p)
            local pr = p:split(' ')
            if #pr < 2 then core.chat_send_player(sender, 'Usage: /guild_wp_unset <guild_name> <wp_name>'); return end
            local guild_name = pr[1]
            local wpname = pr[2]
            local g = guilds[guild_name]
            if not g then core.chat_send_player(sender, ('Guild "%s" not found.'):format(guild_name)); return end
            if g.leader ~= sender then core.chat_send_player(sender, 'Only the guild leader can remove waypoints.'); return end
            if not g.waypoints or not g.waypoints[wpname] then core.chat_send_player(sender, ('Waypoint "%s" not found.'):format(wpname)); return end
            for member,_ in pairs(g.members or {}) do
                hud.remove_guild_waypoint_hud_for_player(member, guild_name, wpname)
            end
            g.waypoints[wpname] = nil
            save_guilds()
            core.chat_send_player(sender, ('Removed guild waypoint "%s/%s".'):format(guild_name, wpname))
        end),
    })

    core.register_chatcommand('guild_invite', {
        params = '<guild_name> <player>',
        description = 'Invite a player to your guild (creates an invitation).',
        func = saf(function(sender, p)
            local pr = p:split(' ')
            if #pr < 2 then core.chat_send_player(sender, 'Usage: /guild_invite <guild_name> <player>'); return end
            local guild_name, new_member = pr[1], pr[2]
            local g = guilds[guild_name]
            if not g then core.chat_send_player(sender, ('Guild "%s" not found.'):format(guild_name)); return end
            if g.leader ~= sender then core.chat_send_player(sender, 'Only the guild leader may invite members.'); return end
            if g.members and g.members[new_member] then core.chat_send_player(sender, (('%s is already a member of "%s".'):format(new_member, guild_name))); return end
            local ok = guilds_mod.create_guild_request(sender, guild_name, new_member, 60)
            if ok then core.chat_send_player(sender, ('Invitation sent to %s for guild "%s".'):format(new_member, guild_name)) else core.chat_send_player(sender, ('An invitation is already pending for %s to join "%s".'):format(new_member, guild_name)) end
        end),
    })

    core.register_chatcommand('guild_decline', {
        params = '<guild_name>',
        description = 'Decline an invitation to a guild.',
        func = saf(function(player, p)
            local guild_name = p:trim()
            if guild_name == '' then core.chat_send_player(player, 'Usage: /guild_decline <guild_name>'); return end
            local ok, err = guilds_mod.decline_guild_request(player, guild_name)
            if not ok then core.chat_send_player(player, err); return end
            core.chat_send_player(player, ('You declined invitation to guild "%s".'):format(guild_name))
        end),
    })

    core.register_chatcommand('guild_list', {
        params = '[guild_name]',
        description = 'List guilds visible to you or details of a specific guild (if you are member or leader).',
        func = saf(function(player, p)
            local guild_name = p:trim()
            local m = ''
            if guild_name ~= '' then
                local g = guilds[guild_name]
                if not g then core.chat_send_player(player, ('Guild "%s" not found.'):format(guild_name)); return end
                m = ('Guild "%s" (leader: %s)\nMembers:\n'):format(guild_name, g.leader or '?')
                for mem,_ in pairs(g.members or {}) do m = m .. '- ' .. mem .. '\n' end
                m = m .. 'Waypoints:\n'
                for wn, d in pairs(g.waypoints or {}) do
                    local po = d.position or vector.new(0,0,0)
                    local color_str = string.format('%06X', d.color or 0xFFFFFF)
                    m = m .. string.format('%s | Color: #%s | Position: %i, %i, %i\n', wn, color_str, po.x, po.y, po.z)
                end
            else
                m = 'Guilds visible to you:\n'
                for name, g in pairs(guilds) do if g.members and g.members[player] then m = m .. name .. ' (leader: ' .. (g.leader or '?') .. ')\n' end end
                if m == 'Guilds visible to you:\n' then m = 'No guilds.' end
            end
            core.chat_send_player(player, m)
        end),
    })

    core.register_chatcommand('guild_transfer', {
        params = '<guild_name> <new_leader>',
        description = 'Transfer leadership of a guild to another member.',
        func = saf(function(sender, p)
            local pr = p:split(' ')
            if #pr < 2 then core.chat_send_player(sender, 'Usage: /guild_transfer <guild_name> <new_leader>'); return end
            local guild_name, new_leader = pr[1], pr[2]
            local g = guilds[guild_name]
            if not g then core.chat_send_player(sender, ('Guild "%s" not found.'):format(guild_name)); return end
            if g.leader ~= sender then core.chat_send_player(sender, 'Only the current guild leader can transfer leadership.'); return end
            if not g.members or not g.members[new_leader] then core.chat_send_player(sender, (('%s is not a member of "%s".'):format(new_leader, guild_name))); return end
            g.leader = new_leader
            save_guilds()
            core.chat_send_player(sender, ('You transferred leadership of "%s" to %s.'):format(guild_name, new_leader))
            core.chat_send_player(new_leader, ('You are now the leader of guild "%s" (transferred by %s).'):format(guild_name, sender))
        end),
    })

    core.register_chatcommand('guild_delete', {
        params = '<guild_name>',
        description = 'Delete the entire guild.',
        func = saf(function(sender, p)
            local guild_name = p:trim()
            if guild_name == '' then core.chat_send_player(sender, 'Usage: /guild_delete <guild_name>'); return end
            local g = guilds[guild_name]
            if not g then core.chat_send_player(sender, ('Guild "%s" not found.'):format(guild_name)); return end
            if g.leader ~= sender then core.chat_send_player(sender, 'Only the guild leader can delete the guild.'); return end
            for member,_ in pairs(g.members or {}) do
                local ids = hud.get_player_hud_ids(member)
                local pl = core.get_player_by_name(member)
                if pl then
                    local new_ids = {}
                    for _, hid in ipairs(ids) do
                        local hudt = pl:hud_get(hid)
                        if hudt and type(hudt.name) == 'string' and hudt.name:sub(1, #guild_name+1) == guild_name .. '/' then
                            pl:hud_remove(hid)
                        else
                            table.insert(new_ids, hid)
                        end
                    end
                    hud.set_player_hud_ids(member, new_ids)
                    local hidden = hud.get_player_hidden(member)
                    for k,_ in pairs(hidden) do
                        if k:sub(1, #guild_name+1) == guild_name .. '/' then hidden[k] = nil end
                    end
                    hud.set_player_hidden(member, hidden)
                end
            end
            guilds[guild_name] = nil
            save_guilds()
            core.chat_send_player(sender, ('Deleted guild "%s".'):format(guild_name))
        end),
    })

    core.register_chatcommand('guild_remove_member', {
        params = '<guild_name> <player>',
        description = 'Remove a member from the guild.',
        func = saf(function(sender, p)
            local pr = p:split(' ')
            if #pr < 2 then core.chat_send_player(sender, 'Usage: /guild_remove_member <guild_name> <player>'); return end
            local guild_name, member = pr[1], pr[2]
            local g = guilds[guild_name]
            if not g then core.chat_send_player(sender, ('Guild "%s" not found.'):format(guild_name)); return end
            if g.leader ~= sender then core.chat_send_player(sender, 'Only the guild leader may remove members.'); return end
            if g.members and g.members[member] then
                for wp_name,_ in pairs(g.waypoints or {}) do
                    hud.remove_guild_waypoint_hud_for_player(member, guild_name, wp_name)
                end
                g.members[member] = nil
                save_guilds()
                core.chat_send_player(sender, ('Removed %s from guild "%s".'):format(member, guild_name))
                core.chat_send_player(member, ('You were removed from guild "%s" by %s.'):format(guild_name, sender))
            else
                core.chat_send_player(sender, (('%s is not a member of "%s".'):format(member, guild_name)))
            end
        end),
    })

    core.register_chatcommand('guild_wp_toggle', {
        params = '<guild_name> <wp_name|all>',
        description = 'Toggle visibility of a guild waypoint for you. Use "all" to toggle all waypoints in the guild.',
        func = saf(function(player, p)
            local pr = p:split(' ')
            if #pr < 2 then core.chat_send_player(player, 'Usage: /guild_wp_toggle <guild_name> <wp_name|all>'); return end
            local guild_name, wp_name = pr[1], pr[2]
            local g = guilds[guild_name]
            if not g or not g.waypoints then core.chat_send_player(player, ('Guild "%s" not found or has no waypoints.'):format(guild_name)); return end
            if not guilds_mod.is_guild_member(player, guild_name) then core.chat_send_player(player, 'You are not a member of this guild.'); return end

            local hidden = hud.get_player_hidden(player)

            if wp_name == 'all' or wp_name == '*' then
                local any_visible = false
                for name, _ in pairs(g.waypoints) do
                    local key = guild_name .. '/' .. name
                    if not hidden[key] then any_visible = true; break end
                end
                if any_visible then
                    for name, _ in pairs(g.waypoints) do
                        local key = guild_name .. '/' .. name
                        hidden[key] = true
                        hud.remove_guild_waypoint_hud_for_player(player, guild_name, name)
                    end
                    hud.set_player_hidden(player, hidden)
                    core.chat_send_player(player, ('All waypoints of guild "%s" hidden for you.'):format(guild_name))
                else
                    for name, _ in pairs(g.waypoints) do hidden[guild_name .. '/' .. name] = nil end
                    hud.set_player_hidden(player, hidden)
                    for name, wp_data in pairs(g.waypoints) do hud.add_guild_waypoint_hud_for_player(player, guild_name, name, wp_data) end
                    core.chat_send_player(player, ('All waypoints of guild "%s" shown for you.'):format(guild_name))
                end
                return
            end

            if not g.waypoints[wp_name] then core.chat_send_player(player, ('Guild waypoint "%s/%s" not found.'):format(guild_name, wp_name)); return end
            local key = guild_name .. '/' .. wp_name
            if hidden[key] then
                hidden[key] = nil
                hud.set_player_hidden(player, hidden)
                hud.add_guild_waypoint_hud_for_player(player, guild_name, wp_name, g.waypoints[wp_name])
                core.chat_send_player(player, ('Guild waypoint "%s/%s" shown for you.'):format(guild_name, wp_name))
            else
                hidden[key] = true
                hud.set_player_hidden(player, hidden)
                hud.remove_guild_waypoint_hud_for_player(player, guild_name, wp_name)
                core.chat_send_player(player, ('Guild waypoint "%s/%s" hidden for you.'):format(guild_name, wp_name))
            end
        end),
    })

    local function accept_guild_request_and_show(target, guild_name)
        local ok, err = guilds_mod.accept_guild_request(target, guild_name)
        if not ok then return false, err end
        hud.show_all_guild_waypoints_to_player(target, guilds, guild_name)
        return true
    end

    core.register_chatcommand('guild_accept', {
        params = '<guild_name>',
        description = 'Accept an invitation to a guild.',
        func = saf(function(player, p)
            local guild_name = p:trim()
            if guild_name == '' then core.chat_send_player(player, 'Usage: /guild_accept <guild_name>'); return end
            local ok, err = accept_guild_request_and_show(player, guild_name)
            if not ok then core.chat_send_player(player, err); return end
            hud.hid_s(player); hud.hid(player); hud.sho(player, way, guilds)
        end),
    })

    core.register_chatcommand('guild_wp_move', {
        params = '<guild_name> <wp_name> <x,y,z>',
        description = 'Move an existing guild waypoint to new coordinates.',
        func = saf(function(sender, p)
            local pr = p:split(' ')
            if #pr < 3 then core.chat_send_player(sender, 'Usage: /guild_wp_move <guild_name> <wp_name> <x,y,z>'); return end
            local guild_name, wn, pos_str = pr[1], pr[2], pr[3]
            local g = guilds[guild_name]
            if not g then core.chat_send_player(sender, ('Guild "%s" not found.'):format(guild_name)); return end
            if g.leader ~= sender then core.chat_send_player(sender, 'Only the guild leader can move waypoints.'); return end
            if not g.waypoints or not g.waypoints[wn] then core.chat_send_player(sender, ('Waypoint "%s" not found in guild "%s".'):format(wn, guild_name)); return end
            local pos_vals = pos_str:split(',')
            if #pos_vals < 3 then core.chat_send_player(sender, 'Invalid coordinates format. Use <x,y,z>.'); return end
            local px, py, pz = tonumber(pos_vals[1]), tonumber(pos_vals[2]), tonumber(pos_vals[3])
            if not px or not py or not pz then core.chat_send_player(sender, 'Invalid coordinates. Use numbers for <x,y,z>.'); return end
            local new_pos = vector.round(vector.new(px, py, pz))
            g.waypoints[wn].position = new_pos
            save_guilds()
            core.chat_send_player(sender, ('Moved guild waypoint "%s/%s" to %i, %i, %i.'):format(guild_name, wn, new_pos.x, new_pos.y, new_pos.z))
            for member,_ in pairs(g.members or {}) do
                hud.update_guild_waypoint_hud_for_player(member, guild_name, wn, g.waypoints[wn])
            end
        end),
    })
end
