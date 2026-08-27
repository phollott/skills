---
id: mech.rust-brawler
type: game:Mech

tags:
  - training
  - salvage
  - brawler

queries:
  - available-moves
  - attack-moves
  - block-moves
  - channel-moves
---

# Rust Brawler

A scrappy training mech cobbled together from salvaged parts.

What it lacks in sophistication, it makes up for in tenacity.

## Narrative

Originally assembled from discarded battlefield components and maintenance-yard scrap, Rust Brawler was never intended to survive real combat. Through constant repairs and improvised upgrades it has gained a reputation for stubborn resilience.

## Moves

### Scrap Slam

**Type:** Attack

**Description**

@fighter winds up a crude but powerful swing aimed at @opponent!

**Outcome**

@fighter's crude but powerful swing connects with @opponent!

**Power Level:** 2

---

### Junk Shield

**Type:** Block

**Description**

@fighter raises makeshift armor plating to block @opponent's attack!

**Outcome**

@fighter's makeshift armor deflects @opponent's strike!

**Power Level:** 2

---

### Spark Charge

**Type:** Channel

**Description**

@fighter's exposed wiring crackles as power builds up!

**Outcome**

@fighter's exposed wiring crackles as power builds up!

**Power Level:** 1

---

### Basic Strike

**Type:** Attack

**Description**

@fighter swings a heavy fist at @opponent!

**Outcome**

@fighter's fist connects with @opponent!

**Power Level:** 2

---

### Quick Jab

**Type:** Attack

**Description**

@fighter throws a quick punch at @opponent!

**Outcome**

@fighter's quick jab catches @opponent off guard!

**Power Level:** 3

---

### Standard Guard

**Type:** Block

**Description**

@fighter raises arms to block @opponent's attack!

**Outcome**

@fighter's guard holds against @opponent's assault!

**Power Level:** 2

## RDF

```turtle
@prefix game: <https://example.org/game#> .
@prefix mech: <https://example.org/mech#> .

mech:rust-brawler
    a game:Mech ;
    game:name "Rust Brawler" ;
    game:description "A scrappy training mech cobbled together from salvaged parts. What it lacks in sophistication, it makes up for in tenacity." .

mech:rust-brawler game:containsMove [
    a game:AttackMove ;
    game:id "m001-scrap-slam-0001" ;
    game:name "Scrap Slam" ;
    game:powerLevel 2 ;
    game:type "Attack"
] .

mech:rust-brawler game:containsMove [
    a game:BlockMove ;
    game:id "m002-junk-shield-0001" ;
    game:name "Junk Shield" ;
    game:powerLevel 2 ;
    game:type "Block"
] .

mech:rust-brawler game:containsMove [
    a game:ChannelMove ;
    game:id "m003-spark-charge-0001" ;
    game:name "Spark Charge" ;
    game:powerLevel 1 ;
    game:type "Channel"
] .

mech:rust-brawler game:containsMove [
    a game:AttackMove ;
    game:id "m100-basic-strike-0001" ;
    game:name "Basic Strike" ;
    game:powerLevel 2 ;
    game:type "Attack"
] .

mech:rust-brawler game:containsMove [
    a game:AttackMove ;
    game:id "m101-quick-jab-0001" ;
    game:name "Quick Jab" ;
    game:powerLevel 3 ;
    game:type "Attack"
] .

mech:rust-brawler game:containsMove [
    a game:BlockMove ;
    game:id "m102-standard-guard-0001" ;
    game:name "Standard Guard" ;
    game:powerLevel 2 ;
    game:type "Block"
] .
```
