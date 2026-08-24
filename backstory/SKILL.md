## Purpose

Create an ongoing stream of related fiction, **with no AI generation of text**. Backstory tooling may resemble Scrivener, mobile first, based on RDF triples using N3.js and related libraries. Backstory is a mobile app created with the intent of blending Scrivener-like functionality with card-based gameplay. Mobile First, connectionless and serverless, local storage becomes the source of truth, and no AI is used. The game provides simple prompts augmented by sparse templated revelations, and the player provides the bulk of the descriptive elements. The sparse templated set pieces and predefined locations, people and objects becomes very important for setting the scene.

### Scrivener vs. Cardgame

The architecture can be approached from two complementary directions. The Scrivener approach starts with world-building. An author builds on a narrative template to create a Story World containing places, people, things, and other persistent elements before any story is played. A mansion may be populated with rooms, characters, and objects, but many of the relationships between them remain undefined. Episodes are then created as realizations of that world, selecting a subset of places, participants, and revelations. This approach emphasizes authoring, planning, continuity, and reuse. The world exists, and stories emerge from it.

The Roguelike Cardgame approach starts with play. Rather than building a complete world up front, gameplay progressively creates and enriches it. A prompt card may introduce a place, a character, or a revelation, and the player's responses give those elements meaning and detail. New locations, relationships, clues, and backstories emerge through interaction and are retained as part of the persistent world after the session ends. In this model, world-building becomes one of the rewards of gameplay. The world provides possibilities, cards activate those possibilities, gameplay realizes them, and the resulting discoveries flow back into the world. The most compelling vision may be a hybrid of the two: a sparse world created through Scrivener-like authoring, combined with card-driven play that continually expands and deepens that world over time.

### GOLEM

| Scrivener |	Backstory |
|-----------|-----------|
|Story is primary	| World is primary |
| Author writes scenes	| Player realizes scenes |
| Characters serve story |Story reveals characters |
| World supports narrative	| Narrative grows world |
| Static artifact | Persistent evolving artifact |

GOLEM's focus on characters, events, settings, relationships, and narrative inferences maps surprisingly closely to the persistent elements you're accumulating. What I think the core ontology looks like

Story World
 ├─ Places
 ├─ Characters
 ├─ Objects
 ├─ Facts
 ├─ Secrets
 ├─ Relationships
 └─ Potential Events

Episode
 ├─ Active Places
 ├─ Active Characters
 ├─ Drawn Cards
 ├─ Revelations
 └─ Realized Events

The Story World contains persistent entities (the scene). The Episode contains events. Events modify the world. GOLEM provides Narrative as a first-class object. A narrative ontology stores: Character, Location, Item, Event, Relationship, Narrative, InferenceRevelations should be ontology objects

GOLEM is one of the few ontologies that treats narrative as a network of events, actors, settings, and relationships rather than as a text document.

If I were designing Backstory from scratch, I'd probably use GOLEM as the narrative layer, but I'd add a second layer explicitly devoted to uncertainty, revelation, and world evolution, because those seem to be the truly novel mechanics in your design. That's where Backstory starts to become something more like a "persistent fictional knowledge graph game" rather than simply a Scrivener-with-cards.

## scene by scene

Each writer spreadsheets their novel a little different, but from the spreadsheets I’ve looked and used to build my own, they all feature columns dedicated to:

- word count
- setting
- characters in the scene
- scene number
- summary of scene
- problem
- complication
- conclusion
