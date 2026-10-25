-- prototypes/families.lua
-- Plain data, no data.raw access, so both the data stage and control.lua can require it.
return {
    { base_item = "concrete",                base_tiles = { "concrete" } },
    { base_item = "refined-concrete",        base_tiles = { "refined-concrete" } },
    { base_item = "hazard-concrete",         base_tiles = { "hazard-concrete-left", "hazard-concrete-right" } },
    { base_item = "refined-hazard-concrete", base_tiles = { "refined-hazard-concrete-left", "refined-hazard-concrete-right" } },
}
