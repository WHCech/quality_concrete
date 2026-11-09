-- prototypes/generate.lua
---@param naming Naming
---@return nil
return function(ctx, naming, items_mod, tiles_mod)
    local items, tiles = {}, {}

    for _, fam in ipairs(ctx.families) do
        for _, q in ipairs(ctx.qualities) do
            items[#items + 1] = items_mod.make_quality_item(ctx, naming, fam, q)

            for _, base_tile in ipairs(fam.base_tiles) do
                tiles[#tiles + 1] = tiles_mod.make_quality_tile(ctx, naming, fam, base_tile, q)
            end
        end
    end

    data:extend(items)
    data:extend(tiles)

    -- Base game tiles (placed before the mod, or in old blueprints) act as the normal tier:
    -- they mine into it and robots build their ghosts from it. Leftover plain concrete still works too.
    for _, fam in ipairs(ctx.families) do
        local normal_item = naming.q_item_name(fam.base_item, "normal")
        for _, base_tile in ipairs(fam.base_tiles) do
            for _, tile_name in ipairs({ base_tile, "frozen-" .. base_tile }) do
                local tile = data.raw.tile[tile_name]
                if tile and tile.minable then
                    tile.minable.result = normal_item
                    tile.placeable_by = { { item = normal_item, count = 1 }, { item = fam.base_item, count = 1 } }
                end
            end
        end
    end

    -- Rotating a left/right pair (hazard tiles) swaps them within the same tier
    for _, fam in ipairs(ctx.families) do
        local left_base, right_base = fam.base_tiles[1], fam.base_tiles[2]
        if right_base then
            for _, q in ipairs(ctx.qualities) do
                local left, right = naming.q_tile_name(left_base, q), naming.q_tile_name(right_base, q)
                data.raw.tile[left].next_direction = right
                data.raw.tile[right].next_direction = left
            end
        end
    end
end
