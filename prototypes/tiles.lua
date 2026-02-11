-- prototypes/tiles.lua
local tile_graphics = require("__base__/prototypes/tile/tile-graphics")
local tile_sounds = require("__space-age__/prototypes/tile/tile-sounds")


local M = {}

local function frozen_concrete(q_tile_name, q_item_name, transition_merge_tile, base_name, layer, localised_name)
    local q_frozen_name = "frozen-" .. q_tile_name
    local frozen_name = "frozen-" .. base_name
    local base_prototype = data.raw.tile[base_name]
    local frozen_concrete = table.deepcopy(base_prototype)
    frozen_concrete.order = "z[frozen-concrete]-" .. q_frozen_name
    frozen_concrete.subgroup = "aquilo-tiles"
    frozen_concrete.name = q_frozen_name
    frozen_concrete.localised_name = localised_name
    frozen_concrete.can_be_part_of_blueprint = true
    frozen_concrete.placeable_by = { item = q_item_name, count = 1 }
    frozen_concrete.layer = layer + 1
    frozen_concrete.sprite_usage_surface = "aquilo"
    frozen_concrete.variants =
    {
        material_background =
        {
            picture = "__space-age__/graphics/terrain/aquilo/" .. frozen_name .. ".png",
            count = 8,
            scale = 0.5
        },
        transition = tile_graphics.generic_texture_on_concrete_transition
    }
    frozen_concrete.transition_merges_with_tile = transition_merge_tile
    frozen_concrete.transition_overlay_layer_offset = 1
    frozen_concrete.transitions = nil
    frozen_concrete.transitions_between_transitions = nil
    frozen_concrete.thawed_variant = q_tile_name
    frozen_concrete.minable.result = q_item_name
    frozen_concrete.frozen_variant = nil
    frozen_concrete.walking_sound = tile_sounds.walking.frozen_concrete
    data:extend({ frozen_concrete })
    return q_frozen_name
end

---@param naming Naming
function M.make_quality_tile(ctx, naming, base_tile_name, item_name, q)
    local base = data.raw.tile[base_tile_name]
    if not base or not q then return nil end

    local t = table.deepcopy(base)
    t.name = base_tile_name .. "-quality-" .. q

    t.minable = t.minable or {}
    t.minable.result = naming.q_item_name(item_name, q)
    t.localised_name = naming.localised_name_with_quality(ctx, item_name, q)
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
    local frozen_merge_tile
    if base_tile_name:find("refined", 1, true) then
        frozen_merge_tile = "refined-concrete" .. "-quality-" .. q
    else
        frozen_merge_tile = "concrete" .. "-quality-" .. q
    end
    t.transition_overlay_layer_offset = 0
    t.frozen_variant = frozen_concrete(
        t.name,
        t.minable.result,
        frozen_merge_tile,
        base_tile_name,
        t.layer,
        t.localised_name
    )

    local mult = ctx.quality_speed_mult[q] or 1.0
    if t.walking_speed_modifier ~= nil then
        t.walking_speed_modifier = t.walking_speed_modifier * mult
    end

    return t
end

return M
