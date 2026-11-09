-- prototypes/naming.lua
-- Only localised_name_with_quality reads data.raw, so control.lua and migrations can require this too.
---@class Naming
local M = {}

---@param item_name ItemName
---@param q QualityName
---@return ItemName
function M.q_item_name(item_name, q)
    return item_name .. "-" .. q
end

---@param base_tile string
---@param q QualityName
---@return string
function M.q_tile_name(base_tile, q)
    return base_tile .. "-quality-" .. q
end

-- "Concrete (Rare)" in the quality's color; normal has no suffix, like the base game
---@param item_name ItemName
---@param q QualityName
---@return LocalisedString
function M.localised_name_with_quality(ctx, item_name, q)
    if q == "normal" then
        return { "", { "item-name." .. item_name } }
    end

    local quality = data.raw.quality[q]
    local quality_name = quality and quality.localised_name or { "quality-name." .. q }

    -- Colors can be given as an array or with r/g/b keys
    local tint = ctx.base_tint[q] or {}
    local r = tint.r or tint[1] or 255
    local g = tint.g or tint[2] or 255
    local b = tint.b or tint[3] or 255

    return {
        "",
        "[color=" .. r .. "," .. g .. "," .. b .. "]",
        { "item-name." .. item_name },
        " (", quality_name, ")",
        "[/color]"
    }
end

return M
