-- prototypes/recipes.lua
local function linear_probs(n)
    local probs = {}
    k = 4
    local weights = {}
    local total = 0
    for i = 1, n do
        local w = (n - i + 1) ^ k
        weights[i] = w
        total = total + w
    end

    for i = 1, n do
        probs[i] = weights[i] / total
    end

    return probs
end

return function(ctx, naming)
    --Change basegame recipes to normal quality
    local base_items = {}
    for _, fam in ipairs(ctx.families) do
        base_items[fam.base_item] = true
    end

    for _, fam in ipairs(ctx.families) do
        local item_name = fam.base_item
        local r = data.raw.recipe[item_name]
        if r then
            -- Patch ingredients (rename base concrete ingredients -> normal quality)
            for _, ingredient in ipairs(r.ingredients or {}) do
                if ingredient.type ~= "fluid" then
                    local ing_name = ingredient.name or ingredient[1]
                    if ing_name and base_items[ing_name] then
                        local new_name = naming.q_item_name(ing_name, "normal")
                        if ingredient.name then ingredient.name = new_name else ingredient[1] = new_name end
                    end
                end
            end

            local out = naming.q_item_name(item_name, "normal")

            -- Determine output amount
            local out_amount = 1
            if r.result then
                out_amount = r.result_count or 1
            elseif r.results and r.results[1] then
                local first = r.results[1]
                out_amount = first.amount or first[2] or 1
            end

            r.result = nil
            r.result_count = nil
            r.results = { { type = "item", name = out, amount = out_amount } }
            r.main_product = out
            r.localised_name = naming.localised_name_with_quality(fam.base_item, "normal")
            r.allow_quality = false
        end
    end

    for _, fam in ipairs(ctx.families) do
        local unlocked_qualities = { "normal" }
        for _, tech in ipairs(ctx.tech_to_quality) do
            for _, q in ipairs(tech.qualities) do
                table.insert(unlocked_qualities, q)
            end
            local probabilitys = linear_probs(#unlocked_qualities)
            local results = {}
            local max_q
            for i_qualities, q in ipairs(unlocked_qualities) do
                max_q = q
                local result_name = naming.q_item_name(fam.base_item, q)
                table.insert(results,
                    { type = "item", name = result_name, amount = 10, probability = probabilitys[i_qualities] })
            end

            data:extend({
                {
                    type = "recipe",
                    name = naming.q_item_name(fam.base_item, max_q),
                    localised_name = naming.localised_name_with_quality(fam.base_item, max_q),
                    energy_required = 2,
                    enabled = true,
                    category = "crafting",
                    ingredients = { { type = "item", name = naming.q_item_name(fam.base_item, "normal"), amount = 10 } },
                    results = results,
                    main_product = naming.q_item_name(fam.base_item, max_q),
                    allow_quality = false
                },
            })
        end
    end
end