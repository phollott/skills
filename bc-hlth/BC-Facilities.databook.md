---
title: PLIS Reporting Domain Model Notes
summary: Modeling facilities, organizations, and reporting domains within the PLIS laboratory reporting ontology.
author: Piers Hollott
created: 2026-07-31
updated: 2026-07-31
status: draft

tags:
  - plis
  - ontology
  - rdf
  - reporting-domain
  - healthcare
  - laboratory-reporting
  - knowledge-graph

domain: BC Provincial Laboratory Information Solution
project: PLIS Ontology Modernization

concepts:
  - Organization
  - Facility
  - ReportingDomain
  - LaboratoryReportingConfiguration

key-insight: >
  FACILITY_LOOKUP appears to function primarily as a registry of
  reporting domains rather than a registry of physical facilities.
  Facilities, organizations, and reporting domains should be modeled
  as distinct concepts.

open-questions:
  - Should PHSA reporting codes (CDC, BCC, CWH, PHSA-SQ) become first-class reporting domains?
  - Should reportingDomain be modeled as a relationship or as an additional rdf:type?
  - Can a facility participate in multiple reporting domains?
  - How should reporting domains be represented in FHIR resources?

related:
  - hga-primer.databook.md
  - facility_lookup.sql
  - laboratory-reporting-model.md
---

# PLIS Reporting Domain Model Notes

British Columbia's healthcare ecosystem depends on a shared understanding of locations, services, organizations, and clinical terminology. Today, these concepts are often duplicated across operational systems, integration layers, reporting applications, GIS platforms, registries, and healthcare information exchanges. The result is significant effort spent reconciling facility identifiers, service names, organizational hierarchies, reporting domains, and terminology mappings. An ontology-driven knowledge graph provides an opportunity to establish a canonical semantic layer that allows these assets to be defined once and reused consistently across programs, health authorities, provincial services, and digital health initiatives.

A provincial ontology for locations and service locations would create a common model for healthcare delivery across British Columbia. Physical facilities such as hospitals, laboratories, community health centres, clinics, and diagnostic sites could be represented alongside organizational ownership, geographic relationships, service capabilities, reporting domains, and operational characteristics. Rather than treating location data as a collection of application-specific codes, the ontology would model the real-world entities and relationships that healthcare professionals, planners, analysts, and information systems interact with every day. This would support interoperability between systems while preserving healthcare-specific context and governance requirements.

A complementary terminology layer would provide semantic alignment between local business concepts and established standards such as SNOMED CT, LOINC, FHIR, Schema.org, and HL7. By combining location, service, and terminology ontologies within a knowledge graph architecture, British Columbia could establish a foundation for advanced analytics, AI grounding, digital twins, service discovery, interoperability, and enterprise reporting. The resulting semantic infrastructure would become a strategic asset that supports both current operational needs and future innovation initiatives.

## Proposed Initiative
**Enterprise Healthcare Location and Terminology Graph for British Columbia**

The proposed initiative would establish a provincial semantic platform consisting of three interconnected domains:

1. Location Ontology

Models physical and geographic entities including: Health authorities, Hospitals, Community health centres, Laboratories, Clinics, Campuses and Buildings, Departments and Rooms, Geographic regions and Service catchment areas

2. Service Location Ontology

Models where services are delivered and how services relate to facilities.

Examples: Laboratory services, Diagnostic imaging, Emergency services, Pathology, Public health, Community care, Mental health services

3. Terminology Ontology

Models controlled vocabularies and terminology relationships. For instance, PLIS stores an assortment of pCLOCD/LOINC codes for the different Health Authorities. A terminology server could be used to substitute these in at the source, as part of FHIR adaptation or in PLIS DAL, or in HealthIdeas/HDP. Currently, this is implemented within PLIS as a pair of lookup tables. 

Examples: Disciplines, Service categories, Program types, Clinical specialties, Reporting classifications

## Strategic Benefits

**Improved Interoperability**

Organizations currently maintain multiple representations of the same facility, service, or identifier.

A shared ontology would provide: Canonical identifiers, Cross-system mappings, Shared definitions, Reduced integration complexity

**Enhanced Data Governance**

The ontology becomes the authoritative source for: Business definitions, Relationships, Identifier management, Provenance and Metadata

This reduces ambiguity and improves trust in enterprise data.

**Support for AI and Knowledge-Based Systems**

Modern AI systems require strong grounding.

A location and terminology graph provides: Verified entities, Explainable relationships, Controlled vocabulary alignment, Evidence-based retrieval

Example query:

Which laboratories provide microbiology services to facilities within the Interior Health reporting domain?

