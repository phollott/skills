---
title: "HolonBridge Local-First Projection Architecture"
subtitle: "From NL-to-SPARQL Generation to Projection-Based Intent Routing"
author: "Piers Hollott"
date: "2026-09-01"
status: "working"
maturity: "prototype"

tags:
  - holonbridge
  - hga
  - holon-graph-architecture
  - knowledge-graph
  - fuseki
  - ollama
  - mistral
  - semantic-api
  - projection-graph
  - mcp
  - slow-ai
  - local-first

summary: >
  A local-first HolonBridge implementation using Dockerized Fuseki and Ollama.
  The architecture evolved from dynamic NL-to-SPARQL generation toward a
  projection-based model in which named graph capabilities are discovered
  from the knowledge graph and executed directly. The LLM is reduced to
  intent recognition and parameter extraction, improving performance,
  reliability, and governance.

problem-statement:
  - Local CPU-hosted LLMs were too slow for interactive SPARQL generation.
  - Generated queries often failed to match dataset vocabulary.
  - Runtime behavior depended heavily on prompt quality and schema context.
  - Dynamic query generation introduced reliability and governance concerns.

key-findings:
  - Infrastructure and authentication issues were resolved.
  - Dockerized Fuseki and Ollama operated successfully as a local stack.
  - Dataset-specific DataBooks improved schema grounding.
  - Smaller local models reduced latency but did not eliminate it.
  - Intent classification is significantly cheaper than query generation.
  - Projection-based execution is more reliable than generated SPARQL.

architectural-shift:
  from: "Natural Language → LLM → Generated SPARQL → Fuseki"
  to: "Natural Language → Projection Selection → Stored SPARQL → Fuseki"

core-principles:
  - Knowledge before inference
  - Local-first operation
  - Deterministic query execution
  - Capabilities as graph resources
  - AI augmentation rather than AI control
  - Governance through reusable projections

components:
  llm:
    role: "Intent classification and parameter extraction"
    implementation: "Mistral via Ollama"

  graph:
    role: "Knowledge, schema, and capability store"
    implementation: "Apache Jena Fuseki"

  projection-graph:
    role: "Semantic capability registry"
    contents:
      - named queries
      - input parameters
      - output shapes
      - descriptions
      - execution metadata

  bridge:
    role: "Intent routing and projection execution"
    implementation: "HolonBridge"

workflow:
  - Receive natural language question
  - Discover matching projection
  - Extract projection parameters
  - Execute trusted stored SPARQL
  - Return structured results
  - Optionally summarize results as natural language

prototype-status:
  infrastructure: complete
  local-model-integration: complete
  fuseki-integration: complete
  projection-discovery: complete
  projection-routing: complete
  named-query-execution: complete
  nl-to-sparql-generation: deprecated
  natural-language-result-summarization: planned

implemented-projections:
  - GetFacilityByName
  - GetFacilitiesByAuthority

example-result:
  question: "What facilities belong to Vancouver Coastal Health?"
  projection: "GetFacilitiesByAuthority"
  result: "Vancouver General Hospital"

future-directions:
  - Natural-language summarization of query results
  - Projection composition
  - Workflow holons
  - Narrative graph experimentation
  - Backstory integration
  - MCP tool exposure
  - Semantic capability governance

key-insight: >
  The knowledge graph should contain not only data and ontology definitions,
  but also executable organizational knowledge in the form of projections.
  The LLM serves as a lightweight natural-language interface, while the
  graph remains the authoritative source of structure, behavior, and memory.
---

# My HolonBridge prototype

## Today’s progress summary: 2026-09-01

We rebuilt the local HolonBridge setup so it runs with Dockerized Fuseki and Ollama, and we worked through the auth and model-integration issues that were blocking the stack. The bridge is now configured to use local Ollama instead of the original Anthropic path, and the key runtime fix was making sure the environment actually picks up the correct model and bearer token rather than silently retaining stale values. We also verified the stack health and confirmed the test dataset is available in Fuseki, which gave us a stable backend to query against.

We then focused on the actual query pipeline and found two core problems: the model was generating SPARQL that did not match the real dataset vocabulary, and the local inference was too slow to complete interactive requests on CPU. We corrected the schema context by creating dataset-specific Holon DataBook files so the model learned the correct classes, properties, and naming, and we tightened the builder prompt to enforce valid SPARQL structure with prefixes placed before the SELECT clause. After that, the main remaining bottleneck was performance: the first local model we tested was too slow for practical use, so we switched to a smaller local model and completed a full download to continue testing.

By the end of the day, the environment was operational and the bridge was configured for a local Ollama model, but the end-to-end NL query was still timing out at roughly 180 seconds. That means the infrastructure and schema fixes are in place, and the remaining issue is model responsiveness on this laptop hardware rather than a broken stack or bad auth. In practical terms, we have a working local pipeline and a clear next decision point: either keep tuning smaller/faster models, or accept that CPU-only local LLM querying is not truly viable for this use case and move to a faster GPU or hosted model path.

### Grounding Inference

What we've built is best described as facilitating access to a knowledge graph rather than fully grounding an LLM in one. The graph is acting as a semantic database with a capability layer: Mistral helps identify the user's intent, selects a projection, and then Fuseki executes a trusted query against the graph. This is already more powerful than a traditional database because the graph contains ontology, inference, projections, and entity relationships, but its primary role is still fact retrieval. The knowledge graph is helping answer questions accurately, but it is not yet deeply influencing how the model reasons about the domain. The inference Fuseki can perform (ie Hospital is subclassed from Facility) is still very useful.

