Difficulty Mod for Pokemon Rejuvenation v13.5

# Instructions
- Please make sure you have the correct version before proceeding
- Rename your old Scripts folder to something else (e.g. Scripts-Old)
- Copy this folder into the same directory

# Changelog (8/25/24)
## General
  - Aqua Ring
    - also cures the user's status at the end of each turn
  - Hail
    - grants ice types a x1.5 defense boost
  - Frostbite
    - halves special attack of afflicted pokemon
    - takes 1/16th of max HP in damage at the end of each turn
    - ice types are immune

## Pokemon
  - Meganium
    - added Fairy typing
  - Serperior
    - added Dragon typing
    - can learn Draco Meteor
  - Goodra line
    - added Poison Heal as ability for Goomy, Sliggoo, and Goodra
    - added Regenerator as ability for Sliggoo (Hisui) and Goodra (Hisui)
  - Mamoswine Line
    - added Ice Body as ability for Swinub and Piloswine
    - added Slush Rush as ability for Mamoswine
  - Volcarona Line
    - added Flash Fire as ability for Larvesta and Volcarona
    - added Run Away and Gale Wings asa bility for Larvesta (Aevian) and Volcarona (Aevian)

## Attacks

### Updates
- SUPER UMD ATTACK
  - Reverted to v13 (randomly choosing between hammer and cannon instead of alternating)
- Fling
  - Fling Big Nugget for Lord Emvee
- Attract
  - No longer checks gender (Free Cryogonal!)
- Captivate
  - No longer checks gender
- Psycho Cut
  - Hits the target's special defense stat
- X Scissor
  - HCR
- Night Daze
  - BP 85 -> 95
  - acc 95 -> 100
  - effect chance 40 -> 50
- Dark Void
  - acc 50 -> 80
- Quash
  - prio +1
- Roar of Time
  - BP 150 -> 180
- Dragon Rush
  - acc 75 -> 85
  - effect 20 -> 40
- Spacial Rend
  - acc 95 -> 0
  - hits through protect + substitute
  - clears screens + entry hazards
  - TODO: clear weather, terrain, room
- Corrosive Gas
  - 50 BP
  - Poison
  - Special
  - All Foes
  - Corrodes their Items
  - 

### New Attacks
- Sleigh Ride
  - 70 BP
  - Ice
  - Physical
  - Single Target
  - +1 Priority in Hail
-

## Abilities

### Updates
- Gale Wings
  - Reverting Nerf
- Parental Bond
  - Reverting Nerf
- Pastel Veil
  - Protects all allies from Poison type attacks
  -   
 
### New Abilities

## Items

### Updates
- Meganium Crest
  - Heals ALL friendly pokemon (including party pokemon) at the end of each turn
  - extends screens by 3 turns

### New Items
- Poison Potion
  - new item, applies (regular) poison to the target

# TODO:
- Incomplete Implementation:
  - Gastrodon Crest
- Massive AI overhaul: integrate everything above EXCEPT the following:
  - Gastrodon Crest Attempt
  - Gale Wings nerf revert
  - Parental Bond nerf revert
  - Aqua Ring Buff
  - Hail Buff
  - Attract + Captivate Buff
  - Lite Frostbite logic (recognizes it as a status condition)
