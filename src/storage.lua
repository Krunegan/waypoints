local storage = {}

local sto = core.get_mod_storage()

function storage.lod(n)
    local d = sto:get_string(n)
    if d ~= '' then
        return core.deserialize(d)
    else
        return {}
    end
end

function storage.sav(n, d)
    sto:set_string(n, core.serialize(d))
end

function storage.lod_guilds()
    local d = sto:get_string('guilds')
    if d ~= '' then
        return core.deserialize(d)
    else
        return {}
    end
end

function storage.sav_guilds(d)
    sto:set_string('guilds', core.serialize(d))
end

return storage