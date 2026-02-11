---@alias RslItemName string
---@alias RslConditionResult string

---@class RslRandomResult
---@field name RslItemName
---@field weight? number Optional. If omitted, all results are equally weighted.

---@alias RslRandomResults RslRandomResult[] Example: {{name="iron-plate"}, {name="copper-plate"}} or {{name="iron-plate", weight = 1}, {name="copper-plate", weight = 3}}
---@alias RslConditionalRandomResults table<RslConditionResult, RslRandomResults> Example: { ["day"] = {{name="ice", weight=10}, {name = "stone", weight=1}} }
---@alias RslConditionalResults table<RslConditionResult, {name: RslItemName}> Example: { ["night"] = "sunflower" }

---@class RslRegistrationData
---@field original_item_type string item, module etc... The value of the `type` field in the original prototype definition.
---@field original_item_name string The name of the item that will spoil.
---@field items_per_trigger? integer Optional. Number of items required to trigger spoilage.
---@field fallback_spoilage? string Optional. Item name used if no spoilage result is determined only works if loop_spoil_safe_mode is explicitly set to false.
---@field loop_spoil_safe_mode boolean If true, the item spoils into itself if no result is available.
---@field additional_trigger? table Optional. Additional trigger conditions.
---@field random boolean If true, spoilage is chosen randomly.
---@field conditional boolean If true, spoilage depends on a condition function.
---@field condition_checker_func_name? string Name of the condition function used.
---@field condition_checker_func? string the function to check the condition
---@field random_results? RslRandomResults
---@field conditional_random_results? RslConditionalRandomResults
---@field conditional_results? RslConditionalResults


---@alias QualityName
---| "normal"
---| "uncommon"
---| "rare"
---| "epic"
---| "legendary"
---| string

---@alias ItemName string