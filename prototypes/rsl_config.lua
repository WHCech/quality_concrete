-- prototypes/rsl_onfig.lua
---@param naming Naming
---@return nil
return function(ctx, naming)
    for _, fam in ipairs(ctx.families) do
        local item_name = fam.base_item
        local base_item = data.raw.item[item_name]
        base_item.spoil_ticks = 1
        local rsl_results = {}

        for _, q in ipairs(ctx.qualities) do
            local costom_concrete_name = naming.q_item_name(item_name, q)
            rsl_results[q] = { name = costom_concrete_name, quality = "normal" }
        end

        --Turns the base game's concrete into custom concrete that respect quality.
        ---@type RslRegistrationData
        local reg_data_concrete = {
            original_item_type = "item",
            original_item_name = item_name,
            placeholder_overrides = {                                                          ---?
                icon = base_item.icon,                                                         ---? string,
                localised_name = naming.localised_name_with_quality(ctx, item_name, "normal"), ---? LocalisedString,
            },
            loop_spoil_safe_mode = true,
            random = false,
            conditional = true,
            condition_checker_func_name = "spoil_by_quality",
            condition_checker_func = [[
                function(event)
                    local e = event.quality
                    return e or "normal"
                end
            ]],
            conditional_results = rsl_results,
        }

        local my_rsl_registration_concrete = {
            type = "mod-data",
            name = "rsl_" .. item_name,
            data_type = "rsl_registration",
            data = reg_data_concrete
        }

        data:extend { my_rsl_registration_concrete }


        for _, q in ipairs(ctx.qualities) do
            local recycled_placeholder_name = naming.q_recycling_placeholder_name(item_name, q)
            local recycled_placeholder_local_name = naming.localised_name_with_quality(ctx, item_name, q)
            data.raw.item[recycled_placeholder_name].spoil_ticks = 1


            ---@type RslRegistrationData --It turns the recycling placeholder into custom concrete that respect quality.
            local reg_data_concrete_recycle = {
                original_item_type = "item",
                original_item_name = recycled_placeholder_name,
                placeholder_overrides = {                                                      ---?
                    icon = base_item.icon,                                                     ---? string,
                    localised_name = recycled_placeholder_local_name, ---? LocalisedString,
                },
                loop_spoil_safe_mode = true,
                random = false,
                conditional = true,
                condition_checker_func_name = "find_quality_after_recycle",
                condition_checker_func = [[
                function(event)
                    -- Build ordered qualities from prototypes.quality
                    local qdata = prototypes.quality or {}

                    local qualities = {}

                    for name, proto in pairs(qdata) do
                        if name ~= "quality-unknown" then
                            qualities[#qualities + 1] = {
                                name = name,
                                level = proto.level or 0
                            }
                        end
                    end

                    table.sort(qualities, function(a, b)
                        return a.level < b.level
                    end)

                    -- build index lookup
                    local q_index = {}
                    for i, q in ipairs(qualities) do
                        q_index[q.name] = i
                    end

                    -- event quality
                    local eq          = event.quality or "normal"

                    -- item name from stack
                    local item_name   = event.effect_id or event.item

                    -- extract suffix quality
                    local item_q      = item_name:match("^recycled%-.-%-([%a_]+)%-") or "normal"

                    -- add levels
                    local item_level  = (q_index[item_q] or 1) - 1
                    local event_level = (q_index[eq] or 1) - 1

                    local max_level   = #qualities - 1
                    local out_level   = item_level + event_level

                    if out_level > max_level then
                        out_level = max_level
                    end

                    -- return resulting quality string
                    return qualities[out_level + 1].name or "normal"
                end
                ]],
                conditional_results = rsl_results,
            }

            local my_rsl_registration_concrete_recycle = {
                type = "mod-data",
                name = "rsl_" .. recycled_placeholder_name,
                data_type = "rsl_registration",
                data = reg_data_concrete_recycle
            }

            data:extend { my_rsl_registration_concrete_recycle }
        end
    end
end
