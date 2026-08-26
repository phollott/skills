# Forgotten Wars

What happens when a civilization forgets itself in order to survive? The world's institutions all answer that question differently:

- Ministry of Forgetting: Forgetting is mercy
- Falconers Guild: Memory must be managed
- Market of Names: Identity is negotiable
- Tooth House: History is a resource
- Archive Monastery: Truth must survive

Episode 1: The Falconer of Forgotten Wars
Episode 2: The Market of Lost Names
Episode 3: The Dragon's Dentist
Episode 4: The Falconer finds evidence of stolen names.
Episode 5: The Name Broker investigates dragon records.
Episode 6: The Dentist discovers the dragon's name.
Episode 7: The Ministry intervenes and the Archive Monastery reveals the truth.
Episode 8: The Last Dragon remembers.
Episode 9: The Last War Falcon.

The audience initially believes: Memories are stored in Falcons; Identity is stored in Names; History is stored in Dragons: but these are all the same thing. Dragons digest memory. Their teeth form memory crystal. Memory crystal anchors names. Names anchor identity. War-falcons carry displaced memories. Everything is one system.

## The Falconer of Forgotten Wars

The Falconer wants to recover her wife's voice. The memory she seeks is inside a war-falcon carrying far more dangerous memories. Is personal remembrance worth collective suffering?

A memory-falcon has resurfaced in the Borderlands. The Falconer believes it contains the final intact memory of her wife. She tracks the bird. Recovering partial memories forces her to confront the possibility that her marriage wasn't as perfect as she remembers. She captures the bird. She learns it also contains memories that could reignite a forgotten war. She releases only part of the memory, and recovers her wife's true name but discovers there are far larger buried secrets.

Introduces: memory ecology, war falcons, Ministry of Forgetting, Borderlands

## The Market of Lost Names

The Name Broker wants to discover which of his many purchased identities is real. He has accumulated so many names that he can no longer determine which memories belong to him. Are we the stories we remember, or the stories others tell about us?

A customer appears demanding the return of a family's ancestral name. The Broker cannot even remember buying it. Investigation reveals that some names on the market are older than kingdoms. One appears to belong to the Last Dragon. The Broker discovers his own original name was traded long ago. He has been living under an acquired identity for decades. He rejects the market's records and begins searching for his true self.

Introduces: economics of identity, name trade, deeper dragon mystery, ancient history

This episode reveals the world's social infrastructure.

## The Dragon's Dentist

The Dragon Dentist wants to keep his prestigious position, but discovers a deeper need to free the dragon.

The civilization's entire memory economy depends on the dragon's suffering. What do we owe the being whose exploitation created our world? A routine examination reveals the dragon is dying. The Dentist learns the dragon's illness is deliberate. The Tooth House suppresses healing because damaged teeth produce greater quantities of memory crystal. The dragon reveals a terrible truth: It once had a name, the same name now being sold in the Market of Names.

The Dentist chooses rebellion.

Introduces: dragons, memory crystals, hidden history, systemic injustice

This is where the season's deeper mythology emerges.

HGA View

In graph terms:

Scene Graph

Shared world.

Falconer
Name Broker
Dragon Dentist
Last Dragon

Falconers Guild
Market of Names
Tooth House
Ministry

Great Falcon
True Name
Memory Crystal

Event Graph

Each novella activates different tensions.

Story 1
    HuntGreatFalcon

Story 2
    TradeTrueName

Story 3
    HarvestDragonTooth

Season Event

All roads converge on:

RecoverDragonsName


which changes the entire setting.

For a Beneath Ceaseless Skies submission, I'd submit The Falconer of Forgotten Wars first because it has the strongest emotional spine and most self-contained resolution. But I'd secretly write it as Episode 1 of a much larger cycle in which the Falconer, Name Broker, and Dragon Dentist eventually become the three protagonists responsible for restoring the world's memory.

The Falconer lost her wife to war many years past. When the wars ended, all memories of the war were banished, transmuted into falcons and other raptors. 

