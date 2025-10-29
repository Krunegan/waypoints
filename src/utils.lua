local utils = {}

function utils.saf(f)
    return function(...)
        local s, o = pcall(f, ...)
        if s then
            return o
        else
            core.log('warning', 'Error: ' .. tostring(o))
            return nil
        end
    end
end

return utils