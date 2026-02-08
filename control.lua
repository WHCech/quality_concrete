-- control.lua
-- Quality Concrete
-- Applies different module bonuses depending on which material fully covers a machine.

local function stack_quality(stack)
    if not stack or not stack.valid_for_read then return "normal" end
    if stack.quality then
        return tostring(stack.quality.name)
    end
    return "normal"
end

local function quality_tile_name(base_tile_name, q)
    return base_tile_name .. "-quality-" .. q
end

local function on_built_tile_handle_quality(event)
    local surface = game.get_surface(event.surface_index)
    if not surface then return end

    local q = "normal"

    local qual = event.quality
    if qual and qual.valid then
        q = qual.name
    end


    -- Player: cursor stack is usually the tile item stack
    if event.player_index and q == "normal" then
        local p = game.get_player(event.player_index)
        if p and p.valid then
            q = stack_quality(p.cursor_stack)
        end
    end

    -- Robot/mod: if event provides a stack, use it
    if event.item_stack and q == "normal" then
        q = stack_quality(event.item_stack)
    elseif event.stack then
        q = stack_quality(event.stack)
    end

    local set = {}
    for _, t in ipairs(event.tiles or {}) do
        local placed = surface.get_tile(t.position.x, t.position.y)
        local base_name = placed.name

        local desired = quality_tile_name(base_name, q)
        if prototypes.tile[desired] then
            set[#set + 1] = { name = desired, position = t.position }
        end
    end

    if #set > 0 then
        surface.set_tiles(set, true)
    end
end

script.on_event(defines.events.on_player_built_tile, on_built_tile_handle_quality)
script.on_event(defines.events.on_robot_built_tile, on_built_tile_handle_quality)
script.on_event(defines.events.script_raised_set_tiles, on_built_tile_handle_quality)


script.on_event(defines.events.on_player_created, function(event)
    local player = game.players[event.player_index]
    local character = player.character or player.cutscene_character
    if character then
        character.insert { name = "concrete", quality = "normal", count = 10 }
        character.insert { name = "concrete", quality = "uncommon", count = 10 }
        character.insert { name = "concrete", quality = "rare", count = 10 }
        character.insert { name = "concrete", quality = "epic", count = 10 }
        character.insert { name = "concrete", quality = "legendary", count = 10 }

        character.insert { name = "refined-concrete", quality = "normal", count = 10 }
        character.insert { name = "refined-concrete", quality = "uncommon", count = 10 }
        character.insert { name = "refined-concrete", quality = "rare", count = 10 }
        character.insert { name = "refined-concrete", quality = "epic", count = 10 }
        character.insert { name = "refined-concrete", quality = "legendary", count = 10 }

        character.insert { name = "hazard-concrete", quality = "normal", count = 10 }
        character.insert { name = "hazard-concrete", quality = "uncommon", count = 10 }
        character.insert { name = "hazard-concrete", quality = "rare", count = 10 }
        character.insert { name = "hazard-concrete", quality = "epic", count = 10 }
        character.insert { name = "hazard-concrete", quality = "legendary", count = 10 }

        character.insert { name = "refined-hazard-concrete", quality = "normal", count = 10 }
        character.insert { name = "refined-hazard-concrete", quality = "uncommon", count = 10 }
        character.insert { name = "refined-hazard-concrete", quality = "rare", count = 10 }
        character.insert { name = "refined-hazard-concrete", quality = "epic", count = 10 }
        character.insert { name = "refined-hazard-concrete", quality = "legendary", count = 10 }

        player.set_quick_bar_slot(1, { name = "concrete", quality = "normal" })
        player.set_quick_bar_slot(2, { name = "concrete", quality = "uncommon" })
        player.set_quick_bar_slot(3, { name = "concrete", quality = "rare" })
        player.set_quick_bar_slot(4, { name = "concrete", quality = "epic" })
        player.set_quick_bar_slot(5, { name = "concrete", quality = "legendary" })

        player.set_quick_bar_slot(6, { name = "hazard-concrete", quality = "normal" })
        player.set_quick_bar_slot(7, { name = "hazard-concrete", quality = "uncommon" })
        player.set_quick_bar_slot(8, { name = "hazard-concrete", quality = "rare" })
        player.set_quick_bar_slot(9, { name = "hazard-concrete", quality = "epic" })
        player.set_quick_bar_slot(10, { name = "hazard-concrete", quality = "legendary" })

        player.set_quick_bar_slot(11, { name = "refined-concrete", quality = "normal" })
        player.set_quick_bar_slot(12, { name = "refined-concrete", quality = "uncommon" })
        player.set_quick_bar_slot(13, { name = "refined-concrete", quality = "rare" })
        player.set_quick_bar_slot(14, { name = "refined-concrete", quality = "epic" })
        player.set_quick_bar_slot(15, { name = "refined-concrete", quality = "legendary" })

        player.set_quick_bar_slot(16, { name = "refined-hazard-concrete", quality = "normal" })
        player.set_quick_bar_slot(17, { name = "refined-hazard-concrete", quality = "uncommon" })
        player.set_quick_bar_slot(18, { name = "refined-hazard-concrete", quality = "rare" })
        player.set_quick_bar_slot(19, { name = "refined-hazard-concrete", quality = "epic" })
        player.set_quick_bar_slot(20, { name = "refined-hazard-concrete", quality = "legendary" })
    end
end)
