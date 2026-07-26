# Dragonbound Gen 1 Roster — "The Kindra Compact"

**Status: DRAFT for Alex's red-pen. Nothing here is generated into the game yet.**

## Design law

1. **Type is visible at a squint.** Every type owns an animal family. If you can't
   tell a creature's type from its silhouette, the design is wrong.
2. **Dragons are the apex, not the default.** Almost everything you catch is a
   *drake* — a creature carrying a spark of dragon blood. **True dragons** are rare,
   late-game, and story-central. The first true dragon most players ever own is
   their own starter's final evolution.
3. **Legendaries are cryptids, not dragons.** Six one-off myths, one per rare type
   (void / celestial / ancient / spirit / crystal / blood). The things older than
   dragons.

## Type → animal family map (Gen 1: 7 common types + 6 rare)

| Type | Family | Silhouette language |
|---|---|---|
| fire | salamanders, hounds, toads, foxes | pointed ears, flame tails, warm reds/oranges |
| water | fish, eels, amphibians, river mammals | fins, whiskers, blues/teals, droplet shapes |
| nature | bugs, plants, hares | leaves-as-armor, antennae, greens |
| earth | moles, tortoises, golems | domes, plates, browns/tans, stubby |
| wind | birds, bats | wings obviously, sleek, whites/greys |
| lightning | rodents, cats | jagged fur, bolt markings, yellows |
| normal | scrappy mammals | round, plain-colored, friendly |
| *rare ×6* | *cryptids (legendary one-offs)* | *unmistakable, one each* |

Proposed chart additions (current fire/water/nature triangle keeps working;
**needs a simulation pass before shipping**):
earth 2× vs fire+lightning · lightning 2× vs water+wind · wind 2× vs nature ·
water 2× vs earth · nature 2× vs earth · wind 0.5× from earth · normal always 1×.
Rare types: 1.25× vs all common types, resist common 0.75× (postgame math, TBD).

## Availability tiers

- **T1** — Kindra / Dustway / Scald (the live game)
- **T2** — badges 1–3 (north-gate zones)
- **T3** — badges 4–6 (starters hit stage 3 here; first wild true-dragon sightings)
- **T4** — badges 7–8 / the League equivalent
- **LGD** — fixed one-off encounters; some are Gen-2 hooks

---

## Starters (the dragon-reveal arc) — 9 species

Stages 1–2 read as ANIMALS. Stage 3 is the game's first obtainable TRUE DRAGON.

| Line | Stages (evo levels) | Identity arc |
|---|---|---|
| fire | **Ember → Scornn (16) → Ashvane (36)** | fire-pup with smoldering fur → horned ash-hound, embers in mane → crimson true dragon, wings unfurl |
| water | **Ripple → Undertow (16) → Tidewrath (36)** | river axolotl, frill gills → torrent eel-hound → leviathan true dragon, tidal crest |
| nature | **Sprig → Thicket (16) → Ironbark (36)** | leaf beetle, seed-pod shell → bramble stag-beetle → bark-plated true dragon, antler crown |

*(IDs unchanged — this is a re-skin + re-description of existing data, no migration.)*

## Common roster — 35 species

### Fire
- **Flick → Flint (14)** — cinder mouse → flint-backed rat that sparks when startled. T1. *(existing Flick gains an evolution)*
- **Cinderpad → Magmaw (22)** — ember-gulping toad → lava-jawed bull toad. T1 (Scald) / T2.

### Water
- **Gulp → Gorge (16)** — pond gulper tadpole → bucket-mouthed river fish. T1. *(existing Gulp gains an evolution)*
- **Finlet → Marlance (24)** — darting minnow → lance-billed marlin, fastest swimmer in Gen 1. T2/T3.

### Nature
- **Tuft → Bramblet (15)** — leaf-tailed hare → thorn-coated jackrabbit. T1. *(existing Tuft gains an evolution)*
- **Larvine → Chryspin (7) → Mantevine (10)** — vine grub → hanging chrysalis → elegant mantis. The classic early bug: trivially caught, evolves absurdly fast, mid-game ceiling. T1.

