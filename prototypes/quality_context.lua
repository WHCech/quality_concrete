-- prototypes/quality_context.lua
local item_sounds = require("__base__.prototypes.item_sounds")

local quality_data = data.raw.quality or {}

local qualities = {}
local quality_offset = {}
local quality_speed_mult = {}
local base_tint = {}

local concrete_tint = {
    normal = { r = 1.0, g = 1.0, b = 1.0, a = 1 },
    uncommon = { r = 0.7, g = 0.9, b = 0.7, a = 1 },
    rare = { r = 0.7, g = 0.8, b = 0.9, a = 1 },
    epic = { r = 0.8, g = 0.6, b = 0.7, a = 1 },
    legendary = { r = 1.0, g = 0.85, b = 0.65, a = 1 },
}

local hazard_tint = {
    normal = { r = 1.0, g = 1.0, b = 1.0, a = 1 },
    uncommon = { r = 0.6, g = 0.8, b = 0.7, a = 1 },
    rare = { r = 0.7, g = 0.8, b = 0.9, a = 1 },
    epic = { r = 0.7, g = 0.6, b = 1.0, a = 1 },
    legendary = { r = 1.0, g = 0.85, b = 0.65, a = 1 },
}

for name, tier in pairs(quality_data) do
    local level = (tier.level or 0)

    quality_speed_mult[name] = 1 + level * 0.20
    base_tint[name] = tier.color
    if name ~= "quality-unknown" then
        qualities[#qualities + 1] = name
    end
end

table.sort(qualities, function(a, b)
    return (quality_data[a] and quality_data[a].level or 0) < (quality_data[b] and quality_data[b].level or 0)
end)

-- Assign offsets by sorted index: 0,2,4,6,...
for i, name in ipairs(qualities) do
    quality_offset[name] = (i - 1) * 2
end

return {
    qualities = qualities,
    quality_offset = quality_offset,
    quality_speed_mult = quality_speed_mult,

    concrete_tint = concrete_tint,
    hazard_tint = hazard_tint,
    base_tint = base_tint,

    families = require("__quality_concrete__/prototypes/families"),
    item_sounds = item_sounds,
}
