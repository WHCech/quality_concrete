-- prototypes/recipes.lua
local function recycling_icons(item_name)
    local item = data.raw.item[item_name]
    local size = (item and item.icon_size) or 64

    -- Prefer item.icon, but fall back if the item uses icons
    local base_icon = item and item.icon
    if not base_icon and item and item.icons and item.icons[1] then
        base_icon = item.icons[1].icon
        size = item.icons[1].icon_size or size
    end
    base_icon = base_icon or "__base__/graphics/icons/concrete.png"

    return {
        { icon = "__quality__/graphics/icons/recycling.png",     icon_size = 64 },
        {
            icon = base_icon,
            icon_size = size,
            scale = 0.4 * (64 / size),
        },
        { icon = "__quality__/graphics/icons/recycling-top.png", icon_size = 64 },
    }
end

local function make_recycling_recipe(input, input_amount, output, output_amount, crafting_speed)
    crafting_speed = crafting_speed or 0.25

    return {
        type = "recipe",
        name = input .. "-recycling",
        category = "recycling",
        order = "z",
        enabled = true,
        energy_required = crafting_speed,
        ingredients = { { type = "item", name = input, amount = input_amount } },
        results = { { type = "item", name = output, amount = output_amount } },
        allow_productivity = false,
        auto_recycle = false,
        hidden = true,
        icons = recycling_icons(input)
    }
end

local function replace_ingredient(recipe, old, new)
    for _, ing in pairs(recipe.ingredients or {}) do
        if ing.name == old then
            ing.name = new
        end
    end
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

    local refined_concrete = table.deepcopy(data.raw.recipe["refined-concrete"])
    replace_ingredient(refined_concrete, "concrete", "stone-brick")
    data:extend { refined_concrete }

    local hazard = table.deepcopy(data.raw.recipe["concrete"])
    hazard.name = "hazard-concrete"
    hazard.results = {{ type = "item", name = "hazard-concrete", amount = 10 }}
    replace_ingredient(hazard, "iron-ore", "copper-ore")
    data:extend { hazard }

    local refined_hazard = table.deepcopy(data.raw.recipe["refined-concrete"])
    refined_hazard.name = "refined-hazard-concrete"
    refined_hazard.results = {{ type = "item", name = "refined-hazard-concrete", amount = 10 }}
    replace_ingredient(refined_hazard, "iron-stick", "copper-cable")
    data:extend { refined_hazard }
end
