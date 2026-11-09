-- migrations/quality_concrete_1.0.0.lua
-- The JSON migration (quality_concrete_1.0.0-placeholders.json) renames leftover spoilage placeholders but keeps their quality, which leaves
--  * base concrete at some quality (concrete at rare), which should be our tier item (concrete-rare)
--  * tier items at some quality (concrete-rare at epic, from recycling), which should move up by that quality
-- This converts both once, wherever an inventory can be reached. Belts, inserter hands and robots are not covered.

local FAMILIES = require("__quality_concrete__/prototypes/families")
local naming = require("__quality_concrete__/prototypes/naming")
local tiers = require("__quality_concrete__/scripts/tiers")

local base_items = {}
for _, fam in ipairs(FAMILIES) do base_items[fam.base_item] = true end

---@return string? the tier item this item at this quality should be
local function target_of(name, quality)
    local target
    if base_items[name] then
        target = naming.q_item_name(name, quality)
    else
        local info = tiers.item_tiers()[name]
        local steps = info and quality ~= "normal" and tiers.chain_position(quality)
        if steps then
            target = naming.q_item_name(info.family, tiers.raise_tier(info.tier, steps))
        end
    end
    if target and prototypes.item[target] then return target end
end

local converted = 0

local function convert_inventory(inventory)
    if not inventory or not inventory.valid then return end
    for _, item in pairs(inventory.get_contents()) do
        local target = target_of(item.name, item.quality)
        if target then
            local old = { name = item.name, quality = item.quality, count = item.count }
            local removed = inventory.remove(old)
            local inserted = removed > 0 and inventory.insert({ name = target, count = removed }) or 0
            if inserted < removed then
                -- e.g. a filtered slot that won't take the new item: put the rest back as it was
                old.count = removed - inserted
                inventory.insert(old)
            end
            converted = converted + inserted
        end
    end
end

local function convert_stack(stack)
    if not (stack and stack.valid_for_read) then return end
    local target = target_of(stack.name, stack.quality.name)
    if target then
        local count = stack.count
        if stack.set_stack({ name = target, count = count }) then converted = converted + count end
    end
end

-- Entity types that never hold items
local SKIPPED_TYPES = { "tree", "resource", "simple-entity", "cliff", "fish", "corpse", "character-corpse",
    "tile-ghost", "entity-ghost", "smoke-with-trigger", "explosion" }

for _, surface in pairs(game.surfaces) do
    for _, entity in pairs(surface.find_entities_filtered { type = SKIPPED_TYPES, invert = true }) do
        if entity.type == "item-entity" then
            convert_stack(entity.stack)
        else
            for index = 1, entity.get_max_inventory_index() do
                convert_inventory(entity.get_inventory(index))
            end
        end
    end
end

for _, player in pairs(game.players) do
    convert_stack(player.cursor_stack)
    -- A player without a character (god mode, editor) keeps an inventory of their own
    if not player.character then convert_inventory(player.get_main_inventory()) end
end

log("QC: migration converted " .. converted .. " leftover concrete items to their tier")
