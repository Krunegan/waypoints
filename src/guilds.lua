return function(storage, hud)
    local gmod = {}
    local guilds = storage.lod_guilds()
    local pending_requests = {}

    function gmod.get_all()
        return guilds
    end

    function gmod.save_all()
        storage.sav_guilds(guilds)
    end

    function gmod.is_guild_member(player_name, guild_name)
        local g = guilds[guild_name]
        if not g or not g.members then return false end
        return g.members[player_name] == true
    end

    function gmod.list_pending_for(player_name)
        return pending_requests[player_name] or {}
    end

    function gmod.create_guild_request(leader, guild_name, target, timeout_seconds)
        timeout_seconds = timeout_seconds or 60
        pending_requests[target] = pending_requests[target] or {}
        local key = 'guild:' .. guild_name
        if pending_requests[target][key] then return false end
        pending_requests[target][key] = { leader = leader, guild = guild_name }
        core.chat_send_player(target, ('%s invited you to the guild "%s". Use /guild_accept %s to accept or /guild_decline %s to decline. Invitation expires in %d seconds.'):format(leader, guild_name, guild_name, guild_name, timeout_seconds))
        core.chat_send_player(leader, ('Invitation sent to %s to join guild "%s".'):format(target, guild_name))

        core.after(timeout_seconds, function()
            if pending_requests[target] and pending_requests[target][key] then
                pending_requests[target][key] = nil
                core.chat_send_player(target, ('Invitation to join guild "%s" expired.'):format(guild_name))
                core.chat_send_player(leader, ('Invitation for %s to join guild "%s" expired.'):format(target, guild_name))
            end
        end)
        return true
    end

    function gmod.accept_guild_request(target, guild_name)
        pending_requests[target] = pending_requests[target] or {}
        local key = 'guild:' .. guild_name
        if not pending_requests[target][key] then
            return false, 'No pending invitation found.'
        end
        local info = pending_requests[target][key]
        local leader = info.leader
        if not guilds[guild_name] then
            pending_requests[target][key] = nil
            return false, 'Guild not found.'
        end
        guilds[guild_name].members = guilds[guild_name].members or {}
        guilds[guild_name].members[target] = true
        pending_requests[target][key] = nil
        storage.sav_guilds(guilds)
        core.chat_send_player(target, ('You joined guild "%s".'):format(guild_name))
        core.chat_send_player(leader, ('%s joined your guild "%s".'):format(target, guild_name))
        for wp_name, wp_data in pairs(guilds[guild_name].waypoints or {}) do
            hud.add_guild_waypoint_hud_for_player(target, guild_name, wp_name, wp_data)
        end
        return true
    end

    function gmod.decline_guild_request(target, guild_name)
        pending_requests[target] = pending_requests[target] or {}
        local key = 'guild:' .. guild_name
        if not pending_requests[target][key] then return false, 'No pending invitation found.' end
        local leader = pending_requests[target][key].leader
        pending_requests[target][key] = nil
        core.chat_send_player(target, ('You declined invitation to guild "%s".'):format(guild_name))
        core.chat_send_player(leader, ('%s declined invitation to join guild "%s".'):format(target, guild_name))
        return true
    end

    function gmod.create_guild(leader, guild_name, members)
        if guilds[guild_name] then return false, 'Guild exists' end
        guilds[guild_name] = { leader = leader, members = { [leader] = true }, waypoints = {} }
        storage.sav_guilds(guilds)
        if members and members ~= '' then
            for _, nm in ipairs(members:split(',')) do
                local t = nm:trim()
                if t ~= '' and t ~= leader then gmod.create_guild_request(leader, guild_name, t, 60) end
            end
        end
        return true
    end

    gmod._guilds = guilds
    gmod._pending = pending_requests

    return gmod
end
