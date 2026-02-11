-- data.lua
local ctx = require("__quality_concrete__/prototypes/quality_context")

local naming = require("__quality_concrete__/prototypes/naming")
local items_mod = require("__quality_concrete__/prototypes/items")
local tiles_mod = require("__quality_concrete__/prototypes/tiles")

require("__quality_concrete__/prototypes/generate")(ctx, naming, items_mod, tiles_mod)
require("__quality_concrete__/prototypes/recipes")(ctx, naming)
require("__quality_concrete__/prototypes/rsl_config")(ctx, naming)

