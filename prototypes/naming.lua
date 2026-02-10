-- prototypes/naming.lua
local M = {}

function M.q_item_name(item_name, q)
    return item_name .. "-" .. q
end

function M.q_tile_name(item_name, q)
    local base = item_name
    if item_name == "hazard-concrete" or item_name == "refined-hazard-concrete" then
        base = base .. "-left"
    end
    return base .. "-quality-" .. q
end

function M.localised_name_with_quality(item_name, q)
    return { "", string.upper(string.sub(q, 1, 1)) .. string.sub(q, 2), " ", { "item-name." .. item_name } }
end

return M