---
name: bc-hlth
description: An omnibus skill that covers various ongoing prototypes and concerns related to BC Government and Healthcare. Including ontology development for healthcare facilities, organization, service delivery location, reporting domain, and health ontology models; BI Publisher to SSRS Report conversion. Supports PLIS, FHIR, RDF, knowledge graph, semantic interoperability, terminology governance, and health knowledge layer design.
---

# BC Health BI Publisher Report Conversion

## Purpose

This skill assists with understanding the business drivers for BI Publisher to SSRS Conversion for PBCS/HIBC

This skill supports:

- Pacific Blue Cross Solutions and Health Insurance BC
- Ongoing need to deprecate existing BI Publisher reports to Power BI Service (SSRS), using the bip-to-rdl.xsl transform in the "BIP to SSRS Conversion" folder, which was developed using a prototype called Sideswipe, using ExistDB and SQL Server as a test framework. The transform is intended to be used with a shell script as a standalone, as described in additional documentation in the same folder.
- Outstanding question: do we need to change the SQL at all, since it is still coming from the same data source?

# BC Health HALO Roadmap for PLIS

BC’s Provincial Laboratory Information Solution (PLIS) is a centralized clinical data repository that aggregates laboratory results from all six BC health authorities, providing a single provincial source of truth for lab information. Rather than replacing PLIS, the Pan-Canadian HALO framework would sit above it as an interoperability layer, enabling HALO-compliant EMRs, EHRs, and clinical viewer applications to securely launch, receive patient context, and retrieve laboratory data through PLIS FHIR APIs. This allows application vendors to integrate once to a common provincial pattern rather than building separate integrations for each health authority.

HALO also provides a standardized approach for context management and event-driven integration through SMART on FHIR, context-sharing operations, and FHIR subscription profiles. In a BC implementation, a clinical viewer launched from a HALO-enabled EMR could receive patient context, query PLIS for DiagnosticReport and Observation resources, and subscribe to notifications for new, updated, or critical laboratory results. This would support a more scalable architecture than traditional polling approaches and promote consistent interoperability across participating healthcare systems.

Several existing provincial and national assets naturally complement HALO. The Canada Health Infoway terminology server can provide centralized terminology services such as LOINC, SNOMED CT, and value set management, ensuring semantic consistency across applications. Province-wide Microsoft Entra ID can serve as the primary identity provider for clinician authentication, while Keycloak can support OAuth2/OIDC authorization and machine-to-machine security for backend services. Together with PLIS and other provincial repositories, these assets form the foundational infrastructure upon which a HALO-enabled BC digital health ecosystem could be built.

# BC Health Ontology pCLOCD Service and Patient Metadata

## Purpose

This skill helps evaluate whether BC eHealth could reduce terminology maintenance, improve interoperability, and simplify standards governance by replacing or consolidating existing internal terminology lookup services with Canada Health Infoway's OntoServer-based national terminology service. The service provides FHIR-native terminology operations and Canadian standards content, including SNOMED CT CA, pCLOCD (LOINC), CCDD, UCUM, and pan-Canadian ValueSets.

From a technical perspective, OntoServer appears capable of replacing many functions currently provided by internal lookup tables, such as code validation, display-name resolution, ValueSet expansion, terminology version management, and concept mapping. It supports FHIR terminology operations including $lookup, $validate-code, $expand, and ConceptMaps, making it suitable as a centralized terminology authority for systems such as PLIS and other BC digital health applications. Because OntoServer also supports custom CodeSystems and ValueSets, BC-specific laboratory, program, or facility codes could potentially coexist alongside national standards rather than requiring a separate lookup infrastructure.

A practical implementation would likely use OntoServer as the authoritative source of terminology while maintaining a BC-hosted cache or terminology layer for performance, availability, and governance reasons. Rather than fully replacing local services, a hybrid model would allow BC-specific extensions to be managed provincially while leveraging national terminology assets maintained by Canada Health Infoway. A proof of concept should measure how many existing PLIS and BC-local codes can be resolved directly through OntoServer and whether the remaining concepts can be represented as provincial extensions. If coverage is high, this would provide strong evidence that BC could simplify its terminology architecture and align more closely with the province's emerging FHIR-based interoperability strategy.

