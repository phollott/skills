Cluelumbo is a narrative knowledge-graph game in which card reveals progressively collapse a space of fictional possibilities into a canonical Columbo-style episode, represented as GOLEM narrative entities and persisted as a HOLON world graph.

### Strawman Episode

```trig
@prefix rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs:  <http://www.w3.org/2000/01/rdf-schema#> .

@prefix holon: <https://cluelumbo.org/holon#> .
@prefix golem: <https://cluelumbo.org/golem#> .

@prefix ex:    <https://cluelumbo.org/episode/001#> .

ex:BoundaryGraph {

    ex:ColumboMysteryTemplate
        a holon:Boundary ;

        holon:requiresDetective true ;
        holon:requiresEvidence true ;
        holon:requiresInference true ;
        holon:requiresAccusation true .

}

ex:SceneGraph {

    ex:Columbo
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

        golem:hasParticipant ex:Columbo ;
        golem:occursIn ex:Conservatory .

    ex:GunDiscoveryEvent
        a golem:Event ;

        golem:hasParticipant ex:MrsPlum ;
        golem:occursIn ex:Conservatory ;
        golem:involvesObject ex:SmokingGun .

    ex:FalseStatementEvent
        a golem:Event ;

        golem:hasParticipant ex:MrGreen .

#        holon:claim
#            "Mr Green claimed he had never entered the Conservatory." .

    ex:PhotoDiscoveryEvent
        a golem:Event ;

        golem:hasParticipant ex:Columbo ;
        golem:occursIn ex:Conservatory ;
        golem:involvesObject ex:Photograph .

    ex:InferenceEvent
        a golem:Inference ;

        golem:hasParticipant ex:Columbo ;

        holon:conclusion
            "Mr Green lied about his whereabouts." .

    ex:AccusationEvent
        a golem:Event ;

        golem:hasParticipant ex:Columbo ;
        golem:hasParticipant ex:MrGreen ;

        holon:accuses ex:MrGreen .

}

ex:EpisodeGraph {

    ex:Episode001
        a golem:Narrative ;

        golem:containsEvent ex:ArrivalEvent ;
        golem:containsEvent ex:GunDiscoveryEvent ;
        golem:containsEvent ex:FalseStatementEvent ;
        golem:containsEvent ex:PhotoDiscoveryEvent ;
        golem:containsEvent ex:InferenceEvent ;
        golem:containsEvent ex:AccusationEvent .

}

ex:ProjectionGraph {

    ex:CaseSummary001
        a holon:Projection .

    ex:Columbo
        holon:possesses ex:SmokingGun ;
        holon:possesses ex:Photograph .

    ex:MrGreen
        holon:isPrimarySuspect true .

}
```
