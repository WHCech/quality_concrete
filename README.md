# Quality Concrete

Adds **quality tiers** to concrete tiles, adjusting movement speed bonuses and colors.

Due to the way this is implemented, concrete is removed from recipes and replaced with stone bricks.

Requires [Runtime Spoilage Engine](https://mods.factorio.com/mod/runtime-spoilage-engine). Since version 1.0.0 (Factorio 2.1) it replaces Runtime Spoilage Library, which is no longer needed and is incompatible.

---

## Features

Quality variants for:

* Concrete
* Refined concrete
* Hazard concrete
* Refined hazard concrete

Movement speed bonus scales with quality tier
Works with Blueprints

---

## Compatibility

Works with most mods that add additional quality tiers.  
Tested and compatible with:

* Additional-Qualities
* ArtifactQuality
* end-game-mythic-quality
* Inverted-Quality
* morequality
* prismatic-quality
* Quality-Plus-Plus
* Quality-Plus-Plus-Shiny-Mechanics
* QualityPlus

---

## Load behavior

* Prototype generation runs in `data-updates.lua`
* If your mod adds quality tiers, ensure they are defined before this stage.
* Incompatible with mods that increase the total tile prototype count beyond 255.  
Special thanks to SirPuck for the help and for creating the Runtime Spoilage Engine.
