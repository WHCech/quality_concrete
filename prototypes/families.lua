-- prototypes/families.lua
-- Plain data, no data.raw access, so both the data stage and control.lua can require it.
--  base_tiles  the base game tiles of the family; two tiles are a left/right pair that rotate into each other
--  layer_slot  which block of tile layers the family's tiers use, so tiers of one family never overlap another's
--  tint        which tint table of quality_context colours the tiles
--  merges_with the family whose tiles of the same tier this one blends into, also for its frozen variant
return {
    { base_item = "concrete",                base_tiles = { "concrete" },
      layer_slot = 0, tint = "concrete", merges_with = "concrete" },
    { base_item = "refined-concrete",        base_tiles = { "refined-concrete" },
      layer_slot = 2, tint = "concrete", merges_with = "refined-concrete" },
    { base_item = "hazard-concrete",         base_tiles = { "hazard-concrete-left", "hazard-concrete-right" },
      layer_slot = 1, tint = "hazard",   merges_with = "concrete" },
    { base_item = "refined-hazard-concrete", base_tiles = { "refined-hazard-concrete-left", "refined-hazard-concrete-right" },
      layer_slot = 3, tint = "hazard",   merges_with = "refined-concrete" },
}
