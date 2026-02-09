local item_sounds = require("__base__.prototypes.item_sounds")
local item_tints = require("__base__.prototypes.item-tints")
------------------------------------------------------------------------
---Globals
------------------------------------------------------------------------

local quality_data = data.raw.quality
log("QC: qualities:\n" .. serpent.line(data.raw.quality))


local qualities = {}

local quality_offset = {}

local quality_speed_mult = {}

local concrete_tint = {
    normal = { r = 1.0, g = 1.0, b = 1.0, a = 1 },
    uncommon = { r = 0.7, g = 1.0, b = 0.7, a = 1 },
    rare = { r = 0.7, g = 0.8, b = 1.0, a = 1 },
    epic = { r = 1.0, g = 0.7, b = 0.7, a = 1 },
    legendary = { r = 1.0, g = 0.85, b = 0.65, a = 1 },
}

local hazard_tint = {
    normal = { r = 1.0, g = 1.0, b = 1.0, a = 1 },
    uncommon = { r = 0.7, g = 1.0, b = 0.7, a = 1 },
    rare = { r = 0.7, g = 0.7, b = 1.0, a = 1 },
    epic = { r = 0.9, g = 0.7, b = 1.0, a = 1 },
    legendary = { r = 1.0, g = 0.85, b = 0.65, a = 1 },
}

local base_tint = {}

for name, tier in pairs(quality_data) do
    local level = (tier.level or 0)
    quality_offset[name] = level * 2
    quality_speed_mult[name] = 1 + level * 0.20
    base_tint[name] = tier.color
    if name ~= "quality-unknown" then
        table.insert(qualities, name)
    end
end

table.sort(qualities, function(a, b)
    return (quality_data[a].level or 0) < (quality_data[b].level or 0)
end)

-- Base item -> which base tile(s) to clone for visuals and placement pattern
local families = {
    {
        base_item = "concrete",
        base_tiles = { "concrete" }
    },
    {
        base_item = "refined-concrete",
        base_tiles = { "refined-concrete" }
    },
    {
        base_item = "hazard-concrete",
        base_tiles = { "hazard-concrete-left", "hazard-concrete-right" }
    },
    {
        base_item = "refined-hazard-concrete",
        base_tiles = { "refined-hazard-concrete-left", "refined-hazard-concrete-right" }
    }
}
------------------------------------------------------------------------
---Items
------------------------------------------------------------------------

local function q_tile_name(item_name, q)
    local base = item_name

    if item_name == "hazard-concrete" or item_name == "refined-hazard-concrete" then
        base = base .. "-left"
    end

    return base .. "-quality-" .. q
end

local function q_item_name(item_name, q)
    return item_name .. "-" .. q
end

local function make_quality_item(item_name, q)
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

    local t = {
        type = "item",
        name = q_item_name(item_name, q),
        localised_name = { "", string.upper(string.sub(q, 1, 1)) .. string.sub(q, 2), " ", { "item-name." .. item_name } },
        icons = icons,
        order = base_item.order .. quality_offset[q],
        stack_size = 100,
        hidden = false,
        subgroup = "terrain",
        weight = base_item.weight,
        inventory_move_sound = item_sounds.concrete_inventory_move,
        pick_sound = item_sounds.concrete_inventory_pickup,
        drop_sound = item_sounds.concrete_inventory_move,


        place_as_tile = {
            result = q_tile_name(item_name, q),
            condition_size = (base_place and base_place.condition_size) or 1,
            condition = (base_place and base_place.condition) or { layers = { ground_tile = true } },
        },
    }

    return t
end

------------------------------------------------------------------------
---Tiles
------------------------------------------------------------------------

local function make_quality_tile(base_tile_name, item_name, q)
    local base = data.raw.tile[base_tile_name]
    if not base then return nil end
    if not q then return nil end

    local t = table.deepcopy(base)
    t.name = base_tile_name .. "-quality-" .. q

    t.minable = t.minable or {}
    t.minable.result = q_item_name(item_name, q)
    t.minable.count = 1
    t.placeable_by = { item = q_item_name(item_name, q), count = 1 }

    local b_layer = (base.layer or 0)
    local off_layer = (quality_offset[q] or 0)
    local max_offset = quality_offset.legendary

    if base_tile_name:find("hazard", 1, true) then
        t.tint = hazard_tint[q] or base_tint[q]
        if base_tile_name:find("refined", 1, true) then
            --refined-hazard-concrete
            t.transition_merges_with_tile = "refined-concrete" .. "-quality-" .. q
            t.layer = b_layer + 3 * max_offset + off_layer
        else
            --hazard-concrete
            t.transition_merges_with_tile = "concrete" .. "-quality-" .. q
            t.layer = b_layer + 1 * max_offset + off_layer
        end
    else
        t.tint = concrete_tint[q] or base_tint[q]
        if base_tile_name:find("refined", 1, true) then
            --refined-concrete
            t.layer = b_layer + 2 * max_offset + off_layer
        else
            --concrete
            t.layer = b_layer + 0 * max_offset + off_layer
        end
    end
    t.transition_overlay_layer_offset = 0


    -- Scale the existing movement bonus by quality
    local mult = quality_speed_mult[q] or 1.0
    if t.walking_speed_modifier ~= nil then
        t.walking_speed_modifier = t.walking_speed_modifier * mult
    end

    return t
end

------------------------------------------------------------------------
---Create Items and Tiles
------------------------------------------------------------------------

local items = {}
local tiles = {}

for _, fam in ipairs(families) do
    local item_name = fam.base_item

    for _, q in ipairs(qualities) do
        table.insert(items, make_quality_item(item_name, q))

        for _, base_tile in ipairs(fam.base_tiles) do
            table.insert(tiles, make_quality_tile(base_tile, item_name, q))
        end
    end
end

data:extend(items)
data:extend(tiles)

-- Patch hazard next_direction
local function patch_next_direction(left_base, right_base)
    for _, q in ipairs(qualities) do
        local left = data.raw.tile[left_base .. "-quality-" .. q]
        local right = data.raw.tile[right_base .. "-quality-" .. q]
        if left then left.next_direction = right_base .. "-quality-" .. q end
        if right then right.next_direction = left_base .. "-quality-" .. q end
    end
end

patch_next_direction("hazard-concrete-left", "hazard-concrete-right")
patch_next_direction("refined-hazard-concrete-left", "refined-hazard-concrete-right")


------------------------------------------------------------------------
---Recipes
------------------------------------------------------------------------


local base_items = {}
for _, fam in ipairs(families) do
    base_items[fam.base_item] = true
end

for _, fam in ipairs(families) do
    local item_name = fam.base_item
    local r = data.raw.recipe[item_name]
    if r then
        --Patch ingredients
        for _, ing in ipairs(r.ingredients or {}) do
            local ing_name = ing.name or ing[1]
            if ing_name and base_items[ing_name] then
                local new_name = q_item_name(ing_name, "normal")
                if ing.name then
                    ing.name = new_name
                else
                    ing[1] = new_name
                end
            end
        end

        local out = q_item_name(item_name, "normal")

        --determinate outut amount
        local out_amount = 1
        if r.result then
            out_amount = r.result_count or 1
        elseif r.results and r.results[1] then
            local first = r.results[1]
            out_amount = first.amount or first[2] or 1
        end

        r.result = nil
        r.result_count = nil
        r.results = {
            { type = "item", name = out, amount = out_amount }
        }
        r.main_product = out
        r.allow_quality = false
    end
end