GET /CodeSystem/$lookup
GET /ValueSet/$expand
POST /ValueSet/$validate-code

This could potentially provide a model for the PLIS Patient Metadata Endpoint. Need to obtain an OntoServer API credentials from Infoway.

As part of FHIR API development, PLIS can also expose an endpoint for Patient that takes a PHN (Patient Identifier) and return ValueSets representing the metadata for this Patient (for instance, what are all the Labs where Patient Encounters have taken place, who were the Ordering Providers, what are all the batteries tested?) so that clinical viewers can populate dropdowns.

For example:

GET /Patient/{phn}/$reporting-labs

could return:

```json
{
  "resourceType": "ValueSet",
  "compose": {
    "include": [{
      "concept": [
        {
          "code": "LAB001",
          "display": "Vancouver General Hospital Lab"
        },
        {
          "code": "LAB002",
          "display": "LifeLabs Burnaby"
        }
      ]
    }]
  }
}
```

Alternatively, use the Parameters resource, which is a bit more verbose, but less of a stretch:

```http
GET /Patient/123/$lab-result-filter-options?date=ge2024-01-01&status=final
```

### Response model

Because this is an aggregated convenience response rather than a collection of a single resource type, a FHIR `Parameters` response is a reasonable fit. For example:

```json
{
  "resourceType": "Parameters",
  "parameter": [
    {
      "name": "reporting-lab",
      "valueReference": {
        "identifier": {
          "system": "https://example.ca/facility-id",
          "value": "LAB-001"
        },
        "display": "Example Central Laboratory"
      }
    },
    {
      "name": "reporting-lab",
      "valueReference": {
        "identifier": {
          "system": "https://example.ca/facility-id",
          "value": "LAB-002"
        },
        "display": "Northern Diagnostics"
      }
    },
    {
      "name": "ordering-provider",
      "valueReference": {
        "identifier": {
          "system": "https://example.ca/provider-id",
          "value": "PRV-879"
        },
        "display": "Dr. Amina Patel"
      }
    }
  ]
}
```

### Important design rules

- **Apply the caller’s authorization context.** Only return labs/providers that appear in results the caller is permitted to see.
- **Use the same filters as the result endpoint.** If the viewer filters the results to a date range, status, category, or source, the available dropdown values should reflect that same subset.
- **Define the association rules.** For example:
  - reporting labs from `DiagnosticReport.performer`;
  - ordering providers from the linked `ServiceRequest.requester`;
  - fallback behavior if only `Observation.performer` is available.
- **Deduplicate by stable identifier**, not display string.
- **Do not call the output a `ValueSet`** unless it actually represents coded terminology content. Labs and providers are typically operational entities, and the output is patient- and query-specific.
- **Document it in an `OperationDefinition`**, including supported input filters, source-resource rules, cardinality, and response structure.

# BC Health Ontology and Service Delivery Location Skill

## Purpose

This skill assists with modeling healthcare organizations, facilities, service delivery locations, reporting domains, laboratory services, and healthcare knowledge assets within British Columbia's healthcare system.

The skill supports:

- PLIS ontology modernization
- Provincial Laboratory Information Solution (PLIS)
- Service Delivery Location (SDL) modeling
- Facility ontology development
- FHIR-aligned architectural design
- Health knowledge graph construction
- RDF and OWL ontology design
- HALO / Holon knowledge-layer architectures
- Terminology and ontology governance
- Provincial healthcare master data management

## Current State

