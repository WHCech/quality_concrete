# Quality Concrete

Adds **quality tiers** to concrete tiles, adjusting movement speed bonuses and colors.

Due to the way this is implemented, concrete is removed from recipes and replaced with stone bricks.

Since version 1.0.0 (Factorio 2.1) Runtime Spoilage Library is no longer required.

---

## Features

Quality variants for:

* Concrete
* Refined concrete
* Hazard concrete
* Refined hazard concrete

Movement speed bonus scales with quality tier.  
Works with blueprints.

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

* Items, tiles and recipes are generated in `data-updates.lua`; recipes that make concrete are patched in `data-final-fixes.lua`.
* If your mod adds quality tiers, ensure they are defined before `data-updates.lua`.
* Incompatible with mods that increase the total tile prototype count beyond 255.

Special thanks to SirPuck for the help and for Runtime Spoilage Library, which earlier versions used.
