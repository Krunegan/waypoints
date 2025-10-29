local hud = {}

local function get_player_meta(player_name)
    local pl = core.get_player_by_name(player_name)
    if not pl then return nil end
    return pl:get_meta()
end

function hud.hid_s(n)
    local p = core.get_player_by_name(n)
    if not p then return end
    local m = p:get_meta()
    local h = m:get_string('h_s')
    if h == '' then return end
    local hu = core.deserialize(h)
    for _, hi in ipairs(hu) do p:hud_remove(hi) end
    m:set_string('h_s', '')
end

function hud.hid(n)
    local p = core.get_player_by_name(n)
    if not p then return end
    local m = p:get_meta()
    local h = m:get_string('h')
    if h == '' then return end
    local hu = core.deserialize(h)
    for _, hi in ipairs(hu) do p:hud_remove(hi) end
    m:set_string('h', '')
end

function hud.get_player_hidden(player_name)
    local pl = core.get_player_by_name(player_name)
    local meta = nil
    if pl then meta = pl:get_meta() end
    if meta then
        local s = meta:get_string('guild_hidden')
        if s == '' then return {} end
        return core.deserialize(s) or {}
    end
    return {}
end

function hud.set_player_hidden(player_name, t)
    local pl = core.get_player_by_name(player_name)
    if not pl then return end
    local meta = pl:get_meta()
    meta:set_string('guild_hidden', core.serialize(t or {}))
end

function hud.get_player_hud_ids(player_name)
    local pl = core.get_player_by_name(player_name)
    if not pl then return {} end
    local meta = pl:get_meta()
    local s = meta:get_string('h')
    if s == '' then return {} end
    return core.deserialize(s) or {}
end

function hud.set_player_hud_ids(player_name, ids)
    local pl = core.get_player_by_name(player_name)
    if not pl then return end
    pl:get_meta():set_string('h', core.serialize(ids or {}))
end

function hud.find_hud_by_name(player_name, display_name)
    local pl = core.get_player_by_name(player_name)
    if not pl then return nil, nil end
    local ids = hud.get_player_hud_ids(player_name)
    for i, hid in ipairs(ids) do
        local h = pl:hud_get(hid)
        if h and h.name == display_name then return i, hid end
    end
    return nil, nil
end

function hud.add_guild_waypoint_hud_for_player(player_name, guild_name, wp_name, wp_data)
    if not player_name or not guild_name or not wp_name or not wp_data then return end
    local hidden = hud.get_player_hidden(player_name)
    local key = guild_name .. '/' .. wp_name
    if hidden[key] then return end
    local pl = core.get_player_by_name(player_name)
    if not pl then return end
    local display_name = guild_name .. '/' .. wp_name
    local idx, hid = hud.find_hud_by_name(player_name, display_name)
    if hid then
        pl:hud_remove(hid)
        local ids = hud.get_player_hud_ids(player_name)
        table.remove(ids, idx)
        hud.set_player_hud_ids(player_name, ids)
    end
    local h = pl:hud_add({
        hud_elem_type = 'waypoint',
        name = display_name,
        number = wp_data.color or 0xFFFFFF,
        world_pos = wp_data.position,
        text = string.format("m | (%d, %d, %d)", wp_data.position.x, wp_data.position.y, wp_data.position.z)
    })
    local ids = hud.get_player_hud_ids(player_name)
    table.insert(ids, h)
    hud.set_player_hud_ids(player_name, ids)
end

function hud.remove_guild_waypoint_hud_for_player(player_name, guild_name, wp_name)
    local display_name = guild_name .. '/' .. wp_name
    local idx, hid = hud.find_hud_by_name(player_name, display_name)
    if hid then
        local pl = core.get_player_by_name(player_name)
        if pl then pl:hud_remove(hid) end
        local ids = hud.get_player_hud_ids(player_name)
        if idx then table.remove(ids, idx) end
        hud.set_player_hud_ids(player_name, ids)
    end
end

function hud.update_guild_waypoint_hud_for_player(player_name, guild_name, wp_name, wp_data)
    hud.remove_guild_waypoint_hud_for_player(player_name, guild_name, wp_name)
    hud.add_guild_waypoint_hud_for_player(player_name, guild_name, wp_name, wp_data)
end

function hud.show_all_guild_waypoints_to_player(player_name, guilds_table, guild_name)
    if not guilds_table or type(guilds_table) ~= 'table' then return end
    local g = guilds_table[guild_name]
    if not g then return end
    for wp_name, wp_data in pairs(g.waypoints or {}) do
        hud.add_guild_waypoint_hud_for_player(player_name, guild_name, wp_name, wp_data)
    end
end

function hud.sho(n, way_table, guilds_table)
    local p = core.get_player_by_name(n)
    if not p then return end
    local m = p:get_meta()
    local hu = {}

    for w, d in pairs(way_table[n] or {}) do
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

    for guild_name, g in pairs(guilds_table or {}) do
        if g.members and g.members[n] then
            for wp_name, d in pairs(g.waypoints or {}) do
                local c = d.color or 0xFFFFFF
                local display_name = guild_name .. '/' .. wp_name
                local h = p:hud_add({
                    hud_elem_type = 'waypoint',
                    name = display_name,
                    number = c,
                    world_pos = d.position,
                    text = string.format("m | (%d, %d, %d)", d.position.x, d.position.y, d.position.z)
                })
                table.insert(hu, h)
            end
        end
    end

    m:set_string('h', core.serialize(hu))
end

return hud