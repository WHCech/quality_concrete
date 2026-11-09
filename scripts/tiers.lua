-- scripts/tiers.lua
-- Runtime helpers for the tier items (concrete-rare and so on), shared by control.lua and migrations.
local FAMILIES = require("__quality_concrete__/prototypes/families")

local M = {}

local item_tiers -- item name -> { family = ..., tier = quality name }

---@return table<string, { family: string, tier: string }>
function M.item_tiers()
    if item_tiers then return item_tiers end
    item_tiers = {}
    for _, fam in ipairs(FAMILIES) do
        for q in pairs(prototypes.quality) do
            local name = fam.base_item .. "-" .. q
            if prototypes.item[name] then
                item_tiers[name] = { family = fam.base_item, tier = q }
            end
        end
    end
    return item_tiers
end

-- Number of steps from the start of the quality's own chain (normal = 0, rare = 2).
-- Counted per chain so a roll on a modded chain still adds its distance.
function M.chain_position(quality)
    local proto = prototypes.quality[quality]
    local steps = 0
    -- the cap guards against a modded chain that loops back on itself
    while proto and proto.previous and steps < 255 do
        proto = proto.previous
        steps = steps + 1
    end
    if steps >= 255 then return 0 end
    return steps
end

-- Moves a tier up by a number of steps, stopping at the end of its chain
function M.raise_tier(tier, steps)
    local proto = prototypes.quality[tier]
    for _ = 1, steps do
        if not proto.next then break end
        proto = proto.next
    end
    return proto.name
end

return M
