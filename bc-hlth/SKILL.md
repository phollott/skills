---
name: bc-hlth
description: Creates and validates British Columbia healthcare facility, organization, service delivery location, reporting domain, and health ontology models. Supports PLIS, FHIR, RDF, knowledge graph, semantic interoperability, terminology governance, and health knowledge layer design.
---

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
| Health terminology standards | ✅ Yes | BC Ministry of Health maintains Health Information Standards and publishes standards artifacts for healthcare interoperability and information exchange. 【1](https://www2.gov.bc.ca/assets/gov/health/practitioner-pro/health-information-standards/bc_document_ontology_implementation_guide_v6.pdf](https://www2.gov.bc.ca/gov/content/data/policy-standards/data-standards-and-guidelines/core-metadata-standard) |
| BC Health document ontology | ✅ Yes | The B.C. Document Ontology is a formally maintained provincial standard based on HL7/LOINC Document Ontology structures, with implementation guides, governance, and version management.【2】(https://www2.gov.bc.ca/gov/content/health/practitioner-professional-resources/health-information-standards/standards-catalogue/bc-document-ontology) |
| Metadata governance | ✅ Yes | The Province publishes a Core Administrative and Descriptive Metadata Standard defining mandatory metadata elements and governance guidance for government information assets. 【3】(https://www2.gov.bc.ca/gov/content/data/policy-standards/data-standards-and-guidelines/core-metadata-standard) | 
| Enterprise ontology service (cross-domain) | ⚠ Not evident | No publicly visible evidence was found of a province-wide ontology management service, ontology registry, or semantic governance platform spanning multiple ministries or domains. Public materials focus on metadata standards and domain-specific ontologies. | 
| Knowledge graph platform | ⚠ Not evident | No publicly documented provincial knowledge graph or semantic graph platform was identified in the sources reviewed. Available information focuses on standards, metadata, and health data access platforms. |
| Shared ontology registry/catalog | ⚠ Not evident | No public registry or catalog for ontologies across BC Government or BC Shared Health Services was found. Existing published assets appear to be managed individually by standards programs. | 
| Province-wide health data metadata catalog | ✅ Yes | Health Data Platform BC provides metadata and dataset descriptions for numerous provincial health datasets, indicating mature metadata cataloguing capabilities. 【4】(https://healthdataplatformbc.ca/) [6](https://healthdataplatformbc.ca/hdpbc-data-sets)|
| Shared Health Services data governance capability | ✅ Yes | BC Shared Health Services explicitly identifies Data & Analytics, Information Management, and IM/IT as shared provincial functions. 【5](https://www.bcsharedhealthservices.ca/) |

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
