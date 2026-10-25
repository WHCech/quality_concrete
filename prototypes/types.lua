---@class RseResult
---@field name string Item to spoil into.
---@field quality? string Explicit output quality; omit to preserve the spoiled item's quality.
---@field weight? integer Positive relative probability in a random result array.

---@class RsePlaceholderOverrides
---@field icon? string
---@field icons? table[]
---@field localised_name? LocalisedString
---@field localised_description? LocalisedString

---@class RseRegistrationData
---@field original_item_type string Usually "item".
---@field original_item_name string Existing spoilable prototype name. RSE does not add spoil_ticks.
---@field results RseResult|RseResult[]|table<string, RseResult|RseResult[]>
---@field key_selector? string "quality" or the name of an rse_function mod-data prototype.
---@field items_per_trigger? integer Advanced; defaults to the original stack size.
---@field placeholder_spoil_into_self? boolean Defaults to true.
---@field fallback_spoilage? string Used when placeholder_spoil_into_self is false.
---@field additional_trigger? table
---@field placeholder_overrides? RsePlaceholderOverrides


---@alias QualityName
---| "normal"
---| "uncommon"
---| "rare"
---| "epic"
---| "legendary"
---| string

---@alias ItemName string