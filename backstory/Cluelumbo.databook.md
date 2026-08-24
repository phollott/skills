---
id: cluelumbo-hga-golem
title: Cluelumbo
subtitle: A HOLON Graph Architecture and GOLEM Narrative Ontology Example
type: databook
status: draft

author:
  name: Piers Hollott

keywords:
  - HOLON
  - GOLEM
  - Narrative Ontology
  - Knowledge Graph
  - Columbo
  - Clue
  - Fan Fiction
  - RDF
  - TriG
  - Event Sourcing
  - Projection

summary: >
  Cluelumbo is a narrative knowledge-graph game in which card reveals
  progressively collapse a space of fictional possibilities into a
  canonical Columbo-style episode, represented as GOLEM narrative
  entities and persisted as a HOLON world graph.

ontology:
  primary:
    - HOLON
    - GOLEM

graphs:
  - BoundaryGraph
  - SceneGraph
  - EventGraph
  - ProjectionGraph

concepts:
  - Boundary
  - Scene
  - Event
  - Projection
  - Agent
  - Character
  - Setting
  - Object
  - Narrative
  - Inference

principles:
  - Persist narrative reality rather than gameplay mechanics
  - Cards select possibilities but are not persisted
  - Events are ordered but not necessarily causal
  - Agents provide perspective over the world state
  - Episodes are projections over event history
  - World state evolves through event accumulation

architecture:
  boundary:
    purpose: Defines narrative constraints and episode templates

  scene:
    purpose: Represents the current world state

  event:
    purpose: Records canonical episode history

  projection:
    purpose: Produces contextual narrative views

agent_model:
  holon:Agent:
    subclassOf: golem:Character
    capabilities:
      - possesses
      - observes
      - suspects
      - remembers
      - infers

projection_examples:
  - Episode View
  - Detective Notebook
  - Evidence Inventory
  - Suspect Board
  - Timeline
  - Case Summary

design_statement: >
  The Scene Graph contains the current world, the Event Graph records
  what happened, the Projection Graph determines how that history is
  viewed, and the Boundary Graph constrains what kinds of stories may
  emerge.

formulae:
  - "Episode = Projection(EventGraph)"
  - "Template = BoundaryGraph + SceneGraph"
  - "CanonicalWorld = SceneGraph + EventGraph"

# Cluelumbo Basics

Cluelumbo is a narrative knowledge-graph game in which card reveals progressively collapse a space of fictional possibilities into a canonical Columbo-style episode, represented as GOLEM narrative entities and persisted as a HOLON world graph.

Cluelumbo is emerging as a HOLON Graph Architecture application in which a boundary graph defines the constraints of a Columbo-style mystery, a scene graph contains the persistent world (characters, locations, evidence, and agent state), an event graph records what actually happens during the episode, and projection graphs provide views such as detective notebooks, inventories, suspect boards, timelines, or case summaries. GOLEM contributes the narrative vocabulary, providing concepts such as Character, Setting, Object, Event, Narrative, and Inference, while HOLON provides the structural concepts of Boundary, Scene, Projection, Agent, and state evolution. The detective (for example, Columbo) is best modeled as a holon:Agent that is also a golem:Character, allowing inventories, knowledge, suspicions, and observations to be represented without forcing every character in the story to behave as an agent.

A key conclusion is that card draws should probably not be persisted in the graph. Cards are runtime mechanics that select narrative possibilities, but the graph should store only the resulting fictional reality: discoveries, conversations, accusations, evidence, locations, and participant relationships. While card reveals can be viewed philosophically as events that collapse a space of narrative possibilities into a canonical episode, they are not necessarily meaningful parts of the story world itself. Likewise, event ordering is objective and can be represented in the event graph, but causal relationships and inference chains are often supplied implicitly by the player and are therefore difficult to model accurately. As a result, the graph should capture who, what, where, and when, while the player remains the source of interpretation and meaning, producing a canonical Columbo fan-fiction episode that is represented through GOLEM entities and persisted as evolving HOLON world state.

## Strawman Episode

```trig
@prefix rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs:  <http://www.w3.org/2000/01/rdf-schema#> .

@prefix holon: <https://cluelumbo.org/holon#> .
@prefix golem: <https://cluelumbo.org/golem#> .

@prefix ex:    <https://cluelumbo.org/episode/001#> .

ex:BoundaryGraph {

    holon:Agent
        rdfs:subClassOf golem:Character .

    ex:ColumboMysteryTemplate
        a holon:Boundary ;

        holon:requiresDetective true ;
        holon:requiresEvidence true ;
        holon:requiresInference true ;
        holon:requiresAccusation true .

}

ex:SceneGraph {

    ex:Columbo
        a holon:Agent ;
        a golem:Character ;
        rdfs:label "Lieutenant Columbo" .

    ex:MrsPlum
        a golem:Character ;
        rdfs:label "Mrs Plum" .

    ex:MrGreen
        a golem:Character ;
        rdfs:label "Mr Green" .

    ex:Conservatory
        a golem:Setting ;
        rdfs:label "Conservatory" .

    ex:SmokingGun
        a golem:Object ;
        rdfs:label "Smoking Gun" .

    ex:Photograph
        a golem:Object ;
        rdfs:label "Photograph" .

}

ex:EventGraph {

    ex:ArrivalEvent
        a golem:Event ;
        holon:sequence 1;

        golem:hasParticipant ex:Columbo ;
        golem:occursIn ex:Conservatory .

    ex:GunDiscoveryEvent
        a golem:Event ;
        holon:sequence 2;

        golem:hasParticipant ex:MrsPlum ;
        golem:occursIn ex:Conservatory ;
        golem:involvesObject ex:SmokingGun .

    ex:FalseStatementEvent
        a golem:Event ;
        holon:sequence 3;

        golem:hasParticipant ex:MrGreen .

#        holon:claim
#            "Mr Green claimed he had never entered the Conservatory." .

    ex:PhotoDiscoveryEvent
        a golem:Event ;
        holon:sequence 4;

        golem:hasParticipant ex:Columbo ;
        golem:occursIn ex:Conservatory ;
        golem:involvesObject ex:Photograph .

    ex:InferenceEvent
        a golem:Event ;
        holon:sequence 5;

        golem:hasParticipant ex:Columbo .

#        holon:conclusion
#            "Mr Green lied about his whereabouts." .

    ex:AccusationEvent
        a golem:Event ;
        holon:sequence 6;

        golem:hasParticipant ex:Columbo ;
        golem:hasParticipant ex:MrGreen ;

        holon:accuses ex:MrGreen .
#        golem:containsEvent ex:AccusationEvent .

}

ex:ProjectionGraph {

    ex:CaseSummary001
        a holon:Projection .

    ex:Columbo
        holon:possesses ex:SmokingGun ;
        holon:possesses ex:Photograph .

    ex:MrGreen
        holon:isPrimarySuspect true .

    ex:EpisodeView
        a holon:Projection ;

        rdfs:label "Full Episode Narrative" ;

        holon:query """
PREFIX golem: <https://cluelumbo.org/golem#>
PREFIX holon: <https://cluelumbo.org/holon#>

CONSTRUCT {

    ex:Episode
        a golem:Narrative ;
        golem:containsEvent ?event .

    ?event
        a golem:Event ;
        holon:sequence ?sequence .
}
WHERE {
    ?event a golem:Event ;
           holon:sequence ?sequence .
}
ORDER BY ?sequence
""" .

}


}
```
