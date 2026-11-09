-- prototypes/craft_conversion.lua
-- Recipes that make one of the base concrete items, handled by how their machines give out results:
--  * Machines that keep results in their output (assemblers, foundries): the recipe raises an event when
--    crafted and control.lua swaps the crafted item for our item of the rolled tier. The output only
--    accepts the recipe's own products, so the tier item goes to trash slots, which inserters also empty.
--  * Machines that drop results behind them (recyclers) never empty their trash, so a swap there has
--    nowhere to go. Their recipes (recycling a rocket silo, scrap) give stone bricks instead of concrete,
--    like the recipes that used to take concrete, and keep their quality roll that way.
-- The converted recipes are handed to control.lua through a mod-data prototype.

local TRASH_SLOTS = 1
local CRAFTING_MACHINE_TYPES = { "assembling-machine", "furnace", "rocket-silo" }
local BRICKS_PER_CONCRETE = 5

return function(ctx)
    ---@type table<ItemName, boolean>
    local base_items = {}
    for _, fam in ipairs(ctx.families) do
        base_items[fam.base_item] = true
    end

    -- Categories crafted by a machine that drops its results
    local dropping_categories = {}
    for _, machine_type in ipairs(CRAFTING_MACHINE_TYPES) do
        for _, machine in pairs(data.raw[machine_type] or {}) do
            if machine.vector_to_place_result then
                for _, category in pairs(machine.crafting_categories or {}) do
                    dropping_categories[category] = true
                end
            end
        end
    end

    local function recipe_categories(recipe)
        return recipe.categories or { "crafting" }
    end

    local function is_dropped(recipe)
        for _, category in pairs(recipe_categories(recipe)) do
            if dropping_categories[category] then return true end
        end
        return false
    end

    local function crafted_base_item(recipe)
        for _, result in pairs(recipe.results or {}) do
            if result.type == "item" and base_items[result.name] then return result.name end
        end
    end

    local function results_to_bricks(recipe)
        for _, result in pairs(recipe.results) do
            if result.type == "item" and base_items[result.name] then
                result.name = "stone-brick"
                -- Recycling results keep the part below one in extra_count_fraction; whole bricks from it move into the amounts
                local fraction = (result.extra_count_fraction or 0) * BRICKS_PER_CONCRETE
                local whole = math.floor(fraction)
                if result.extra_count_fraction then result.extra_count_fraction = fraction - whole end
                for _, field in pairs({ "amount", "amount_min", "amount_max" }) do
                    if result[field] then result[field] = math.min(result[field] * BRICKS_PER_CONCRETE + whole, 65000) end
                end
            end
        end
        if base_items[recipe.main_product or ""] then recipe.main_product = "stone-brick" end
    end

    ---@type table<string, ItemName> recipe name -> base item it makes
    local conversions = {}
    local trash_categories = {}

    for name, recipe in pairs(data.raw.recipe) do
        local item_name = crafted_base_item(recipe)
        if item_name then
            if is_dropped(recipe) then
                results_to_bricks(recipe)
            else
                recipe.raise_on_crafted = true
                conversions[name] = item_name
                for _, category in pairs(recipe_categories(recipe)) do trash_categories[category] = true end
            end
        end
    end

    for _, machine_type in ipairs(CRAFTING_MACHINE_TYPES) do
        for _, machine in pairs(data.raw[machine_type] or {}) do
            if not machine.vector_to_place_result then
                for _, category in pairs(machine.crafting_categories or {}) do
                    if trash_categories[category] then
                        machine.trash_inventory_size = math.max(machine.trash_inventory_size or 0, TRASH_SLOTS)
                        break
                    end
                end
            end
        end
    end

    data:extend { {
        type = "mod-data",
        name = "quality_concrete-craft-conversions",
        data = { recipes = conversions },
    } }
end
