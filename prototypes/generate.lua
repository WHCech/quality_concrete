-- prototypes/generate.lua
return function(ctx, naming, items_mod, tiles_mod)
    local items, tiles = {}, {}

    for _, fam in ipairs(ctx.families) do
        local item_name = fam.base_item
        for _, q in ipairs(ctx.qualities) do
            items[#items + 1] = items_mod.make_quality_item(ctx, naming, item_name, q)
            for _, base_tile in ipairs(fam.base_tiles) do
                tiles[#tiles + 1] = tiles_mod.make_quality_tile(ctx, naming, base_tile, item_name, q)
            end
        end
    end

    data:extend(items)
    data:extend(tiles)

    local function patch_next_direction(left_base, right_base)
        for _, q in ipairs(ctx.qualities) do
            local left = data.raw.tile[left_base .. "-quality-" .. q]
            local right = data.raw.tile[right_base .. "-quality-" .. q]
            if left then left.next_direction = right_base .. "-quality-" .. q end
            if right then right.next_direction = left_base .. "-quality-" .. q end
        end
    end

    patch_next_direction("hazard-concrete-left", "hazard-concrete-right")
    patch_next_direction("refined-hazard-concrete-left", "refined-hazard-concrete-right")
end
