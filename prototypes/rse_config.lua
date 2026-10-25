-- prototypes/rse_config.lua
local function make_spoilable(item)
    item.spoil_ticks = 1
    item.quality_affects_spoil_ticks = false
end

---@param q QualityName
---@return string
local function recycle_selector_name(q)
    return "quality_concrete-recycle-from-" .. q
end

--One selector per quality: the recycled item's own tier is baked in, the recycler's roll is event.quality.
--The rolled quality's distance from its chain start is added on top of the item's tier, capped at the end of its chain.
local function make_recycle_selector(q)
    return {
        type = "mod-data",
        name = recycle_selector_name(q),
        data_type = "rse_function",
        data = {
            func = [[
                function(event)
                    local qualities = prototypes.quality
                    local result = qualities["]] .. q .. [["]

                    -- Count the rolled quality's steps back to the start of its own chain,
                    -- so a roll on a different quality chain still adds its distance
                    local steps = 0
                    local rolled = qualities[event.quality or "normal"]
                    -- the step cap guards against modded chains that loop back on themselves
                    while rolled and rolled.previous and steps < 255 do
                        rolled = rolled.previous
                        steps = steps + 1
                    end
                    if steps >= 255 then steps = 0 end

                    for _ = 1, steps do
                        if not result.next then break end
                        result = result.next
                    end

                    return result.name
                end
            ]],
        },
    }
end

---@param naming Naming
---@return nil
return function(ctx, naming)
    for _, q in ipairs(ctx.qualities) do
        data:extend { make_recycle_selector(q) }
    end

    for _, fam in ipairs(ctx.families) do
        local item_name = fam.base_item
        local base_item = data.raw.item[item_name]
        make_spoilable(base_item)

        ---@type table<QualityName, RseResult>
        local rse_results = {}

        for _, q in ipairs(ctx.qualities) do
            rse_results[q] = { name = naming.q_item_name(item_name, q), quality = "normal" }
        end

        --Turns the base game's concrete into custom concrete that respect quality.
        ---@type RseRegistrationData
        local reg_data_concrete = {
            original_item_type = "item",
            original_item_name = item_name,
            placeholder_overrides = {
                icon = base_item.icon,
                localised_name = naming.localised_name_with_quality(ctx, item_name, "normal"),
            },
            placeholder_spoil_into_self = true,
            key_selector = "quality",
            results = rse_results,
        }

        data:extend { {
            type = "mod-data",
            name = "quality_concrete-" .. item_name,
            data_type = "rse_registration",
            data = reg_data_concrete
        } }


        for _, q in ipairs(ctx.qualities) do
            local recycled_placeholder_name = naming.q_recycling_placeholder_name(item_name, q)
            make_spoilable(data.raw.item[recycled_placeholder_name])

            ---@type RseRegistrationData --It turns the recycling placeholder into custom concrete that respect quality.
            local reg_data_concrete_recycle = {
                original_item_type = "item",
                original_item_name = recycled_placeholder_name,
                placeholder_overrides = {
                    icon = base_item.icon,
                    localised_name = naming.localised_name_with_quality(ctx, item_name, q),
                },
                placeholder_spoil_into_self = true,
                key_selector = recycle_selector_name(q),
                results = rse_results,
            }

            data:extend { {
                type = "mod-data",
                name = "quality_concrete-" .. recycled_placeholder_name,
                data_type = "rse_registration",
                data = reg_data_concrete_recycle
            } }
        end
    end
end