### Earth
- **Molehm → Bouldenn (18)** — velvet mole with stone claws → boulder-backed digger. T2.
- **Shellon → Tarrapex (26)** — pebble tortoise → walking land-fortress, highest DEF in Gen 1. T2/T3.

### Wind
- **Peeper → Galewing (12) → Sirocco (28)** — dust sparrow → gale hawk → heat-storm raptor. The "route bird," on every route from T1.
- **Flitter → Gustbat (16)** — cave pip bat → twin-fanned gust bat. T1 (add to Scald encounter table!).

### Lightning
- **Zappup → Volthound (20)** — static-furred pup → storm hound, bolt-shaped blaze. T2.
- **Skitt → Ampurr (19)** — spark kitten → charged lynx, whiskers arc when it purrs. T2.

### Normal
- **Scamp → Rampant (17)** — scrappy plains pup → charging tusked beast. T1/T2.
- **Snoot** — round dust-puffball. Never evolves. Catch rate 200, XP piñata, beloved. T1.

## True dragons (wild) — 6 species, late-game apex

Gated hard: these do not spawn before the listed tier. Seeing one should be an event.

- **Stormaw → Tempestrix (44)** — wind/lightning storm dragon; crackling thunderhead mane. T3 mountain peaks, rare.
- **Terradon → Gaiawyrm (46)** — earth dragon; canyon-carver, tectonic plates for scales. T4.
- **Cindrake → Pyrevern (45)** — fire true dragon of the deep Scald; returns to the first dungeon post-badge-8 (the Scald has a locked lower level — nice bookend). T4.

## Legendary cryptids — 6 one-offs (rare types, NOT dragons)

One fixed encounter each. No evolutions. Each carries a signature mechanic.

| Name | Type | Myth | Encounter & mechanic |
|---|---|---|---|
| **Nessyra** | water/ancient | Loch Ness | Fog event on a still lake, T3. *Elder Sight:* reveals enemy moves. |
| **Krakenos** | water/void | Kraken | Sea trench, postgame / Gen-2 hook. *Hundred Grips:* traps + drains. |
| **Solyre** | fire/celestial | Phoenix | Crater shrine at dawn, T4. *Rekindle:* self-revives once per battle. |
| **Mothrenn** | wind/spirit | Mothman | Night-only omen on a bridge, T3. *Portent:* dodges the first hit of every battle. |
| **Rimehorn** | earth/crystal | Yeti | Blizzard summit, T4. *Glacier Hide:* damage taken is delayed one turn. |
| **Basilith** | nature/blood | Basilisk | Sealed vault beneath a ruin, T4. *Stone Gaze:* chance to skip enemy turns. |

## Class taxonomy (feeds bench synergy — the flagship system)

`class` field values: `beast, bug, fish, avian, shell, elemental, true_dragon, legend`.
Synergy hooks this unlocks (examples, to design later): 3 bugs = swarm (crit up),
3 fish = current (speed up), 2 avian = tailwind (flee/first-strike), any legend =
aura. True dragons intentionally have NO 3-of-a-kind bonus — you can't hoard apexes.

## Rollout plan (after red-pen)

1. **Wave 1 (no new zones needed):** re-describe the existing 12 species to their
   animal identities; regenerate their battle sprites; add the 3 fodder evolutions
   (Flint, Gorge, Bramblet); add Flitter/Gustbat to the Scald and Peeper to Dustway.
2. **Wave 2:** extend the type chart to 7 common types + moves for each; simulate
   balance before shipping.
3. **Wave 3:** T2 zones through the north gate arrive with their native species.
4. **Wave 4:** true dragons + first legendary event (Nessyra's lake).

**Count: 56 species** — 9 starter-line, 35 common, 6 wild true dragons, 6 legendaries.
