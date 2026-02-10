-- prototypes/items.lua
local M = {}

function M.make_quality_item(ctx, naming, item_name, q)
    if not q then return nil end
    local base_item = data.raw.item[item_name]
    local base_place = base_item and base_item.place_as_tile

    local base_icon = (base_item and base_item.icon) or "__base__/graphics/icons/iron-plate.png"
    local base_icon_size = (base_item and base_item.icon_size) or 64

    local qproto = data.raw.quality and data.raw.quality[q]

    local icons = {
        { icon = base_icon, icon_size = base_icon_size }
    }

    if qproto and qproto.icon and q ~= "normal" then
        table.insert(icons, {
            icon = qproto.icon,
            icon_size = qproto.icon_size or 64,
            scale = 0.25,
            shift = { -base_icon_size * 0.15, base_icon_size * 0.15 },
        })
    end

    return {
        type = "item",
        name = naming.q_item_name(item_name, q),
        localised_name = naming.localised_name_with_quality(item_name, q),
        icons = icons,
        order = base_item.order .. ctx.quality_offset[q]/2,
        stack_size = 100,
        hidden = false,
        subgroup = "terrain",
        weight = base_item.weight,

        inventory_move_sound = ctx.item_sounds.concrete_inventory_move,
        pick_sound = ctx.item_sounds.concrete_inventory_pickup,
        drop_sound = ctx.item_sounds.concrete_inventory_move,

        place_as_tile = {
            result = naming.q_tile_name(item_name, q),
            condition_size = (base_place and base_place.condition_size) or 1,
            condition = (base_place and base_place.condition) or { layers = { ground_tile = true } },
        },
    }
end

return M
