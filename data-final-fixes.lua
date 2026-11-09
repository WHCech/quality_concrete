-- data-final-fixes.lua
-- Runs last so recipes other mods add for concrete are patched too
local ctx = require("__quality_concrete__/prototypes/quality_context")

require("__quality_concrete__/prototypes/craft_conversion")(ctx)
