# PLIS Workload Profile

Assuming monthly volumes:

| Request type | Monthly | Average per day | Average per second* |
|---|---:|---:|---:|
| Put / ingest | 10 million | ~328,500 | ~3.8 |
| Get / retrieval | 4 million | ~131,400 | ~1.5 |
| Summary / reporting | 4 million | ~131,400 | ~1.5 |
| **Total** | **18 million** | **~591,000** | **~6.8** |

\*Average across a 30.4-day month, continuously. Real capacity must be based on peak periods—not this average.

Annualized, this is approximately:

- **120 million put requests**
- **48 million get requests**
- **48 million summary requests**
- **216 million total requests/year**

At **2.5 TB annual growth**, the implied net new stored data averages roughly **21 KB per put request** if puts broadly correspond to new retained data. That is only a rough planning indicator; actual database I/O can be much larger due to indexes, redo/undo, logging, LOBs, and updates.

# Cost comparison

For a production-grade deployment with high availability, backup, and disaster recovery, the expected **fully burdened cost** ranking is usually:

1. **Oracle on Azure VMs** — often lowest cloud infrastructure cost, but highest client operational responsibility.
2. **AWS RDS for Oracle BYOL** — typically higher platform cost than raw VMs, but lower operational cost because AWS manages much of the database infrastructure.
3. **Oracle Database@Azure / Exadata** — typically the highest-cost option, unless it replaces a substantial operational-support cost, consolidates multiple Oracle workloads, or has a demonstrated performance/availability requirement that avoids other costs.

That is a directional comparison, not a quote. A defensible dollar comparison requires a region, sizing, Oracle edition/options, HA/DR targets, retention, and a validated Oracle license position.

## What should be compared

The comparison should not be limited to monthly cloud infrastructure. Use a **five-year total cost of ownership (TCO)** model:

| Cost element | AWS RDS for Oracle BYOL | Oracle on Azure VMs | Oracle Database@Azure / Exadata |
|---|---|---|---|
| Database compute | RDS DB instance(s), normally primary plus Multi-AZ standby | Primary and Data Guard standby VMs | Exadata database compute: OCPU/ECPU consumption |
| Database storage | RDS storage, IOPS/throughput, backup/snapshot storage | Managed disks or ANF, plus backup storage and replication | Exadata/Exascale storage, backup storage, flash cache where applicable |
| Oracle licenses and support | Existing BYOL licenses, Oracle support, separately licensed options | Existing Oracle licenses, Oracle support, separately licensed options | BYOL or license-included; conversion ratios and included features must be validated |
| High availability | Managed Multi-AZ platform | Two VMs plus Data Guard design, configuration, monitoring, and testing | Included service architecture, but configuration and DR scope still affect cost |
| Disaster recovery | Cross-region replica/restore design, additional license and infrastructure where needed | Second-region infrastructure, Data Guard/backup replication, networking | Oracle-provided DR architecture and cross-region service scope |
| Operations | Lower: AWS manages core platform tasks | Higher: client or replacement provider manages Oracle and OS operations | Lower: Oracle manages Exadata/service infrastructure |
| Cloud/platform integration | New AWS landing zone, networking, security, monitoring, skills | Uses existing Azure landing zone and services | Uses Azure marketplace, Azure networking, and OCI/Oracle service operations |
| Migration | Assessment, conversion, testing, cutover | Assessment, migration, build, testing, cutover | Assessment, Oracle onboarding/private offer, migration, testing, cutover |

## Directional cost view

| Option | Infrastructure cost | Oracle licensing exposure | Client / support operating cost | Overall TCO expectation |
|---|---|---|---|---|
| **AWS RDS BYOL** | Medium | Medium to high | Low to medium | **Potentially competitive** if managed operations replace the current support vendor and AWS is acceptable |
| **Azure VMs** | Low to medium | Medium to high | High unless the client has an internal DBA/platform team | **Can be lowest**, but only if internal operations are genuinely available and costed |
| **Database@Azure / Exadata** | High | Medium to high, depending on BYOL conversion and options | Low to medium | **Usually highest**, but may be justified for consolidation, demanding SLOs, or a favorable negotiated offer |

## 1. AWS RDS for Oracle BYOL

