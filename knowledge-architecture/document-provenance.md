---
title: Knowledge Architecture: Documents, Provenance, and Agent Interoperability
author: Piers Hollott
date: 2026-07-15
type: DataBook
status: Draft
topics:
  - Knowledge Architecture
  - Interoperability
  - FHIR
  - HL7 SPL
  - TEI
  - RDF
  - RDFa
  - Provenance
  - Agent Systems
  - Open Knowledge Format
related:
  - Documents as Knowledge Objects
  - Narrative and Metadata
  - Agent Grounding
  - Semantic Publishing
summary:
  Knowledge requires both content and metadata. Human-readable
  narratives and machine-readable context together enable
  interoperability, discoverability, trust, provenance, and
  agent grounding.
---

# Executive Summary

A recurring theme across healthcare interoperability, semantic
publishing, and emerging agent architectures is that knowledge
consists of more than content alone. Effective knowledge systems
combine human-readable narratives with machine-readable metadata,
allowing information to be discovered, interpreted, trusted, and reused.

This principle appears repeatedly in formats such as HL7 SPL,
FHIR resources, TEI documents, RDFa-enabled web pages, and
emerging AI-oriented formats such as Open Knowledge Format (OKF)
and DataBooks.

# Core Insight

Knowledge = Content + Context + Provenance

Content provides meaning for readers.

Context and provenance provide meaning for systems.

Removing metadata may simplify storage and retrieval, but risks
losing the information necessary for trust, interpretation,
versioning, grounding, and interoperability.

# Discussion

## SPL as a Knowledge Object

HL7 Structured Product Labeling (SPL) combines:

- Product identifiers
- Drug metadata
- Ingredients
- Regulatory information
- Human-readable monograph content

The success of SPL comes from the combination of structured
metadata and narrative information within a single document.

The metadata enables routing, indexing, and interpretation.

The narrative provides the information being communicated.

## FHIR and Narrative

FHIR resources combine:

- Machine-readable coded content
- Human-entered observations and annotations
- Human-readable narrative representations

The narrative acts as a representation of the resource for
human consumption while maintaining machine-readable semantics.

This reflects the same document-plus-metadata pattern found in SPL.

## TEI as an Internal Representation

TEI was considered as a canonical internal representation because
it supports:

- Rich document structure
- Publication metadata
- Editorial information
- Transformation into HTML

Particularly important is the TEI Header, which functions as a
knowledge envelope around the document itself.

The TEI concept of xenoData suggested the possibility of embedding
external metadata representations such as FHIR resources.

Although SPL was ultimately retained for convenience, TEI
demonstrates a powerful model for combining content and metadata
within a single structured artifact.

# Modern Agent Architectures

Current AI and agent-based systems often prefer:

- Markdown
- JSON
- Vector embeddings
- Simple document stores

These formats optimize accessibility and retrieval but can obscure:

- Provenance
- Authorship
- Versioning
- Authority
- Publication context

The challenge is not retrieval alone.

The challenge is grounding.

Agents need to know:

- Where information originated
- Why it can be trusted
- What it refers to
- How current it is

# Open Knowledge Format and DataBooks

Formats such as:

- Open Knowledge Format (OKF)
- DataBooks

follow a recurring architectural pattern:

Metadata Header
+
Structured Content

A YAML header may contain:

- Source
- Author
- Version
- Provenance
- Concepts
- Relationships

The body contains human-readable narrative.

This resembles a lightweight synthesis of:

- TEI Headers
- FHIR Metadata
- SPL Headers
- RDF Metadata

# Semantic Web Connection

An important observation was the similarity between TEI and
Jeni Tennison's rdfQuery experiments.

rdfQuery demonstrated that:

- Human-readable HTML
- Embedded RDFa metadata

could coexist in the same document.

The web page became both:

- 