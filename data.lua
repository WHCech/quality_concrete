-- data.lua
-- Hidden inputs that fire alongside the game's quality cycling, so control.lua can swap the cursor item.
data:extend({
    {
        type = "custom-input",
        name = "quality_concrete-cycle-quality-up",
        key_sequence = "",
        linked_game_control = "cycle-quality-up",
    },
    {
        type = "custom-input",
        name = "quality_concrete-cycle-quality-down",
        key_sequence = "",
        linked_game_control = "cycle-quality-down",
    },
})