### Cost strengths

- The client pays for a managed RDS service rather than separately staffing or contracting for many routine infrastructure activities.
- AWS manages provisioning, backups, patching processes, monitoring, hardware scaling, and Multi-AZ failover infrastructure. ([aws.amazon.com](https://aws.amazon.com/rds/oracle/?utm_source=openai))
- Reserved pricing and Database Savings Plans can reduce predictable production costs; AWS states RDS Reserved Instances can provide up to 48% savings versus on-demand pricing, depending on the commitment model. ([aws.amazon.com](https://aws.amazon.com/rds/oracle/?utm_source=openai))

### Cost watch-outs

- **BYOL does not eliminate Oracle cost.** The client must retain appropriate Oracle licenses and active Software Update License & Support for the selected edition, instance class, and separately licensed features. ([docs.aws.amazon.com](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Oracle.Concepts.Licensing.html?linkId=448078997&sc_campaign=Support&sc_channel=sm&sc_content=Support&sc_country=global&sc_geo=GLOBAL&sc_outcome=AWS+Support&sc_publisher=REDDIT&trk=Support&utm_source=openai))
- For a production Multi-AZ RDS BYOL deployment, Oracle licensing is needed for both the primary and standby instances. This is a major TCO item. ([docs.aws.amazon.com](https://docs.aws.amazon.com/pdfs/prescriptive-guidance/latest/migration-oracle-database/migration-oracle-database.pdf?utm_source=openai))
- Storage, provisioned IOPS/throughput, backup retention, snapshots, data transfer, and optional reporting replicas all add cost. AWS notes that Multi-AZ synchronous replication doubles write I/O. ([aws.amazon.com](https://aws.amazon.com/rds/oracle/pricing/?utm_source=openai))
- If the Java application tier remains in Azure, network connectivity, latency, egress, security controls, and a second-cloud operating model must be priced—not just the RDS service.

### Interpretation for this client

RDS is potentially the best answer if the main goal is to **replace the current operational support partner with a cloud-managed operating model**. It is likely more expensive than raw Azure VMs at the infrastructure layer, but the managed-service value may offset the cost of a replacement DBA/operations provider.

---

## 2. Oracle on Azure Virtual Machines

### Cost strengths

- The client can use its existing Azure commercial construct, landing zone, network, identity, monitoring, and support model.
- Azure VM infrastructure is generally the most flexible option for rightsizing compute, storage, and commitment discounts.
- Oracle workloads on Azure VMs are BYOL: the client is charged for Azure compute, storage, and networking, while maintaining the required Oracle license and support agreement. ([learn.microsoft.com](https://learn.microsoft.com/en-us/azure/virtual-machines/workloads/oracle/oracle-vm-solutions?utm_source=openai))
- Azure supports constrained-core VM configurations, which can provide the memory, storage, and I/O of a larger VM while limiting the licensed vCPU count—potentially important for Oracle Enterprise Edition licensing. ([learn.microsoft.com](https://learn.microsoft.com/en-us/azure/virtual-machines/workloads/oracle/oracle-vm-solutions?utm_source=openai))

### Cost watch-outs

- The apparent infrastructure savings can be misleading if operations are excluded.
- A resilient design requires at least:
  - a primary database VM;
  - a Data Guard standby VM in another Availability Zone;
  - separate backup storage;
  - monitoring, security, patching, and recovery tooling;
  - potentially a second-region DR environment.

Microsoft’s Azure guidance describes Oracle HA/DR on Azure as requiring separate database VMs and Data Guard/Active Data Guard or comparable design; Azure remains responsible for the VM platform, while the customer is responsible for implementing the database HA/DR solution. ([learn.microsoft.com](https://learn.microsoft.com/en-us/azure/virtual-machines/workloads/oracle/oracle-overview?utm_source=openai))

- Cross-region Data Guard redo transport has a published Azure network charge; Microsoft cites US$0.02/GB for remote-region redo transport, while same-region availability-zone redo transport has no charge. ([learn.microsoft.com](https://learn.microsoft.com/en-us/azure/virtual-machines/workloads/oracle/oracle-azure-vms-faq?utm_source=openai))
- The client must explicitly include the cost of database operations, either through internal staff or a new managed-services provider:
  - Oracle patching and upgrades;
  - RMAN backup and restore testing;
  - Data Guard monitoring and failover;
  - performance tuning;
  - capacity management;
  - security hardening and audit support;
  - 24×7 incident coverage.

### Interpretation for this client

Azure VMs may have the **lowest direct cloud bill**, but they do **not** inherently meet the objective of shifting operational work from the current support vendor to the cloud provider. They are the lowest-cost choice only if the client has, or deliberately wants to build, an internal Oracle operations capability—or contracts a new provider and still finds that model cheaper.

---

## 3. Oracle Database@Azure / Exadata

### Cost strengths

- It is Azure-aligned and purchased through Azure Marketplace; Oracle states that this spend can count toward the Microsoft Azure Consumption Commitment (MACC). ([learn.microsoft.com](https://learn.microsoft.com/en-us/azure/oracle/oracle-azure-overview?utm_source=openai))
- It shifts more database platform and engineered-infrastructure responsibility to Oracle than the Azure VM model.
- It can be purchased as BYOL or license-included, and Oracle offers private pricing based on contract term, commitment, and number of Exadata deployments. ([docs.oracle.com](https://docs.oracle.com/en-us/iaas/Content/database-at-azure/getting-started-private-offer.htm?utm_source=openai))
- For customers with qualifying Oracle support spend, Oracle Support Rewards may offset a portion of the Oracle technology support bill. ([oracle.com](https://www.oracle.com/engineered-systems/exadata/database-service/faq/?utm_source=openai))

### Cost watch-outs

- Exadata has a materially different cost structure from a VM database:
  - **Dedicated Exadata** includes Exadata infrastructure charges plus enabled database OCPU charges.
  - **Exadata Exascale** includes database ECPU charges plus separately metered infrastructure, smart database storage, VM filesystem storage, and optional flash cache. ([oracle.com](https://www.oracle.com/contracts/docs/oracle_database_azure_credits_service_descriptions_v121123.pdf?download=true&utm_source=openai))
- Oracle’s pricing is generally quote-based/private-offer based for Database@Azure. Public list prices alone will not be sufficient for a decision. ([docs.oracle.com](https://docs.oracle.com/en-us/iaas/Content/database-at-azure/getting-started-private-offer.htm?utm_source=openai))
- Exadata may offer operational and performance benefits, but it should not be assumed to be cheaper merely because it is managed or because the organization is Azure-first.
- The client still needs technical governance for schema, stored procedures, performance, access management, releases, recovery requirements, and vendor escalation.

### Interpretation for this client

Database@Azure is strategically attractive because it supports the two stated goals:

- remain aligned to Azure; and
- reduce dependency on the current operational support vendor.

However, the client should require Oracle to demonstrate that the additional Exadata cost delivers measurable value compared with RDS or Azure VMs.

---

## Recommended TCO scenarios

Request pricing in three comparable scenarios:

### Scenario A — AWS managed baseline

- RDS for Oracle BYOL, Multi-AZ.
- Current 20 TB plus five-year projected growth.
- Production backup retention and immutable/recovery copy.
- Cross-region DR option.
- Java application tier in AWS, or explicitly cost secure connectivity to Azure.
- Include Oracle licenses for both Multi-AZ database instances.

### Scenario B — Azure self-managed baseline

- Oracle Enterprise Edition on a right-sized Azure VM.
- Data Guard standby in a second Availability Zone.
- Backup and regional DR design.
- Azure monitoring, storage, security, networking, and support plan.
- Internal staffing or replacement managed-service-provider cost.
- Oracle license model, including constrained-core sizing and standby/DR rights validation.

### Scenario C — Database@Azure / Exadata managed proposal

Require Oracle to provide:

- a recommended Exadata configuration and a smaller viable configuration;
- BYOL and license-included alternatives;
- dedicated-infrastructure and Exascale options where available;
- production HA, regional DR, backup, and retention assumptions;
- Oracle support and operational responsibilities;
- five-year committed and on-demand pricing;
- all migration, onboarding, network, and exit costs;
- the exact Oracle features assumed to be included under the BYOL model.

## Recommended decision rule

For this client, compare the options using **fully burdened five-year TCO**, not cloud resource cost alone:

> **Azure VMs** should win only if the client accepts the responsibility and cost of operating Oracle, internally or through a new provider.  
> **AWS RDS BYOL** should win if minimizing database operational dependence is more important than remaining single-cloud Azure.  
> **Database@Azure / Exadata** should win only if Oracle’s managed, Azure-aligned service delivers a clear advantage in service levels, operational-risk reduction, consolidation, or total cost that exceeds its likely premium.

The most important input is the client’s current operational-support contract cost. If that contract is substantial, RDS or Database@Azure may compare far better than a simple infrastructure-only calculation suggests.


# PLIS Database Feasibility Assessment for not using Exadata

This is now a **meaningful transactional production workload**, though it is still not automatically a case for Exadata.

The key question becomes: **what does peak look like?**

For example, if most results arrive during an 8-hour laboratory processing window, average load during that window is closer to:

- ~**11.4 puts/second**
- ~**4.6 gets/second**
- ~**4.6 summary requests/second**
- ~**20.6 requests/second total**

If traffic is concentrated in a 2-hour batch window, it becomes roughly **82 requests/second** before considering concurrent users, retries, report query cost, or batch work. Peak surges could be materially higher.

For Oracle, the hard part is likely not raw request count. It is:

- write amplification from redo/undo and index maintenance;
- transaction size and commit frequency;
- LOB/document storage and retrieval behavior;
- concurrency during lab-result ingestion;
- complexity and scan volume of the 4M monthly summary requests;
- reporting queries competing with inserts;
- RPO/RTO, auditability, and backup/restore requirements.

## Recommendation

### 1. Oracle on AWS RDS BYOL — still the default first choice, if compatible

RDS remains a credible primary option if:

- peak write throughput is within a conventional Oracle managed-service profile;
- summary workloads are well-indexed, partitioned, pre-aggregated, or moved to a reporting path;
- the application does not require host-level Oracle administration or unsupported integrations;
- the organization accepts RDS operational restrictions.

At this request volume, RDS should not be ruled out based solely on throughput. A properly sized Multi-AZ Oracle RDS deployment with good schema design, partitioning, storage performance, and reporting separation may be entirely adequate.

### 2. Oracle on Azure VMs — strongest full-control option

Azure VMs become attractive if you need:

- full Oracle administrative control;
- custom backup, monitoring, encryption, agent, or filesystem integrations;
- a more direct lift-and-shift of the existing Oracle estate;
- detailed tuning of storage, memory, OS, and Oracle settings;
- custom Data Guard topology and disaster-recovery control.

For this workload, a properly designed Oracle-on-Azure-VM setup with **Data Guard across availability zones** is technically realistic. The tradeoff is that your organization owns patching, operating-system hardening, monitoring, RMAN recovery, failover processes, and 24×7 database operational responsibility.

### 3. Oracle Database@Azure / Exadata — assess, but do not assume it is necessary

The revised monthly volumes make a serious Exadata assessment reasonable, especially if the application is clinically critical and summary queries are resource-intensive. However, the stated figures alone still do **not** justify Exadata.

Database@Azure / Exadata becomes compelling if one or more of the following is true:

- current on-premises Oracle is already on Exadata and depends on its performance profile;
- ingestion peaks are in the hundreds or thousands of transactions per second;
- summary queries run against very large historical result sets with high concurrency;
- strict service objectives require minimal operational risk and very fast recovery;
- multiple Oracle databases can be consolidated onto the platform;
- Azure proximity is required for application services, analytics, identity, and network governance;
- Oracle’s commercial proposal is competitive after including licenses, HA/DR, operations, and support.

Otherwise, it may be an expensive solution to a problem that a well-designed RDS or Azure VM deployment can solve.

That makes the workload profile more favorable for a conventional cloud Oracle deployment.

## Final workload characterization

- ** real-time lab-result ingestion, Gets, and Lab Summary requests.
  - This is the critical latency-sensitive period.
  - Puts average about **11.4/sec** over the 8-hour window, but sizing must use the observed peak 5–15 minute rate.
  - Get and Summary calls run concurrently through Java calling Oracle stored procedures.

- ** the same Get and Lab Summary stored-procedure paths are used for cache warming, but the workload is **throttled**.
  - It is a controlled background read workload rather than an uncontrolled batch spike.
  - It should be scheduled and rate-limited so it yields to backups, maintenance, redo/archive processing, and the next day’s real-time operating window.

## Implication for platform choice

There is **no workload evidence yet that requires Exadata**.

The real-time daytime window—not overnight caching—is the architecture and sizing driver. At the volumes described, the likely limiting factors are:

- peak daytime stored-procedure concurrency;
- p95/p99 response-time requirements;
- efficiency of the Lab Summary SQL;
- indexing and partitioning of the results repository;
- average/max payload or LOB size;
- connection-pool/session management in the Java tier;
- HA/DR objectives.

Throttled overnight cache warming should be manageable on either RDS or Azure VMs, provided it is operationally bounded.

## Recommended decision position

### Preferred: Oracle on AWS RDS BYOL, if compatibility passes

This should be the leading option if:

- the Java tier uses standard JDBC connections to PL/SQL stored procedures;
- Oracle options and stored-procedure dependencies are supported in RDS;
- no OS access, unrestricted SYSDBA access, external procedures, Oracle JVM-in-database, or custom filesystem/agent dependency is required;
- the application can run in AWS close to the database;
- managed Multi-AZ availability, backups, and patching are desirable.

The workload is well suited to a managed database model: real-time OLTP during business hours and rate-controlled read-oriented cache warming overnight.

### Strong alternative: Oracle on Azure VMs

Choose this when the primary requirement is **full self-operation and full Oracle control**, not because the workload demands it.

It is the better choice if you need:

- custom Oracle host/database configuration;
- unrestricted operational tooling or diagnostic access;
- custom backup, monitoring, security, or scheduling integrations;
- a close lift-and-shift migration;
- full control over Data Guard topology, patch timing, and storage layout;
- tight alignment with an Azure-hosted Java ecosystem.

### Conditional: Oracle Database@Azure / Exadata

Keep this as an evaluated option, but require Oracle to substantiate why it is needed.

For the stated design, it should only be selected if a realistic benchmark shows that RDS or Azure VMs cannot meet:

- real-time daytime p95/p99 latency;
- peak ingest and summary concurrency;
- required RPO/RTO and failover behavior;
- growth performance as data expands beyond 20 TB;
- operational requirements that make Oracle-managed Exadata materially safer or less costly.

“Large database” and “Oracle recommendation” are not sufficient reasons by themselves.

## Practical architecture guidance

1. **Prioritize the daytime real-time path**
   - Set explicit SLOs for lab-result ingest, Get, and Lab Summary procedures.
   - Test at simultaneous peak put/get/summary concurrency.
   - Keep the Java tier and Oracle database in the same cloud region and private network.

2. **Control the overnight process**
   - Maintain a hard cap on cache-warming workers and requests/sec.
   - Pause or reduce it automatically if daytime load begins, latency rises, or maintenance/backup windows are active.
   - Monitor cache-warm completion time and database resource consumption.

3. **Optimize the stored procedures**
   - Inspect the SQL plans underlying Get and Lab Summary calls.
   - Partition large time-based clinical-result tables.
   - Confirm partition pruning and index usage.
   - Use bind variables, stable execution plans, and current optimizer statistics.
   - Avoid recalculating the same summary for multiple cache keys where results can be shared.

4. **Separate analytics from operational queries**
   - Keep operational summaries efficient and bounded.
   - Send broad historical, ad hoc, or population-level analytics to a reporting/analytics platform rather than the real-time transactional primary.

5. **Test failover behavior**
   - Validate Java connection retry behavior during Multi-AZ failover or Data Guard role transition.
   - Confirm transaction idempotency for puts so retries do not create duplicate lab results.

## Concise conclusion

A **managed Oracle RDS BYOL deployment is likely technically feasible** for this workload, assuming RDS compatibility and successful performance validation. **Azure VMs** are appropriate if self-management and unrestricted Oracle control are essential. **Database@Azure / Exadata is not currently justified by the workload description**; it should be chosen only after a proof of concept demonstrates a measurable performance, resiliency, or operational advantage.