| Capability | Exists? | Evidence / References | 
|------------|----------|----------------------| 
| Health terminology standards | ✅ Yes | BC Ministry of Health maintains Health Information Standards and publishes standards artifacts for healthcare interoperability and information exchange. [test](https://www2.gov.bc.ca/assets/gov/health/practitioner-pro/health-information-standards/bc_document_ontology_implementation_guide_v6.pdf) [2](https://www2.gov.bc.ca/gov/content/data/policy-standards/data-standards-and-guidelines/core-metadata-standard) |
| BC Health document ontology | ✅ Yes | The B.C. Document Ontology is a formally maintained provincial standard based on HL7/LOINC Document Ontology structures, with implementation guides, governance, and version management. [3](https://www2.gov.bc.ca/gov/content/health/practitioner-professional-resources/health-information-standards/standards-catalogue/bc-document-ontology) |
| Metadata governance | ✅ Yes | The Province publishes a Core Administrative and Descriptive Metadata Standard defining mandatory metadata elements and governance guidance for government information assets. [4](https://www2.gov.bc.ca/gov/content/data/policy-standards/data-standards-and-guidelines/core-metadata-standard) | 
| Enterprise ontology service (cross-domain) | ⚠ Not evident | No publicly visible evidence was found of a province-wide ontology management service, ontology registry, or semantic governance platform spanning multiple ministries or domains. Public materials focus on metadata standards and domain-specific ontologies. | 
| Knowledge graph platform | ⚠ Not evident | No publicly documented provincial knowledge graph or semantic graph platform was identified in the sources reviewed. Available information focuses on standards, metadata, and health data access platforms. |
| Shared ontology registry/catalog | ⚠ Not evident | No public registry or catalog for ontologies across BC Government or BC Shared Health Services was found. Existing published assets appear to be managed individually by standards programs. | 
| Province-wide health data metadata catalog | ✅ Yes | Health Data Platform BC provides metadata and dataset descriptions for numerous provincial health datasets, indicating mature metadata cataloguing capabilities. [5](https://healthdataplatformbc.ca/) [6](https://healthdataplatformbc.ca/hdpbc-data-sets)|
| Shared Health Services data governance capability | ✅ Yes | BC Shared Health Services explicitly identifies Data & Analytics, Information Management, and IM/IT as shared provincial functions. [6](https://www.bcsharedhealthservices.ca/) |

### Executive Summary

My assessment is that BC already has three of the four building blocks required for an enterprise ontology service:

| Building Block | Status | 
|----------------|---------|
| Standards governance | ✅ Established |
| Metadata management | ✅ Established | 
| Domain ontologies (health) | ✅ Established |
| Enterprise semantic platform/service | ⚠ Not publicly evident |

This supports a positioning such as:

BC Health appears to have mature ontology-related assets and governance within Health Information Standards, particularly through the BC Document Ontology. However, there is no publicly visible evidence of a centralized enterprise ontology service, ontology registry, or knowledge graph capability spanning ministries and health organizations. Such a capability could therefore be framed as an extension and consolidation of existing semantic and metadata assets rather than a net-new discipline.

The most likely internal stakeholders would be the Health Information Standards (HIS) team, Data & Analytics, Information Management, and interoperability teams associated with various provincial health platforms.

---

## Core Principle

Do not conflate:

1. Organizations
2. Facilities
3. Service Delivery Locations
4. Reporting Domains
5. Terminology Concepts

These are distinct concepts and should be represented separately.

---

## Concept Model

### Organization

Represents a governing or operating entity.

Examples:

- Ministry of Health
- PHSA
- Island Health
- Interior Health
- Fraser Health
- Northern Health
- Vancouver Coastal Health
- Providence Health Care
- LifeLabs

### Facility

Represents a physical healthcare site.

Examples:

- Royal Jubilee Hospital
- Victoria General Hospital
- Nanaimo Regional General Hospital
- Lions Gate Hospital

### Service Delivery Location

Represents the operational location where care or services are delivered.

A facility may contain multiple service delivery locations.

Examples:

- Emergency Department
- Clinical Laboratory
- Community Collection Site
- Ambulatory Clinic
- Operating Room