This is naturally answered through graph traversal rather than document search.

**Improved Analytics and Reporting**

The graph allows reporting systems to reason over: Facility hierarchies, Service relationships, Geographic boundaries, Organizational structures

**Foundation for Digital Twins**

The ontology can act as the semantic backbone for healthcare digital twins.

Future extensions may include: Capacity metrics, Equipment inventories, Workforce assignments, Service demand, Operational events

## Recommended Platform Architecture

**Option 1: Open Source Foundation**

Recommended for pilots and early adoption.

Plain Text, OWL 2 RL, SKOS, SHACL, Apache Jena Fuseki, GitHub

Benefits: Low cost, Standards-based, Rapid experimentation, Easy deployment

**Option 2: Enterprise Semantic Platform**

Recommended for long-term provincial deployment.

Plain Text, OWL 2 RL, SKOS, SHACL, GraphDB or Stardog, Azure

Benefits: Governance, Federated data access, Enterprise security, Advanced reasoning, AI integration

### Ontology Responsibilities

| Technology | Purpose |
|------------|------------|
| OWL	| Structural ontology and semantic relationships |
| SKOS | Controlled vocabularies and terminology schemes |
| SHACL | Data quality and validation rules |
| RDF | Knowledge representation |
| SPARQL | Query and integration |
| PROV-O | Lineage and provenance |

## Expected Outcomes

The initiative would establish a provincial semantic foundation that:

- Creates a canonical healthcare location model for BC
- Unifies facilities, services, organizations, and terminology
- Reduces integration and maintenance costs
- Supports FHIR and HL7 interoperability initiatives
- Improves analytics and reporting consistency
- Enables AI and knowledge graph applications
- Provides a foundation for future digital twin capabilities

Most importantly, it would shift location and terminology management from application-specific implementations to a shared provincial knowledge asset that can be reused across health authorities, provincial services, and future digital health initiatives.


## Modeling Notes

Facilities presently act as composite reporting entities and may simultaneously represent place, organization, and operational reporting concepts. Multiple reporting codes are retained where historical or alternate identifiers are known; although effective dating would ideally be represented through events, reliable transition dates are not currently available. The model therefore preserves identifier aliases without temporal assertions and leaves more granular organizational, provenance, and interoperability modeling for future revisions.

- Reporting entities currently represent a deliberate composite of organizational, operational, and physical-place concepts. These concerns may be separated into distinct holons in a future revision if additional governance, spatial, or interoperability requirements emerge.
- Facilities may contain multiple plis:reportingCode values representing aliases, legacy identifiers, or alternate source-system representations. While effective dating of these identifiers would ideally be modeled as events, the necessary historical transition data is not currently available, so codes are treated as coexisting identifiers without temporal assertions.
- Disciplines are currently modeled as controlled vocabulary members rather than a formal terminology hierarchy. More rigorous SKOS or OWL-based modeling may be introduced if additional classification requirements arise.
- The Boundary graph currently captures only lightweight source-system lineage and identifier mappings. Future revisions may incorporate richer interoperability artefacts such as HL7, FHIR, terminology, and provenance mappings as these become available.

## Key Insight

The legacy `FACILITY_LOOKUP` table is probably **not actually a facility registry**.

It is better understood as a: **Reporting Domain Registry**, identified by Facility ID and OID, which governs report generation. These are reporting concerns rather than physical facility concerns.

## Distinguish Three Concepts

### 1. Organization

Represents governance / ownership.

Examples:

```text
Island Health
Fraser Health
Northern Health
Interior Health
PHSA
LifeLabs
Providence
Vancouver Coastal
```

Example:

```sparql
PREFIX plis:   <http://plis.hlth.gov.bc.ca/ns#>
PREFIX holon:  <http://holon.org/ns#>
PREFIX schema: <https://schema.org/>

SELECT
    ?organization
    ?name
WHERE {
    GRAPH <http://plis.hlth.gov.bc.ca/ns#scene> {
        ?organization
            a holon:OrganizationHolon .

        OPTIONAL {
            ?organization
                schema:name ?name .
        }
    }
}
ORDER BY ?name
```

### 2. Facility

Represents a physical care location.

Examples:

```text
Royal Jubilee Hospital
Victoria General Hospital
Nanaimo Regional General Hospital
Prince Rupert Regional Hospital
```

Example:

