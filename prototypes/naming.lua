-- prototypes/naming.lua
---@class Naming
local M = {}

---@param item_name ItemName
---@param q QualityName
---@return ItemName
function M.q_item_name(item_name, q)
    return item_name .. "-" .. q
end

---@param item_name ItemName
---@param q QualityName
---@return ItemName
function M.q_recycling_placeholder_name(item_name, q)
    return "recycled-" .. item_name .. "-" .. q
end

---@param item_name ItemName
---@param q QualityName
---@return ItemName
function M.q_tile_name(item_name, q)
    local base = item_name
    if item_name == "hazard-concrete" or item_name == "refined-hazard-concrete" then
        base = base .. "-left"
    end
    return base .. "-quality-" .. q
end

---@param item_name ItemName
---@param q QualityName
---@return LocalisedString
function M.localised_name_with_quality(ctx, item_name, q)
    -- vanilla: do NOT show "(Normal)"
    if q == "normal" then
        return { "", { "item-name." .. item_name } }
    end

    local qname = string.upper(string.sub(q, 1, 1)) .. string.sub(q, 2)

    local tint = ctx.base_tint[q] or {255,255,255}
    local r = tint[1] or 255
    local g = tint[2] or 255
    local b = tint[3] or 255

    return {
        "",
        "[color=" .. r .. "," .. g .. "," .. b .. "]",
        { "item-name." .. item_name },
        " (", qname, ")",
        "[/color]"
    }
end

return M