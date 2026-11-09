-- control.lua
local FAMILIES = require("__quality_concrete__/prototypes/families")
local tiers = require("__quality_concrete__/scripts/tiers")

local TILE_SIZE = 3 -- 3x3 blocks
local GAP = 1       -- space between blocks
local CELL = TILE_SIZE + GAP

local function debug_enabled()
    return settings.startup["debug-spawn-all-tiles"]
        and settings.startup["debug-spawn-all-tiles"].value == true
end

local function sorted_qualities()
    local q = {}

    for name, proto in pairs(prototypes.quality or {}) do
        if name ~= "quality-unknown" then
            q[#q + 1] = { name = name, level = proto.level or 0 }
        end
    end

    table.sort(q, function(a, b)
        if a.level ~= b.level then return a.level < b.level end
        return a.name < b.name
    end)

    local out = {}
    for i = 1, #q do out[i] = q[i].name end
    return out
end

local function set_block(surface, x, y, tile)
    local tiles = {}

    for dx = 0, TILE_SIZE - 1 do
        for dy = 0, TILE_SIZE - 1 do
            tiles[#tiles + 1] = { name = tile, position = { x + dx, y + dy } }
        end
    end

    surface.set_tiles(tiles, true, true, true)
end

local function place_grid(player)
    local surface   = player.surface
    local qualities = sorted_qualities()

    local cols      = #FAMILIES
    local rows      = #qualities

    local width     = cols * CELL - GAP
    local height    = rows * CELL - GAP

    local start_x   = math.floor(player.position.x - width / 2)
    local start_y   = math.floor(player.position.y - height / 2)

    for col, fam in ipairs(FAMILIES) do
        local x = start_x + (col - 1) * CELL

        for row, q in ipairs(qualities) do
            local y = start_y + (row - 1) * CELL
            local tile_name = fam.base_tiles[1] .. "-quality-" .. q

            if prototypes.tile[tile_name] then
                set_block(surface, x, y, tile_name)
            else
                log("QC\tmissing tile\t" .. tile_name)
            end
        end
    end

    player.print("QC: spawned preview grid (debug-spawn-all-tiles).")
end

script.on_event(defines.events.on_player_created, function(e)
    if not debug_enabled() then return end
    if storage.qc_grid_done then return end
    storage.qc_grid_done = true

    local player = game.get_player(e.player_index)
    if player then
        place_grid(player)
    end
end)

-- Quality cycling
-- Our concrete items are always normal quality; the tier lives in the item name (concrete-rare).
-- Cycling quality on them would give e.g. concrete-normal at uncommon quality, so instead
-- we step to the item of the next tier and put that one in the cursor.

---@return string?, string? item name, quality name of whatever is in the cursor
local function cursor_item(player)
    local stack = player.cursor_stack
    if stack and stack.valid_for_read then
        return stack.name, stack.quality.name
    end
    local ghost = player.cursor_ghost
    if ghost then
        local name = type(ghost.name) == "string" and ghost.name or ghost.name.name
        local quality = ghost.quality and (type(ghost.quality) == "string" and ghost.quality or ghost.quality.name) or "normal"
        return name, quality
    end
end

-- Next tier in the quality chain that has an item for this family. Nil at the end of the chain.
-- Locked qualities are not skipped: the game's own cycling reaches them too.
local function step_tier(family, tier, direction)
    local proto = prototypes.quality[tier]
    for _ = 1, 255 do
        -- not `direction > 0 and proto.next or proto.previous`: that falls back to previous at the top end
        if direction > 0 then
            proto = proto.next
        else
            proto = proto.previous
        end
        if not proto or (not proto.hidden and tiers.item_tiers()[family .. "-" .. proto.name]) then break end
    end
    return proto and proto.name
end

-- Takes the item from the main inventory like the game's pipette does, or holds a ghost if there is none.
local function put_in_cursor(player, item_name)
    local item = { name = item_name, quality = "normal" }
    -- No cursor in this controller, or the held stack can't go back (full inventory): leave the cursor alone
    if not player.cursor_stack then return end
    if not player.clear_cursor() then return end

    local inventory = player.get_main_inventory()
    local stack, slot
    if inventory then
        stack, slot = inventory.find_item_stack(item)
    end

    if stack and player.cursor_stack.transfer_stack(stack) then
        if player.character and slot then
            player.hand_location = { inventory = inventory.index, slot = slot }
        end
    else
        player.cursor_ghost = item
    end
end

local function on_cycle_quality(e, direction)
    local player = game.get_player(e.player_index)
    if not player then return end

    local name, quality = cursor_item(player)
    local info = name and tiers.item_tiers()[name]
    if not info then return end

    local tier = step_tier(info.family, info.tier, direction)
    local target = tier and (info.family .. "-" .. tier) or name

    -- The game's own cycle runs right after this event, but only changes the cursor if the
    -- held quality has a neighbour in that direction (scrolling down from normal does nothing)
    local held = prototypes.quality[quality]
    local game_will_cycle
    if direction > 0 then
        game_will_cycle = held.next ~= nil
    else
        game_will_cycle = held.previous ~= nil
    end

    if quality == "normal" and game_will_cycle then
        -- Swap once the game's change raises on_player_cursor_stack_changed
        storage.qc_pending_cycle = storage.qc_pending_cycle or {}
        storage.qc_pending_cycle[e.player_index] = { tick = e.tick, item = target }
    else
        put_in_cursor(player, target)
    end
end

script.on_event("quality_concrete-cycle-quality-up", function(e) on_cycle_quality(e, 1) end)
script.on_event("quality_concrete-cycle-quality-down", function(e) on_cycle_quality(e, -1) end)

script.on_event(defines.events.on_player_cursor_stack_changed, function(e)
    local pending = storage.qc_pending_cycle and storage.qc_pending_cycle[e.player_index]
    if not pending then return end
    storage.qc_pending_cycle[e.player_index] = nil

    -- Only the game's own cycle in the same tick counts; a leftover from an earlier tick is dropped
    -- so it can't swap the cursor on some later, unrelated change
    if pending.tick ~= e.tick then return end

    local player = game.get_player(e.player_index)
    if player then
        put_in_cursor(player, pending.item)
    end
end)

-- Crafted concrete
-- Recipes make the base game's concrete at a real quality, but a placed tile can't keep a quality.
-- Right after the craft it is swapped for our item of that tier (concrete at rare -> concrete-rare at normal).
-- data-final-fixes lists the recipes in a mod-data prototype.

---@type table<string, string> recipe name -> base item it makes
local CONVERSIONS = prototypes.mod_data["quality_concrete-craft-conversions"].data.recipes

---@return string? the tier item crafted concrete of this quality becomes
local function converted_item(item_name, quality)
    local name = item_name .. "-" .. quality
    if prototypes.item[name] then return name end
end

-- The output only takes the recipe's own products, so the tier item goes to the trash slots
-- data-final-fixes added
local function convert_in_output(output, trash, item_name, quality, count)
    local target = converted_item(item_name, quality)
    if not target then return end

    local crafted = { name = item_name, quality = quality, count = count }
    local removed = output.remove(crafted)
    local inserted = trash.insert({ name = target, count = removed })
    if inserted < removed then
        -- Trash is full: keep the rest as crafted, which also stops the machine until it is emptied
        crafted.count = removed - inserted
        output.insert(crafted)
    end
end

local function on_recipe_crafted(e)
    local item_name = CONVERSIONS[e.recipe]
    if not item_name or not e.entity.valid then return end
    local output = e.entity.get_inventory(defines.inventory.crafter_output)
    -- A machine added after data-final-fixes has no trash slots and is left alone
    local trash = e.entity.get_inventory(defines.inventory.crafter_trash)
    if not output or not trash then return end

    -- Every quality, not only this craft's: a full trash may have left earlier crafts unconverted
    for _, stack in pairs(output.get_contents()) do
        if stack.name == item_name then
            convert_in_output(output, trash, item_name, stack.quality, stack.count)
        end
    end
end

local crafted_events = {}
for recipe_name in pairs(CONVERSIONS) do
    local recipe = prototypes.recipe[recipe_name]
    if recipe and recipe.on_crafted_event then
        crafted_events[#crafted_events + 1] = recipe.on_crafted_event
    end
end
if #crafted_events > 0 then
    script.on_event(crafted_events, on_recipe_crafted)
end

-- Handcrafting doesn't raise the recipe's event; the crafted stack can still be changed before it is inserted
script.on_event(defines.events.on_player_crafted_item, function(e)
    local item_name = CONVERSIONS[e.recipe.name]
    local stack = e.item_stack
    if not item_name or not stack.valid_for_read or stack.name ~= item_name then return end

    local target = converted_item(item_name, stack.quality.name)
    if target then
        stack.set_stack({ name = target, count = stack.count })
    end
end)

-- One-time notice for saves upgraded from a version that used Runtime Spoilage Library
script.on_configuration_changed(function(data)
    local change = data.mod_changes["quality_concrete"]
    if not (change and change.old_version) then return end
    if helpers.compare_versions(change.old_version, "1.0.0") >= 0 then return end

    log("QC: upgraded from " .. change.old_version .. ", showing the dependency notice")
    game.print({ "quality_concrete.dependency-notice" })
end)
