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

local function is_recycling(recipe)
    for _, category in pairs(recipe.categories or {}) do
        if category == "recycling" then return true end
    end
    return false
end

-- Builds <item>-recycling with the recycler's own generator, as if the item were crafted by this recipe.
-- The generator replaces an existing recycling recipe but also adds a second unlock for it, which is dropped.
local function generate_recycling(recipe, item_name)
    local crafted = 0
    for _, result in pairs(recipe.results) do
        if result.type == "item" then crafted = result.amount or result.amount_min end
    end

    local tech = data.raw.technology["recycling"]
    local effect_count = tech and tech.effects and #tech.effects
    local existed = data.raw.recipe[item_name .. "-recycling"] ~= nil

    recycling.generate_recycling_recipe({
        name = item_name,
        main_product = item_name,
        energy_required = recipe.energy_required,
        ingredients = table.deepcopy(recipe.ingredients),
        results = { { type = "item", name = item_name, amount = crafted } },
    }, function() return true end)

    if existed and effect_count and #tech.effects > effect_count then table.remove(tech.effects) end
end

-- Recycling a tier item works like the base game's recycling of the concrete it stands for:
-- it gives back a quarter of the recipe's ingredients, at the item's tier plus the recycler's roll.
local function make_recycling_recipe(recipe, tier_item, q, steps)
    generate_recycling(recipe, tier_item)

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
    -- Crafted concrete always becomes a tier item, so nothing can supply plain concrete as an ingredient.
    -- Recycling recipes keep concrete as their input: they recycle it, they don't consume it.
    for _, recipe in pairs(data.raw.recipe) do
        if not is_recycling(recipe) then
            for _, fam in ipairs(ctx.families) do
                replace_ingredient(recipe, fam.base_item, "stone-brick", 5)
            end
        end
    end

    -- Hazard concrete is crafted like the concrete it is striped from, with copper in place of iron.
    -- The hazard recipe keeps its own name, results, unlock and placement in the menus.
    local function craft_like(target_name, source_name, old, new)
        local target, source = data.raw.recipe[target_name], data.raw.recipe[source_name]
        if not (target and source) then
            log("QC: recipe " .. target_name .. " or " .. source_name .. " is missing, " .. target_name .. " is left as it is")
            return
        end
        target.ingredients = table.deepcopy(source.ingredients)
        target.categories = table.deepcopy(source.categories)
        target.energy_required = source.energy_required
        replace_ingredient(target, old, new)
    end
    craft_like("hazard-concrete", "concrete", "iron-ore", "copper-ore")
    craft_like("refined-hazard-concrete", "refined-concrete", "iron-stick", "copper-cable")

    -- After the replacements above, so recycling gives back the ingredients the recipes now use.
    -- Plain concrete (mined from tiles placed before the mod) recycles like its normal tier.
    local steps = steps_from_normal()
    for _, fam in ipairs(ctx.families) do
        local recipe = data.raw.recipe[fam.base_item]
        if recipe then
            generate_recycling(recipe, fam.base_item)
            for _, q in ipairs(ctx.qualities) do
                make_recycling_recipe(recipe, naming.q_item_name(fam.base_item, q), q, steps)
            end
        else
            log("QC: no recipe named " .. fam.base_item .. ", its tiers can't be recycled")
        end
    end
end
