-- prototypes/recipes.lua
-- Defines the global generate_recycling_recipe_icons_from_item, which keeps every icon layer (quality badge included)
require("__recycler__.recycling")

local function make_recycling_recipe(input, input_amount, output, output_amount, crafting_speed)
    crafting_speed = crafting_speed or 0.25
    local item = data.raw.item[input]

    return {
        type = "recipe",
        name = input .. "-recycling",
        -- Same naming as the recycler's generated recipes: "<item> recycling"
        localised_name = { "recipe-name.recycling", item.localised_name or { "item-name." .. input } },
        categories = { "recycling" },
        order = "z",
        enabled = true,
        energy_required = crafting_speed,
        ingredients = { { type = "item", name = input, amount = input_amount } },
        results = { { type = "item", name = output, amount = output_amount } },
        allow_productivity = false,
        auto_recycle = false,
        hidden = true,
        hidden_in_factoriopedia = true,
        icons = generate_recycling_recipe_icons_from_item(item)
    }
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
    local recipes = {}

    for _, fam in ipairs(ctx.families) do
        local item_name = fam.base_item

        for _, q in ipairs(ctx.qualities) do
            local q_base_item = naming.q_item_name(item_name, q)
            recipes[#recipes + 1] = make_recycling_recipe(q_base_item, 8,
                naming.q_recycling_placeholder_name(item_name, q), 2)
        end
    end
    data:extend(recipes)


    local recipes_consuming_concrete = {}
    local concrete_items = {}
    for _, fam in ipairs(ctx.families) do
        concrete_items[fam.base_item] = true
    end


    local function recipe_uses_concrete(recipe)
        local function check_ingredients(ings)
            if not ings then return false end

            for _, ing in pairs(ings) do
                local name = ing.name or ing[1]
                if concrete_items[name] then
                    return true
                end
            end
            return false
        end

        -- modern unified ingredients
        if check_ingredients(recipe.ingredients) then
            return true
        end

        -- old difficulty split
        if recipe.normal and check_ingredients(recipe.normal.ingredients) then return true end
        if recipe.expensive and check_ingredients(recipe.expensive.ingredients) then return true end

        return false
    end

    for name, recipe in pairs(data.raw.recipe) do
        if recipe_uses_concrete(recipe) then
            recipes_consuming_concrete[#recipes_consuming_concrete + 1] = name
        end
    end

    for _, r in ipairs(recipes_consuming_concrete) do
        local recipe = table.deepcopy(data.raw.recipe[r])
        replace_ingredient(recipe, "concrete", "stone-brick", 5)
        replace_ingredient(recipe, "refined-concrete", "stone-brick", 5)
        data:extend { recipe }
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
end
