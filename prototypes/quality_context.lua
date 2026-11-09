-- prototypes/quality_context.lua
local item_sounds = require("__base__.prototypes.item_sounds")
local quality_order = require("__quality_concrete__/prototypes/quality_order")

local quality_data = data.raw.quality or {}

local qualities = quality_order(quality_data)
local quality_offset = {}
local quality_speed_mult = {}
local base_tint = {}

local tints = {
    concrete = {
        normal = { r = 1.0, g = 1.0, b = 1.0, a = 1 },
        uncommon = { r = 0.7, g = 0.9, b = 0.7, a = 1 },
        rare = { r = 0.7, g = 0.8, b = 0.9, a = 1 },
        epic = { r = 0.8, g = 0.6, b = 0.7, a = 1 },
        legendary = { r = 1.0, g = 0.85, b = 0.65, a = 1 },
    },
    hazard = {
        normal = { r = 1.0, g = 1.0, b = 1.0, a = 1 },
        uncommon = { r = 0.6, g = 0.8, b = 0.7, a = 1 },
        rare = { r = 0.7, g = 0.8, b = 0.9, a = 1 },
        epic = { r = 0.7, g = 0.6, b = 1.0, a = 1 },
        legendary = { r = 1.0, g = 0.85, b = 0.65, a = 1 },
    },
}

for name, tier in pairs(quality_data) do
    quality_speed_mult[name] = 1 + (tier.level or 0) * 0.20
    base_tint[name] = tier.color
end

-- Each tier takes two tile layers, its own and the one above for its frozen variant: offsets 0, 2, 4, ...
for i, name in ipairs(qualities) do
    quality_offset[name] = (i - 1) * 2
end

return {
    qualities = qualities,
    quality_offset = quality_offset,
    -- Tile layers one family's tiers span; families are stacked in blocks of this size
    family_layer_span = #qualities * 2,
    quality_speed_mult = quality_speed_mult,

    tints = tints,
    base_tint = base_tint,

    families = require("__quality_concrete__/prototypes/families"),
    item_sounds = item_sounds,
}
