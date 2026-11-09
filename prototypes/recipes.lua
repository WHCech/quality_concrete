-- prototypes/recipes.lua
local recycling = require("__recycler__.recycling")

-- Steps from normal for every quality on normal's chain (normal = 0, rare = 2)
local function steps_from_normal()
    local steps = {}
    local name, step = "normal", 0
    while name and data.raw.quality[name] and not steps[name] do
        steps[name] = step
        name = data.raw.quality[name].next
        step = step + 1
    end
    return steps
end

-- Recycling a tier item works like the base game's recycling of the concrete it stands for:
-- it gives back a quarter of the recipe's ingredients, at the item's tier plus the recycler's roll.
local function make_recycling_recipe(recipe, tier_item, q, steps)
    local crafted = 0
    for _, result in pairs(recipe.results) do
        if result.type == "item" then crafted = result.amount end
    end

    -- The recycler's generator reverses a recipe; this one stands for crafting the tier item itself
    recycling.generate_recycling_recipe({
        name = tier_item,
        main_product = tier_item,
        energy_required = recipe.energy_required,
        ingredients = table.deepcopy(recipe.ingredients),
        results = { { type = "item", name = tier_item, amount = crafted } },
    }, function() return true end)

    -- The tier item is normal quality, so the recycler starts its roll at normal
    for _, result in pairs(data.raw.recipe[tier_item .. "-recycling"].results) do
        if steps[q] then
            if steps[q] > 0 then result.quality_change = steps[q] end
        else
            -- A tier on another quality chain can't be reached from normal: give that quality, without a roll
            result.quality_min, result.quality_max = q, q
        end
    end
end

local function same_ingredient(a, b)
    return a.type == b.type and a.name == b.name
        and a.quality_min == b.quality_min and a.quality_max == b.quality_max and a.quality_change == b.quality_change
end

local function replace_ingredient(recipe, old, new, amount_mult)
    if not recipe.ingredients then return end

    local merged = {}
    for _, ing in pairs(recipe.ingredients) do
        if ing.name == old then
            ing.name = new
            if amount_mult and ing.amount then
                ing.amount = math.min(ing.amount * amount_mult, 65000)
            end
        end

        -- The rename can collide with an ingredient that is already there (e.g. concrete + stone-brick),
        -- and duplicate ingredients fail to load, so fold them into one entry
        local existing
        for _, m in ipairs(merged) do
            if same_ingredient(m, ing) then
                existing = m
                break
            end
        end
        if existing and existing.amount and ing.amount then
            existing.amount = math.min(existing.amount + ing.amount, 65000)
        else
            merged[#merged + 1] = ing
        end
    end
    recipe.ingredients = merged
end

---@param naming Naming
return function(ctx, naming)
    -- Crafted concrete always becomes a tier item, so nothing can supply plain concrete as an ingredient
    for _, recipe in pairs(data.raw.recipe) do
        for _, fam in ipairs(ctx.families) do
            replace_ingredient(recipe, fam.base_item, "stone-brick", 5)
        end
    end

    local hazard = table.deepcopy(data.raw.recipe["concrete"])
    hazard.name = "hazard-concrete"
    hazard.results = { { type = "item", name = "hazard-concrete", amount = 10 } }
    replace_ingredient(hazard, "iron-ore", "copper-ore")
    data:extend { hazard }

    local refined_hazard = table.deepcopy(data.raw.recipe["refined-concrete"])
    refined_hazard.name = "refined-hazard-concrete"
    refined_hazard.results = { { type = "item", name = "refined-hazard-concrete", amount = 10 } }
    replace_ingredient(refined_hazard, "iron-stick", "copper-cable")
    data:extend { refined_hazard }

    -- After the replacements above, so recycling gives back the ingredients the recipes now use
    local steps = steps_from_normal()
    for _, fam in ipairs(ctx.families) do
        for _, q in ipairs(ctx.qualities) do
            make_recycling_recipe(data.raw.recipe[fam.base_item], naming.q_item_name(fam.base_item, q), q, steps)
        end
    end
end
