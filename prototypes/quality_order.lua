-- prototypes/quality_order.lua
-- Quality names ordered by level, then by name. Takes data.raw.quality or the runtime prototypes.quality,
-- so the data stage and control.lua agree on the order of qualities that share a level.
return function(quality_prototypes)
    local names = {}
    for name in pairs(quality_prototypes) do
        if name ~= "quality-unknown" then names[#names + 1] = name end
    end
    table.sort(names, function(a, b)
        local la, lb = quality_prototypes[a].level or 0, quality_prototypes[b].level or 0
        if la ~= lb then return la < lb end
        return a < b
    end)
    return names
end
