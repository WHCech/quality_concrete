-- prototypes/items.lua
local M = {}

-- Small quality badge in the bottom-left corner of an icon of the given size.
-- Qualities define either a single `icon` or a list of `icons` layers (common for modded qualities).
---@return table[] icon layers, empty for normal or a quality without an icon
function M.quality_badge(q, base_icon_size)
    local qproto = data.raw.quality and data.raw.quality[q]
    if not qproto or q == "normal" then return {} end

    local layers = qproto.icons or (qproto.icon and { { icon = qproto.icon, icon_size = qproto.icon_size } }) or {}
    local corner = { -base_icon_size * 0.15, base_icon_size * 0.15 }
    local badge = {}
    for _, layer in ipairs(layers) do
        local size = layer.icon_size or 64
        local shift = layer.shift or { 0, 0 }
        -- Half the layer's own size: a lone 64px icon has a default scale of 0.5, which gives 0.25
        badge[#badge + 1] = {
            icon = layer.icon,
            icon_size = size,
            tint = layer.tint,
            scale = (layer.scale or (32 / size)) * 0.5,
            shift = { corner[1] + (shift[1] or shift.x or 0) * 0.5, corner[2] + (shift[2] or shift.y or 0) * 0.5 },
        }
    end
    return badge
end

---@param naming Naming
function M.make_quality_item(ctx, naming, item_name, q)
    local base_item = data.raw.item[item_name]
    local base_place = base_item.place_as_tile

    local icons = table.deepcopy(base_item.icons) or { { icon = base_item.icon, icon_size = base_item.icon_size or 64 } }
    for _, layer in ipairs(M.quality_badge(q, icons[1].icon_size or 64)) do
        icons[#icons + 1] = layer
    end

    return {
        type = "item",
        name = naming.q_item_name(item_name, q),
        localised_name = naming.localised_name_with_quality(ctx, item_name, q),
        icons = icons,
        order = base_item.order .. string.format("%03d", ctx.quality_offset[q] / 2),
        stack_size = 100,
        auto_recycle = false,
        hidden_in_factoriopedia = true,
        subgroup = "terrain",
        weight = base_item.weight,

        inventory_move_sound = ctx.item_sounds.concrete_inventory_move,
        pick_sound = ctx.item_sounds.concrete_inventory_pickup,
        drop_sound = ctx.item_sounds.concrete_inventory_move,

        place_as_tile = {
            result = naming.q_tile_name(item_name, q),
            condition_size = base_place.condition_size or 1,
            condition = base_place.condition or { layers = { ground_tile = true } },
        },
    }
end

return M