A more fully grounded architecture would use the graph not only for data retrieval but also for concepts, definitions, rules, workflows, and organizational knowledge. In that model, HolonBridge becomes a semantic capability layer where the graph tells the agent what entities exist, how they relate, which projections or tools are available, and what workflows can be executed. The LLM is no longer just querying the graph; it is navigating a knowledge environment defined by the graph. From this perspective, your current projection-based approach is an important first step: you've successfully moved the graph beyond simple data storage and into storing operational knowledge, and the next evolution is to let the graph shape reasoning and decision-making, not just retrieval.

### Intent/Projection Routing

Rather than using a local LLM to generate SPARQL from natural language every time, a better fit for the Holon architecture is to leverage the projection graph as a semantic capability layer. The projection graph can store named queries, their input parameters, output structures, and descriptions. Instead of translating a user's request directly into SPARQL, the LLM only needs to identify which projection best matches the intent and extract the necessary parameters. This shifts the problem from expensive query generation to lightweight intent classification, which is much faster and more reliable on smaller local models. The underlying graph continues to execute the actual SPARQL, but the complexity is hidden behind reusable semantic operations.

Viewed this way, the projection graph becomes a kind of semantic API registry or MCP tool catalog for the knowledge graph. Each named projection represents a trusted, governed operation such as "Facilities by Health Authority," "FHIR Location Export," or "Facility Validation." New projections can still be created with the assistance of a more capable model when needed, but once approved they become reusable assets that eliminate repeated AI reasoning. Over time, the system evolves from an AI generating graph queries on demand into a knowledge-driven platform where the graph contains not only data and ontology definitions, but also the organization's operational knowledge about how that data should be queried and used. This aligns closely with Kurt Cagle's description of HolonBridge as a "smart endpoint" that exposes knowledge graph capabilities through an MCP-accessible semantic layer.

Rather than using a local LLM to generate SPARQL queries from natural language on every request, a better approach is to use the knowledge graph itself as a catalog of semantic capabilities. In this model, the graph stores named projections, query templates, workflows, business rules, and their descriptions. The LLM's job becomes much simpler: it only needs to identify the user's intent and map it to an existing projection while extracting any required parameters. The underlying graph then executes trusted SPARQL queries, eliminating the overhead, latency, and unreliability of generating queries dynamically.

### Slow AI Approach

This "Slow AI" architecture shifts intelligence from runtime inference into knowledge curation. AI is used offline to help build and enrich the graph, create projections, and document capabilities, while online requests are handled through deterministic graph logic and query execution. The result is a system where the knowledge graph acts as a semantic API registry or MCP-style tool catalog, and a small local model serves only as a lightweight natural language interface. This approach is faster, more reliable on local hardware, and more aligned with a knowledge-driven architecture where the graph contains not only data, but also organizational knowledge about how that data should be accessed and used.

HolonBridge now treats the projection graph as an intent-routing layer. It discovers `hga:Projection` resources from Fuseki, matches incoming natural-language questions against projection labels and descriptions, extracts declared parameters, and executes the stored trusted SPARQL directly. Matching requests therefore bypass Mistral and return machine-readable results with fields such as `routed`, `projectionId`, and `params`; unmatched questions still use the existing LLM pipeline.

### Entity Resolution

The Entity Resolution step takes the parameter extracted from the user’s question, looks up graph-owned canonical entities and aliases relevant to the selected projection property, normalizes variations such as “Healthcare” versus “Health,” and applies bounded fuzzy matching for misspellings such as “Costal.” It then replaces the user’s input with the canonical graph value before executing the stored projection SPARQL, while recording the original input, matched alias, canonical value, and similarity score for explainability.

The sample `test.trig` was expanded with a `GetFacilitiesByAuthority` projection for health-authority lookups, including tolerant matching for “Health” versus “Healthcare.” The bridge reload response now reports the number of discovered projections. During verification, duplicate projection data in Fuseki was cleared and reloaded, after which the example question correctly routed to the projection and returned Vancouver General Hospital.

### Natural Language Response Formatting

The next evolution of HolonBridge is to use Mistral after projection execution rather than before it. The graph and projection layer remain responsible for intent routing, entity resolution, and executing trusted SPARQL queries, while Mistral receives the user's original question along with the structured result set and generates a natural-language response based only on those returned facts. This changes the role of the LLM from query generation to explanation and narration, which is faster, more reliable, and less prone to hallucination. The resulting pattern becomes: User Question → Projection Selection → Entity Resolution → Stored SPARQL Execution → Structured Results → Mistral Summary, allowing the knowledge graph to remain the source of truth while the LLM provides a conversational interface for users.

### MCP Use Cases

MCP could be used to extend HolonBridge beyond a single Fuseki dataset by allowing projections to invoke external tools and data sources while remaining grounded in the knowledge graph. In this model, the graph stores the ontology, business concepts, identifiers, rules, workflows, and capability definitions, while MCP tools provide access to operational systems such as SQL databases, FHIR servers, REST APIs, SharePoint, file systems, or analytics platforms. When a user asks a question, the graph determines the intent and the appropriate capability, which then calls the relevant MCP tool to retrieve current data. The graph acts as the semantic layer that gives meaning and context to the retrieved information.

This creates a powerful architecture where the knowledge graph becomes a semantic control plane rather than merely a data store. Projections can function as a catalog of trusted MCP-accessible capabilities, allowing the system to answer questions using live enterprise data while remaining grounded in graph-defined concepts and governance. The resulting pattern becomes User Question → Projection Selection → MCP Tool Invocation → Data Retrieval → Graph Enrichment → Natural Language Response, combining the flexibility of MCP with the structure, explainability, and knowledge-centric design of Holon Graph Architecture.
