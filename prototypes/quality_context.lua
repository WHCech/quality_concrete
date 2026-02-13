-- prototypes/quality_context.lua
local item_sounds = require("__base__.prototypes.item_sounds")

local quality_data = data.raw.quality or {}
log("QC: qualities:\n" .. serpent.line(quality_data))

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

local families = {
    { base_item = "concrete",                base_tiles = { "concrete" } },
    { base_item = "refined-concrete",        base_tiles = { "refined-concrete" } },
    { base_item = "hazard-concrete",         base_tiles = { "hazard-concrete-left", "hazard-concrete-right" } },
    { base_item = "refined-hazard-concrete", base_tiles = { "refined-hazard-concrete-left", "refined-hazard-concrete-right" } },
}

local function collect_quality_unlock_data()
    local tech_to_quality_pairs = {}
    local quality_to_techs = {}

    for tech_name, tech in pairs(data.raw.technology or {}) do
        local unlocked = {}

        for _, effect in ipairs(tech.effects or {}) do
            if effect.type == "unlock-quality" and effect.quality then
                unlocked[#unlocked + 1] = effect.quality

                local tlist = quality_to_techs[effect.quality]
                if not tlist then
                    tlist = {}
                    quality_to_techs[effect.quality] = tlist
                end
                tlist[#tlist + 1] = tech_name
            end
        end

        if #unlocked > 0 then
            tech_to_quality_pairs[#tech_to_quality_pairs + 1] = {
                technology_name = tech_name,
                qualities = unlocked
            }
        end
    end

    return tech_to_quality_pairs, quality_to_techs
end

local tech_to_quality, quality_to_tech = collect_quality_unlock_data()

return {
    quality_data = quality_data,
    qualities = qualities,
    quality_offset = quality_offset,
    quality_speed_mult = quality_speed_mult,

    concrete_tint = concrete_tint,
    hazard_tint = hazard_tint,
    base_tint = base_tint,

    families = families,
    item_sounds = item_sounds,
    tech_to_quality = tech_to_quality,
    quality_to_tech = quality_to_tech
}
