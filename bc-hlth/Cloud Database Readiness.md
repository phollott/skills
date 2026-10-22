# PLIS Cloud Readiness Assessment

## Revised workload profile

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

## Impact on the cloud-platform decision

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

## Updated recommendation

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
