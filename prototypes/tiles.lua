-- prototypes/tiles.lua
local tile_graphics = require("__base__/prototypes/tile/tile-graphics")
local tile_sounds
if mods["space-age"] then
    tile_sounds = require("__space-age__/prototypes/tile/tile-sounds")
end

-- TilePrototype.layer is a uint8
local MAX_TILE_LAYER = 255

local M = {}

local function frozen_concrete(q_tile_name, q_item_name, transition_merge_tile, base_name, layer, localised_name)
    local q_frozen_name = "frozen-" .. q_tile_name
    local frozen_name = "frozen-" .. base_name
    local tile = table.deepcopy(data.raw.tile[base_name])
    tile.order = "z[frozen-concrete]-" .. q_frozen_name
    tile.subgroup = "aquilo-tiles"
    tile.name = q_frozen_name
    tile.localised_name = localised_name
    tile.can_be_part_of_blueprint = true
    tile.placeable_by = { item = q_item_name, count = 1 }
    tile.layer = layer + 1
    tile.sprite_usage_surface = "aquilo"
    tile.variants =
    {
        material_background =
        {
            picture = "__space-age__/graphics/terrain/aquilo/" .. frozen_name .. ".png",
            count = 8,
            scale = 0.5
        },
        transition = tile_graphics.generic_texture_on_concrete_transition
    }
    tile.transition_merges_with_tile = transition_merge_tile
    tile.transition_overlay_layer_offset = 1
    tile.transitions = nil
    tile.transitions_between_transitions = nil
    tile.thawed_variant = q_tile_name
    tile.minable.result = q_item_name
    tile.frozen_variant = nil
    tile.walking_sound = tile_sounds.walking.frozen_concrete
    data:extend({ tile })
    return q_frozen_name
end

---@param naming Naming
function M.make_quality_tile(ctx, naming, fam, base_tile_name, q)
    local base = data.raw.tile[base_tile_name]
    local item_name = naming.q_item_name(fam.base_item, q)

    local t = table.deepcopy(base)
    t.name = naming.q_tile_name(base_tile_name, q)

    t.minable = t.minable or {}
    t.minable.result = item_name
    t.minable.count = 1
    t.localised_name = naming.localised_name_with_quality(ctx, fam.base_item, q)
    t.placeable_by = { item = item_name, count = 1 }
    t.tint = ctx.tints[fam.tint][q] or ctx.base_tint[q]

    t.layer = (base.layer or 0) + fam.layer_slot * ctx.family_layer_span + ctx.quality_offset[q]
    -- +1 for the frozen variant
    if t.layer + 1 > MAX_TILE_LAYER then
        error("Quality Concrete: " .. #ctx.qualities .. " qualities need more tile layers than the game allows ("
            .. MAX_TILE_LAYER .. "). Use fewer quality mods.")
    end

    local merge_tile = naming.q_tile_name(fam.merges_with, q)
    if fam.merges_with ~= fam.base_item then
        t.transition_merges_with_tile = merge_tile
    end
    t.transition_overlay_layer_offset = 0

    if mods["space-age"] then
        t.frozen_variant = frozen_concrete(t.name, item_name, merge_tile, base_tile_name, t.layer, t.localised_name)
    end

    if t.walking_speed_modifier ~= nil then
        t.walking_speed_modifier = t.walking_speed_modifier * (ctx.quality_speed_mult[q] or 1.0)
    end

    return t
end

return M