```sparql
PREFIX plis:   <http://plis.hlth.gov.bc.ca/ns#>
PREFIX schema: <https://schema.org/>

SELECT
    ?facility
    ?name
    ?organizationName
    ?reportingDomainName
    (GROUP_CONCAT(DISTINCT ?code; SEPARATOR=", ") AS ?identifiers)
WHERE {
    GRAPH <http://plis.hlth.gov.bc.ca/ns#scene> {
        {
            ?facility a plis:Hospital .
        }
        UNION
        {
            ?facility a plis:HealthCentre .
        }

        OPTIONAL {
            ?facility schema:name ?name .
        }

        OPTIONAL {
            ?facility plis:reportingCode ?code .
        }

        OPTIONAL {
            ?facility schema:memberOf ?organization .
            ?organization schema:name ?organizationName .
        }

        OPTIONAL {
            ?facility
                plis:memberOfReportingDomain
                    ?reportingDomain .

            ?reportingDomain
                schema:name ?reportingDomainName .
        }
    }
}
GROUP BY
    ?facility
    ?name
    ?organizationName
    ?reportingDomainName
ORDER BY ?name
```

### 3. Reporting Domain

Represents a scope to which reporting rules, legends, notices, and footer content apply.

Example:

```sparql
PREFIX plis:   <http://plis.hlth.gov.bc.ca/ns#>
PREFIX schema: <https://schema.org/>

SELECT
    ?reportingDomain
    ?name
WHERE {
    GRAPH <http://plis.hlth.gov.bc.ca/ns#scene> {
        ?reportingDomain
            a plis:ReportingDomain .

        OPTIONAL {
            ?reportingDomain
                schema:name ?name .
        }
    }
}
ORDER BY ?name
```

## Important Observation

A facility (location) and a reporting domain (reporting) are **not the same thing**, although sometimes they coincide.

### Northern Health

Reporting is largely facility-centric.

```text
Prince George RH
Prince Rupert RH
Fort St John Hospital
```

Each facility effectively acts as its own reporting domain.

### Island Health

Reporting is centralized.

Many facilities share one reporting domain:

```text
Royal Jubilee Hospital
Victoria General Hospital
Nanaimo Regional Hospital
Cowichan District Hospital
...
```

all report through:

```text
VIHA-CN
```

This reveals why Facility and Reporting Domain must be separate concepts.

## Vancouver Coastal Example

```turtle
plis:VancouverGeneralHospital
    plis:reportingDomain
        plis:VHCReportingDomain .

plis:UBCHospital
    plis:reportingDomain
        plis:VHCReportingDomain .

plis:RichmondHospital
    plis:reportingDomain
        plis:VHCReportingDomain .
```

while:

```turtle
plis:LionsGateHospital
    plis:reportingDomain
        plis:STSReportingDomain .
```

## LifeLabs Example

```text
Organization:
    LifeLabs

Reporting Domains:
    LIFELABS
    BCB
    VMLK
    VMLO
    VMLP
    VMLV
```

Many reporting domains under one organization.

## PHSA Example

Current model:

```text
PHSALaboratories
    CDC
    BCC
    CWH
    PHSA-SQ
```

Need to determine whether these should eventually become:

```text
CDCReportingDomain
BCCReportingDomain
CWHReportingDomain
PHSASQReportingDomain
```

following the same pattern used for VHC, STS, VIHA-CN and LifeLabs.

## Future Query Direction

Enable a single reporting mechanism for:

- facility-based reporting
- domain-based reporting
- program-based reporting
- laboratory-service reporting

## Better View: ReportingDomain is the Primary Reporting Concept

A stronger interpretation of the data is:

> Anything identified by a reporting code and assigned footer behaviour is a Reporting Domain.

Under this approach:

```turtle
plis:facility-ARH
    a plis:RegionalHospital ,
      plis:ReportingDomain .

plis:facility-PrinceGeorge
    a plis:RegionalHospital ,
      plis:ReportingDomain .
```

while:

```turtle
plis:VHCReportingDomain
    a plis:ReportingDomain .

plis:VIHACNReportingDomain
    a plis:ReportingDomain .
```

The distinction becomes:

### Physical / Organizational Reality

```text
Regional Hospital
Community Hospital
Health Centre
Organization
```

### Reporting Reality

```text
Reporting Domain
```

A resource may participate in both classifications simultaneously.

This may ultimately simplify the reporting model while preserving rich facility and organizational structure.

## Working Hypothesis

A useful rule of thumb:

> Anything identified by a reporting code and assigned reporting footer behaviour is modeled as a Reporting Domain.

Facilities, hospitals, programs, and laboratory services may participate in one or more reporting domains, but reporting domains are the primary unit used by the report generation system.

Island Health's `VIHA-CN` provides the clearest example of why the distinction matters:

- many physical facilities
- one organization
- one reporting domain

These are three separate concepts and should remain independently representable in the ontology.
