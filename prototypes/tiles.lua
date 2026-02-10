-- prototypes/tiles.lua
local M = {}

function M.make_quality_tile(ctx, naming, base_tile_name, item_name, q)
    local base = data.raw.tile[base_tile_name]
    if not base or not q then return nil end

    local t = table.deepcopy(base)
    t.name = base_tile_name .. "-quality-" .. q

    t.minable = t.minable or {}
    t.minable.result = naming.q_item_name(item_name, q)
    t.minable.count = 1
    t.placeable_by = { item = naming.q_item_name(item_name, q), count = 1 }

    local b_layer = (base.layer or 0)
    local off_layer = (ctx.quality_offset[q] or 0)
    local max_offset = ctx.quality_offset.legendary or 0

    if base_tile_name:find("hazard", 1, true) then
        t.tint = ctx.hazard_tint[q] or ctx.base_tint[q]
        if base_tile_name:find("refined", 1, true) then
            t.transition_merges_with_tile = "refined-concrete" .. "-quality-" .. q
            t.layer = b_layer + 3 * max_offset + off_layer
        else
            t.transition_merges_with_tile = "concrete" .. "-quality-" .. q
            t.layer = b_layer + 1 * max_offset + off_layer
        end
    else
        t.tint = ctx.concrete_tint[q] or ctx.base_tint[q]
        if base_tile_name:find("refined", 1, true) then
            t.layer = b_layer + 2 * max_offset + off_layer
        else
            t.layer = b_layer + 0 * max_offset + off_layer
        end
    end

    t.transition_overlay_layer_offset = 0

    local mult = ctx.quality_speed_mult[q] or 1.0
    if t.walking_speed_modifier ~= nil then
        t.walking_speed_modifier = t.walking_speed_modifier * mult
    end

    return t
end

return M
