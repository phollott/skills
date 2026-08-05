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
