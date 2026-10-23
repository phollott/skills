# PLIS Cloud Application Architecture

**Decoupling application scaling from the current fixed WebLogic zone/cluster topology**.

The current design—three Lab Put instances and two GET/LSM instances across two zones—provides useful capacity and failover, but it is largely a **static capacity model**. A cloud-enabled, REST/FHIR-based service design can preserve high availability while scaling each workload independently according to demand.

## Target operating model

Separate the application into independently deployable and scalable services:

| Service | Primary workload pattern | Recommended scaling signal |
|---|---|---|
| **Lab Put / ingestion API** | Real-time daytime ingest, concentrated in the 8-hour processing window | Requests/sec, concurrent requests, processing latency, database connection-pool usage, queue depth if introduced |
| **Get API** | Continuous, read-oriented retrieval | Requests/sec, p95/p99 latency, CPU/memory, connection-pool utilization |
| **Lab Summary API** | Continuous plus overnight cache warm-up | Request concurrency, query duration, response latency, cache hit rate, database-read pressure |
| **Cache warming worker** | Throttled overnight background workload | Work queue depth, target completion time, capped database sessions/requests per second |

This permits proactive scaling—for example, increasing minimum Lab Put capacity ahead of the known daytime ingestion period—while scaling Get and Lab Summary capacity for interactive use or controlled cache warming.

Azure’s container services can autoscale HTTP workloads using concurrent-request rules and can scale against custom/event metrics through KEDA-compatible triggers. Those controls can support separate scaling profiles for request-driven APIs and queue-driven background workers. ([learn.microsoft.com](https://learn.microsoft.com/en-us/azure/container-apps/scale-app?utm_source=openai))

## Important qualification: do not remove zones from the design

The goal should not be to eliminate availability-zone awareness. It should be to remove the **application’s dependence on fixed, manually managed cluster members**.

A better pattern is:

- deploy each stateless service across at least two availability zones;
- place a managed load balancer/API gateway in front;
- use health checks and automated replacement of unhealthy instances;
- set a non-zero minimum replica count for critical real-time services;
- autoscale upward during known demand windows and unexpected peaks;
- use a separate, throttled worker deployment for overnight cache warming;
- keep the database connection pool bounded per service instance.

In other words: **zone-resilient deployment, but elastic service capacity**.

## REST/FHIR changes the integration contract, not necessarily the workload

Moving from SOAP/HL7v3 Put/Get/LSM services to REST and FHIR equivalents using HAPI FHIR is a material modernization, but the underlying operational behavior remains comparable:

- Lab Put remains a write/ingestion path.
- Get remains a point-read/retrieval path.
- Lab Summary remains a potentially complex read/summary path.
- The Oracle database remains the system of record.
- The PLIS database workload remains driven by the same business events, data size, stored-data retention, and real-time service expectations.

FHIR supports RESTful reads, searches, creates, updates, and operations; it also supports Bundles for batch or atomic transaction processing. Transaction Bundles execute as all-or-nothing units, whereas batches allow individual operations to succeed or fail independently. That distinction should be made deliberately for lab-result submission workflows. ([hl7.org](https://hl7.org/fhir/http.html?utm_source=openai))

## Design implications for the FHIR/HAPI layer

### 1. Do not assume REST/FHIR is automatically lighter

REST and FHIR may simplify integration and improve interoperability, but a FHIR request can be more computationally expensive than the legacy equivalent if it requires:

- JSON/XML parsing and validation;
- resource mapping between FHIR and PLIS data structures;
- profile and terminology validation;
- conditional creates/updates;
- multiple resource writes per clinical event;
- FHIR search translation into broad Oracle queries;
- creation and storage of full FHIR resource history/audit payloads.

The new architecture may reduce middleware and nonfunctional overhead, but its performance must be proven under peak workload. Size initial cloud production for the current or worst credible transitional workload—not presumed FHIR efficiency gains.

### 2. Keep the FHIR API tier stateless

The FHIR/HAPI service instances should not maintain durable session or cache state locally. Use shared managed services where needed:

- distributed cache for frequently reused reads/summaries;
- durable queue or event stream for non-immediate processing;
- centralized observability;
- shared configuration and secrets management.

This allows safe horizontal scale-out and zone replacement.

### 3. Bound database connections—not just HTTP requests

Autoscaling API pods/instances can unintentionally overwhelm Oracle if every new instance opens a large JDBC pool.

Set explicit limits for:

- maximum replicas per service;
- maximum JDBC connections per replica;
- total Oracle sessions allowed for each workload class;
- cache-warming concurrency;
- request timeouts, retry count, and circuit-breaker behavior.

The database should be protected through pool sizing and workload controls, rather than relying on the database to absorb unlimited application elasticity.

### 4. Make Lab Put idempotent

Autoscaling, load balancing, network retries, and failover mean a client may submit the same result more than once.

The FHIR ingestion design should use a stable business identifier and an explicit duplicate/update policy, such as conditional create or conditional update where appropriate. FHIR transactions and conditional interactions must be designed carefully because they can add database lookup and locking overhead. ([hl7.org](https://hl7.org/fhir/http.html?utm_source=openai))

### 5. Treat Lab Summary as a dedicated query product

Do not expose unrestricted generic FHIR search as the primary implementation of every Lab Summary request.

For frequently used summaries:

- define bounded API operations or well-governed query parameters;
- use partition-aware, indexed stored procedures or optimized query services;
- maintain precomputed summaries or cache entries where justified;
- enforce pagination, date limits, and query-cost controls;
- retain throttling for cache-warming traffic.

This keeps the shift to FHIR from inadvertently turning efficient legacy summary procedures into expensive broad searches over a 20+ TB Oracle repository.

## Impact on the RAC/Exadata discussion

This modernization generally **weakens—not strengthens—the case for RAC solely to scale application traffic**.

With the new architecture:

- application scale-out occurs in the REST/FHIR service tier;
- API instances can scale independently for Put versus Get/Lab Summary;
- cache warming can use a separately throttled worker pool;
- failures of individual application instances are handled by load balancing and replica replacement;
- database connection load can be actively controlled.

That means RAC should remain an **Oracle database availability/maintenance decision**, not an application-tier scalability requirement.

Exadata may still be justified if the database evidence shows it is needed for:

- database-node-failure continuity beyond a brief failover;
- rolling database maintenance with minimal interruption;
- significant Oracle I/O, CPU, or query-performance requirements;
- strict recovery objectives;
- an Azure-aligned Oracle-managed service model that wins on total cost and operational risk.

But “we need to scale Lab Put or Get/LSM services independently” is an argument for a **cloud-native application tier**, not for Exadata.

## Recommended assessment wording

> The future REST/FHIR architecture should replace the fixed WebLogic cluster model with independently scalable, stateless service tiers for Lab Put, Get, Lab Summary, and overnight cache warming. Services should be deployed across availability zones behind managed ingress and scaled using workload-specific metrics, while database connection pools and cache-worker concurrency remain explicitly bounded.  
>
> This architecture preserves zonal resilience while enabling capacity to align dynamically with known daytime ingestion demand and overnight cache activity. It also reduces the relevance of RAC as an application-scaling mechanism. RAC and Exadata should be evaluated separately for database-level availability, maintenance continuity, performance, managed-service value, and total cost.
