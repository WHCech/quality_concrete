-- control.lua
-- Quality Concrete



local TILE_FAMILIES = {
    { base = "concrete-quality-" },
    { base = "hazard-concrete-left-quality-" },
    { base = "refined-concrete-quality-" },
    { base = "refined-hazard-concrete-left-quality-" },
}

local TILE_SIZE = 3 -- 3x3 blocks
local GAP = 1       -- space between blocks
local CELL = TILE_SIZE + GAP

local function debug_enabled()
    return settings.global["debug-spawn-all-tiles"]
        and settings.global["debug-spawn-all-tiles"].value == true
end

local function sorted_qualities()
    local q = {}

    for name, proto in pairs(prototypes.quality or {}) do
        if name ~= "quality-unknown" then
            q[#q + 1] = { name = name, level = proto.level or 0 }
        end
    end

    table.sort(q, function(a, b)
        if a.level ~= b.level then return a.level < b.level end
        return a.name < b.name
    end)

    local out = {}
    for i = 1, #q do out[i] = q[i].name end
    return out
end

local function set_block(surface, x, y, tile)
    local tiles = {}

    for dx = 0, TILE_SIZE - 1 do
        for dy = 0, TILE_SIZE - 1 do
            tiles[#tiles + 1] = { name = tile, position = { x + dx, y + dy } }
        end
    end

    surface.set_tiles(tiles, true, true, true)
end

local function place_grid(player)
    local surface   = player.surface
    local qualities = sorted_qualities()

    local cols      = #TILE_FAMILIES
    local rows      = #qualities

    local width     = cols * CELL - GAP
    local height    = rows * CELL - GAP

    local start_x   = math.floor(player.position.x - width / 2)
    local start_y   = math.floor(player.position.y - height / 2)

    for col, fam in ipairs(TILE_FAMILIES) do
        local x = start_x + (col - 1) * CELL

        for row, q in ipairs(qualities) do
            local y = start_y + (row - 1) * CELL
            local tile_name = fam.base .. q

            if prototypes.tile[tile_name] then
                set_block(surface, x, y, tile_name)
            else
                log("QC\tmissing tile\t" .. tile_name)
            end
        end
    end

    player.print("QC: spawned preview grid (debug-spawn-all-tiles).")
end

script.on_event(defines.events.on_player_created, function(e)
    if not debug_enabled() then return end
    if storage.qc_grid_done then return end
    storage.qc_grid_done = true

    local player = game.get_player(e.player_index)
    if player then
        place_grid(player)
    end
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(e)
    if e.setting ~= "debug-spawn-all-tiles" then return end
    if not debug_enabled() then return end
    if storage.qc_grid_done then return end

    local player = game.get_player(e.player_index) or game.get_player(1)
    if player then
        storage.qc_grid_done = true
        place_grid(player)
    end
end)