```trig
@prefix ex:   <https://example.org/forgottenwars#> .
@prefix gc:   <https://w3id.org/golem/ontology#> .
@prefix prov: <http://www.w3.org/ns/prov#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix xsd:  <http://www.w3.org/2001/XMLSchema#> .

################################################
# SCENE GRAPH
################################################

ex:SceneGraph {

    ################################################
    # STORY UNIVERSE
    ################################################

    ex:ForgottenWars
        a gc:G14_Narrative-Stoff ;
        rdfs:label "Forgotten Wars" .

    ex:BorderlandsMemoryResurgence
        a gc:G12_Setting ;
        rdfs:label "Borderlands During the Return of Memories" .

    ################################################
    # LOCATIONS
    ################################################

    ex:Borderlands
        a gc:G13_Narrative_Location ;
        rdfs:label "Borderlands" .

    ex:DragonVault
        a gc:G13_Narrative_Location ;
        rdfs:label "Dragon Vault" .

    ex:NameBazaar
        a gc:G13_Narrative_Location ;
        rdfs:label "Name Bazaar" .

    ex:ArchiveMountain
        a gc:G13_Narrative_Location ;
        rdfs:label "Archive Mountain" .

    ################################################
    # CHARACTERS
    ################################################

    ex:Falconer
        a gc:G1_Character ;
        rdfs:label "The Falconer" .

    ex:Minister
        a gc:G1_Character ;
        rdfs:label "The Minister of Forgetting" .

    ex:NameBroker
        a gc:G1_Character ;
        rdfs:label "The Name Broker" .

    ex:DragonDentist
        a gc:G1_Character ;
        rdfs:label "The Dragon Dentist" .

    ex:LastDragon
        a gc:G1_Character ;
        rdfs:label "The Last Dragon" .

    ################################################
    # ORGANISATIONS
    ################################################
    
    ex:FalconersGuild
      a dlp:agentive-social-object ;
      rdfs:label "Falconers Guild" .

    ex:MarketOfNames
      a dlp:agentive-social-object ;
        rdfs:label "Market of Names" .

    ex:MinistryOfForgetting
      a dlp:agentive-social-object ;
        rdfs:label "Ministry of Forgetting" .

    ex:ArchiveMonastery
      a dlp:agentive-social-object ;
        rdfs:label "Archive Monastery" .

    ex:ToothHouse
      a dlp:agentive-social-object ;
        rdfs:label "Tooth House" .

    ################################################
    # MEMBERSHIPS
    ################################################

    ex:FalconersGuild
        gc:hasCharacter ex:Falconer .

    ex:MarketOfNames
        gc:hasCharacter ex:NameBroker .

    ex:MinistryOfForgetting
        gc:hasCharacter ex:Minister .

    ex:ToothHouse
        gc:hasCharacter ex:DragonDentist .

    ################################################
    # OBJECTS
    ################################################

    ex:GreatFalcon
        a gc:G16_Object ;
        rdfs:label "Great Falcon" .

    ex:MemoryCrystal
        a gc:G16_Object ;
        rdfs:label "Memory Crystal" .

    ex:TrueName
        a gc:G16_Object ;
        rdfs:label "True Name" .

    ex:WifesVoice
        a gc:G16_Object ;
        rdfs:label "Wife's Voice" .

    ex:ForgottenAtrocities
        a gc:G16_Object ;
        rdfs:label "Forgotten Atrocities" .

    ################################################
    # PSYCHOLOGICAL STATES
    ################################################

    ex:Grief
        a gc:G3_Psychological_State .

    ex:Longing
        a gc:G3_Psychological_State .

    ex:IdentityFracture
        a gc:G3_Psychological_State .

    ex:Falconer
        gc:hasPsychologicalState ex:Grief ,
                                 ex:Longing .

    ex:NameBroker
        gc:hasPsychologicalState ex:IdentityFracture .

    ################################################
    # RELATIONSHIPS
    ################################################

    ex:GreatFalcon
        ex:contains ex:WifesVoice ,
                    ex:ForgottenAtrocities .

    ex:LastDragon
        ex:produces ex:MemoryCrystal .

    ex:MarketOfNames
        ex:trades ex:TrueName .

    ################################################
    # SETTING COMPOSITION
    ################################################

    ex:BorderlandsMemoryResurgence
        ex:includes
            ex:Falconer ,
            ex:Minister ,
            ex:GreatFalcon ,
            ex:LastDragon ,
            ex:Borderlands ,
            ex:FalconersGuild ,
            ex:MinistryOfForgetting .
}

################################################
# EVENT GRAPH
################################################

ex:EventGraph {

    ################################################
    # EVENTS
    ################################################

    ex:HuntGreatFalcon
        a gc:G5_Narrative_Event ;
        rdfs:label "Hunt Great Falcon" ;
        prov:startedAtTime
            "1026-05-01T08:00:00Z"^^xsd:dateTime .

    ex:SuppressMemory
        a gc:G5_Narrative_Event ;
        rdfs:label "Suppress Memory" ;
        prov:startedAtTime
            "1026-05-20T12:00:00Z"^^xsd:dateTime .

    ex:HarvestDragonTooth
        a gc:G5_Narrative_Event ;
        rdfs:label "Harvest Dragon Tooth" .

    ex:TradeTrueName
        a gc:G5_Narrative_Event ;
        rdfs:label "Trade True Name" .

    ################################################
    # PARTICIPATION
    ################################################

    ex:HuntGreatFalcon
        ex:participant ex:Falconer ;
        ex:target ex:GreatFalcon ;
        ex:location ex:Borderlands .

    ex:SuppressMemory
        ex:participant ex:Minister ;
        ex:target ex:GreatFalcon ;
        ex:location ex:Borderlands .

    ex:HarvestDragonTooth
        ex:participant ex:DragonDentist ;
        ex:target ex:LastDragon ;
        ex:location ex:DragonVault .

    ex:TradeTrueName
        ex:participant ex:NameBroker ;
        ex:target ex:TrueName ;
        ex:location ex:NameBazaar .

    ################################################
    # NARRATIVE SEQUENCE
    ################################################

    ex:HuntGreatFalcon
        ex:precedes ex:SuppressMemory .

    ex:SuppressMemory
        ex:precedes ex:HarvestDragonTooth .

    ################################################
    # CONSEQUENCES
    ################################################

    ex:HuntGreatFalcon
        ex:seeks ex:WifesVoice .

    ex:SuppressMemory
        ex:prevents ex:MemoryRecovery .

    ex:HarvestDragonTooth
        ex:reveals ex:DragonCaptivity .

    ex:TradeTrueName
        ex:causes ex:IdentityFracture .
}
```
