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

## Modeling Notes

Facilities presently act as composite reporting entities and may simultaneously represent place, organization, and operational reporting concepts. Multiple reporting codes are retained where historical or alternate identifiers are known; although effective dating would ideally be represented through events, reliable transition dates are not currently available. The model therefore preserves identifier aliases without temporal assertions and leaves more granular organizational, provenance, and interoperability modeling for future revisions.

- Reporting entities currently represent a deliberate composite of organizational, operational, and physical-place concepts. These concerns may be separated into distinct holons in a future revision if additional governance, spatial, or interoperability requirements emerge.
- Facilities may contain multiple plis:reportingCode values representing aliases, legacy identifiers, or alternate source-system representations. While effective dating of these identifiers would ideally be modeled as events, the necessary historical transition data is not currently available, so codes are treated as coexisting identifiers without temporal assertions.
- Disciplines are currently modeled as controlled vocabulary members rather than a formal terminology hierarchy. More rigorous SKOS or OWL-based modeling may be introduced if additional classification requirements arise.
- The Boundary graph currently captures only lightweight source-system lineage and identifier mappings. Future revisions may incorporate richer interoperability artefacts such as HL7, FHIR, terminology, and provenance mappings as these become available.

## Key Insight

The legacy `FACILITY_LOOKUP` table is probably **not actually a facility registry**.

It is better understood as a:

> **Reporting Domain Registry**

The consistent characteristics of entries in `FACILITY_LOOKUP` are:

- `FACILITY_ID` (reporting identifier)
- `FACILITY_OID` (identifier system)
- reporting footer content
- report-generation behaviour

These are all reporting concerns rather than physical facility concerns.

Examples:

```text
ARH
Prince George RH
PHC
VHC
STS
VIHA-CN
LIFELABS
VMLK
CDC
```

All are selectable reporting scopes within PLIS.

---

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

```turtle
plis:IslandHealth
    a holon:OrganizationHolon .
```

---

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

```turtle
plis:RoyalJubileeHospital
    a plis:RegionalHospital ;
    schema:memberOf plis:IslandHealth .
```

---

### 3. Reporting Domain

Represents a scope to which reporting rules, legends, notices, and footer content apply.

Examples:

```text
VIHA-CN
VHC
STS
PHC
LIFELABS
VMLK
BCB
CDC
```

Example:

```turtle
plis:VIHACNReportingDomain
    a plis:ReportingDomain ;
    plis:reportingCode "VIHA-CN" .
```

---

## Important Observation

A facility and a reporting domain are **not the same thing**, although sometimes they coincide.

### Northern Health

Reporting is largely facility-centric.

```text
Prince George RH
Prince Rupert RH
Fort St John Hospital
```

Each facility effectively acts as its own reporting domain.

---

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

---

## Proposed Relationship

Introduce:

```turtle
plis:reportingDomain
```

(or possibly `plis:reportsThrough`)

Example:

```turtle
plis:RoyalJubileeHospital
    plis:reportingDomain
        plis:VIHACNReportingDomain .

plis:VictoriaGeneralHospital
    plis:reportingDomain
        plis:VIHACNReportingDomain .

plis:NanaimoRegionalGeneralHospital
    plis:reportingDomain
        plis:VIHACNReportingDomain .
```

This preserves:

- real facility structure
- organizational structure
- reporting structure

without conflating them.

---

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

---

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

---

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

---

## Future Query Direction

Current query assumes:

```sparql
?facility schema:memberOf ?organization
```

This works for facility-centric reporting but breaks down for shared domains such as:

```text
VIHA-CN
VHC
STS
PHC
VMLK
```

Future model should resolve reporting through the reporting domain:

```sparql
?facility
    plis:reportingDomain
        ?domain .

?config
    rpt:appliesToReportingEntity
        ?domain .
```

This enables a single reporting mechanism for:

- facility-based reporting
- domain-based reporting
- program-based reporting
- laboratory-service reporting

---

## Alternative View: Make ReportingDomain the Primary Reporting Concept

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

---

## Working Hypothesis

A useful rule of thumb:

> Anything identified by a reporting code and assigned reporting footer behaviour should be modeled as a Reporting Domain.

Facilities, hospitals, programs, and laboratory services may participate in one or more reporting domains, but reporting domains are the primary unit used by the report generation system.

Island Health's `VIHA-CN` provides the clearest example of why the distinction matters:

- many physical facilities
- one organization
- one reporting domain

These are three separate concepts and should remain independently representable in the ontology.
