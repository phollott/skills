# Longitudinal Family Physician (LFP) Enhancements

Below are five distinct architectural approaches for implementing the full LFP capability—including policy enforcement, sequencing, claim history, cross-setting controls, reporting, and operational support tooling. The key decision is not only where the **rules** run, but where the platform holds **state**, manages **process sequencing**, and records the authoritative **adjudication outcome**.

## Comparison criteria for an options analysis

Use criteria that reflect the real problem, not only product preference:

| Criterion | Key question |
|---|---|
| LFP policy completeness | Can the option represent the policy accurately and explain outcomes? |
| Sequencing and execution | Can it explicitly manage decision order, precedence, re-adjudication, and exceptions? |
| Claim history and state | Can it safely support prior-payment checks, limits, corrections, reversals, and cross-setting enforcement? |
| Financial control | Can it prevent duplicate/incorrect payment and support reconciliation? |
| Mainframe-exit progress | Does it reduce dependency, or deepen it? |
| Time to value | Can it stabilize known Phase 1 gaps soon enough? |
| Operational supportability | Can client operations own, monitor, troubleshoot, and change it? |
| Vendor/skills risk | Does it create dependence on scarce skills or a single implementer? |
| Reuse potential | Can its APIs, audit model, data model, and patterns be reused beyond LFP? |
| Cost and transition debt | What is the total cost now, later migration cost, and cost if later phases never occur? |

## Options Analysis

For a discovery engagement, the likely output should not be a premature platform recommendation. It should determine whether the deferred LFP scope is small enough for Option 1, substantial enough to justify Option 3, or best served by the **Option 2 transitional split**.

| Option | Core idea | Mainframe exit contribution | Near-term delivery risk |
|---|---|---:|---:|
| 1. Complete LFP in the incumbent stack | Extend IBM/COBOL/Aion and legacy database | Low | Low–medium |
| 2. Modern service, legacy system remains financial authority | Java-based LFP flow with modern rules/orchestration; legacy databases and posting retained initially | Medium | Medium |
| 3. Modern LFP adjudication domain with independent history | New LFP decisioning, orchestration, and LFP history/ledger; controlled integration to legacy payment | High | Medium–high |
| 4. Packaged decision/claims platform for LFP | Implement LFP in a commercial rules/claims product | Medium–high | High |
| 5. Hybrid Salesforce workflow + external decisioning | Salesforce for case/workflow/operations; dedicated adjudication services for decisions and state | Medium | Medium–high |

A practical architecture-board framing would be:

- **Option 1** is the lowest-risk stabilization path, but with the least modernization value.
- **Option 2** is likely the most realistic transitional architecture if the goal is to route LFP through a new flow while preserving existing financial authority.
- **Option 3** is the strategic modernization path, but should only be selected with funding, ownership, and operational commitment.
- **Option 4** is appropriate only if there is a genuine enterprise platform case, not simply a desire to replace Aion.
- **Option 5** should be considered for workflow and operational experience, not assumed to replace core adjudication.

### 1. Complete LFP in IBM / COBOL / Aion / legacy database

**Description**

Implement the deferred scope where the existing DPP adjudication capability already runs:

- Aion rules for LFP policy
- COBOL or existing mainline logic for sequencing and execution
- Mainframe database/history structures for claim history and retention
- Existing batch/run-control mechanisms for operational controls
- Existing reporting and operational-support tooling, extended as needed

```text
Provider claim intake
    ↓
DPP mainline / COBOL orchestration
    ↓
Aion LFP policy and rule execution
    ↓
Legacy claims history and database
    ↓
Existing payment/remittance/reporting processes
```

**Strengths**

- Lowest disruption to established claims operations.
- Likely fastest route to completing deferred Phases 2 and 3.
- Reuses known production controls, financial posting, history, remittance, and recovery processes.
- Avoids immediate cross-platform data synchronization and dual-write problems.
- May be the lowest-cost option in the short term.

**Concerns**

- Invests further in the platform the organization ultimately wants to leave.
- Can increase the later mainframe-exit cost by adding more Aion-specific logic, state, controls, and operational dependency.
- Does not naturally improve API enablement, vendor integration, cloud adoption, or modern DevOps.
- Specialized Aion/COBOL/mainframe skills may remain a long-term operating risk.
- Policy, sequencing, and data dependencies may stay difficult to expose, test, explain, and reuse.

**When this is appropriate**

- LFP has urgent operational or financial needs.
- Mainframe exit funding or sponsorship is not yet credible.
- The goal is stabilization, not modernization.
- The work can be isolated and documented as intentional legacy debt.

**Essential guardrails**

- Capture policy, rules, sequencing, data dependencies, and regression tests outside Aion in reusable documentation/repositories.
- Avoid new direct database integrations for external consumers.
- Define future-facing business API contracts even if they are initially implemented behind the mainframe.
- Record the incremental Aion/mainframe debt introduced and its long-term support cost.

---

### 2. Java-based LFP adjudication service with legacy data and payment authority retained

**Description**

Create a new LFP-specific service outside the mainframe. It owns LFP routing, context assembly, rules, sequencing, decision trace, and integration logic. The existing DPP/mainframe environment remains authoritative for claim persistence, financial posting, payment, and perhaps history during the transition.

```text
Claim intake
    ↓
LFP routing service
    ↓
Java LFP adjudication service
    ├─ context assembly
    ├─ explicit sequencing/orchestration
    ├─ DMN/rules evaluation
    └─ decision evidence
    ↓
Legacy data-access API / adapter
    ↓
Mainframe claim history + financial posting
```

**Strengths**

- Begins extracting a real adjudication boundary from the mainframe.
- Enables modern engineering: APIs, CI/CD, automated tests, versioning, telemetry, container deployment, and decision trace.
- Makes sequencing explicit rather than implicit in Aion or batch control flow.
- Can support shadow-mode comparison before it becomes authoritative.
- Creates reusable patterns for later medical-services, pharmaceutical, or special-authority modernization.

**Concerns**

- Still depends on legacy data and financial transactions.
- Requires careful idempotency, concurrency, recovery, and reconciliation design.
- Can become a fragile “wrapper around the mainframe” if the service directly uses legacy schemas and stored procedures.
- May introduce dual logic if both Aion and the new service adjudicate overlapping scenarios.
- Requires a clear operating model across teams and vendors.

**When this is appropriate**

- The organization wants tangible mainframe-exit progress without attempting a full claims-platform replacement.
- LFP is bounded enough to become a distinct processing path.
- There is appetite for Java/API/cloud-native engineering and support capability.

**Essential guardrails**

- Put a business-oriented data-access API between the Java service and legacy database/stored procedures.
- Keep one authoritative writer for claim/payment state—initially probably the mainframe.
- Persist a distinct LFP decision record with rule version, inputs, history facts, outcome, and reason codes.
- Run in parallel/shadow mode and reconcile outcomes before financially binding cutover.

---

### 3. Modern LFP adjudication domain with independent LFP history and ledger

**Description**

Build LFP as a self-contained adjudication domain. The new platform owns LFP claim intake, context, policy/rules, sequencing, LFP history, accumulators, decision evidence, operational control, and possibly LFP payment instructions. The mainframe is integrated only for transitional data, payment, remittance, or enterprise claims visibility.

```text
Claim intake / routing
    ↓
LFP adjudication domain
    ├─ decision service and rules
    ├─ orchestration / sequencing
    ├─ LFP history and accumulators
    ├─ audit and decision evidence
    ├─ exception handling
    └─ reporting and operational control
    ↓
Payment/remittance integration
    ↓
Legacy DPP during transition, successor financial capability later
```

**Strengths**

- Most meaningful progress toward mainframe exit.
- Avoids making future LFP capability dependent on legacy database semantics.
- Allows an explicit LFP history model supporting limits, reversals, corrections, re-adjudication, and cross-setting enforcement.
- Provides clearer ownership, API boundaries, audit evidence, and operational controls.
- Creates a potential template for future adjudication domains.

**Concerns**

- This is materially more than a rules-engine implementation.
- Requires difficult design choices around authoritative state, payment control, reversals, correction handling, reconciliation, and data migration.
- Higher initial cost and longer delivery timeline.
- Needs mature production support, security, resilience, and financial-control capabilities.
- Risk of creating a second claims platform if boundaries with DPP are not explicit.

**When this is appropriate**

- LFP is strategically important and likely to continue evolving.
- The organization has credible commitment to mainframe exit.
- The deferred scope is substantial enough that building it in Aion would materially increase future migration cost.
- There is funding for a multi-release modernization path.

**Essential guardrails**

- Define precise boundaries between LFP and the existing DPP claims system.
- Make one platform authoritative for LFP-specific payment status, history, and accumulators.
- Design correction, reversal, re-adjudication, and reconciliation before going live.
- Do not attempt to generalize immediately into a universal claims replacement platform.

---

### 4. Implement LFP in a commercial decisioning or claims platform

**Description**

Select a commercial platform to provide some combination of rules management, decision tables, policy controls, workflow, orchestration, claims history, and operational tooling. Integrate it with DPP/mainframe and surrounding applications.

Possible platform categories include:

- Enterprise decision-management / BRMS products
- Claims-administration platforms
- Payment-integrity / claims-edit platforms
- Business-process and case-management suites

```text
Claim intake
    ↓
Commercial decisioning / claims platform
    ├─ policy/rule management
    ├─ sequencing/workflow
    ├─ history or state capability
    └─ audit/reporting
    ↓
Legacy/mainframe integration during transition
```

**Strengths**

- May accelerate delivery of rule governance, decision tables, authoring tools, audit, workflow, and operational features.
- Can reduce custom software development for common capabilities.
- May offer mature business-user tooling, vendor support, and implementation accelerators.
- Could provide a broader platform foundation beyond LFP.

**Concerns**

- Product fit may be poor for B.C.-specific LFP policy and DPP adjudication semantics.
- Configuration can become as opaque and hard to operate as custom code.
- Licensing, implementation, data-storage, and vendor costs can be substantial.
- A product can create a new vendor lock-in and migration challenge.
- A platform selection and implementation could delay urgent LFP stabilization.
- Commercial products may still require substantial custom integration, data work, and operational design.

**When this is appropriate**

- The organization has a broader claims-modernization mandate beyond LFP.
- Multiple adjudication domains could use the same platform.
- There is a realistic enterprise product-selection process and long-term operating model.
- The client is willing to invest in vendor/product governance and internal capability.

**Essential guardrails**

- Prove the platform using real representative LFP scenarios, history-dependent decisions, corrections, reversals, and operational failure cases.
- Require exportable decision assets, test cases, audit records, and data.
- Do not let vendor configuration become the only source of policy knowledge.
- Confirm that the client can operate the product after implementation-vendor transition.

---

### 5. Salesforce-led workflow with external adjudication services

**Description**

Use Salesforce/Health Cloud primarily for intake, operational workflow, exception handling, approvals, provider/citizen interaction, and reporting. Keep high-volume adjudication, claim history, sequencing, and financial state in dedicated services outside Salesforce.

```text
Provider / citizen / operations interaction
    ↓
Salesforce workflow and case management
    ↓
External LFP adjudication APIs
    ├─ rules/DMN
    ├─ sequencing/orchestration
    ├─ claim history / ledger
    └─ audit evidence
    ↓
DPP/mainframe payment and remittance during transition
```

**Strengths**

- Builds on the client’s existing Salesforce investment.
- Strong fit for manual review, exception handling, correspondence, approvals, service requests, appeals, and operational dashboards.
- Can improve the human and operational experience around LFP.
- Lets Salesforce remain the system of engagement rather than forcing it to become the core financial adjudication engine.

**Concerns**

- Does not remove the need for a separate adjudication/history platform.
- Salesforce customization and operational handover risks are already known from prior experience.
- Can create duplicated state if claim/decision information is not carefully projected from the authoritative adjudication platform.
- Not ideal as the sole engine for high-volume, history-sensitive, financially binding claims execution.

**When this is appropriate**

- LFP has substantial exception handling, manual review, provider communication, or operational coordination needs.
- Salesforce is strategically supported and the operating model can be improved.
- The architecture preserves a clear system-of-record boundary outside Salesforce.

**Essential guardrails**

- Salesforce consumes adjudication events and exposes work; it does not become the authoritative claims ledger.
- Define what data is replicated into Salesforce and why.
- Keep policy/rules, financial state, and claim-history authority outside Salesforce unless a narrow case proves otherwise.
- Require robust DevOps, documentation, support readiness, and vendor-transition planning.

---

### A sixth variation worth noting: retain Aion temporarily behind an API

This is not a full replacement approach, but it can be a useful bridge:

```text
New LFP intake/orchestration service
    ↓
Decision API
    ↓
Aion initially behind adapter
    ↓
Modern rules service replaces Aion rule family over time
```

It improves integration boundaries but does **not** materially reduce Aion dependence until actual rule execution, history, and state move out.

## Modern Platform Architecture

A modern Java-based LFP architecture would center on an API-first adjudication service that receives or is routed eligible LFP claims from the existing intake path. The service validates and normalizes the claim into a canonical LFP/adjudication model, assigns an idempotency and correlation ID, and assembles the required context: provider and clinic eligibility, LFP enrolment, service/activity information, rates and effective dates, cross-setting facts, and relevant prior claim/payment history. This context is retrieved through business-oriented APIs or adapters—not through direct use of mainframe tables and stored procedures by every new component. The service would be deployed as a containerized Java application on the approved platform, with standard CI/CD, security, secrets management, automated testing, and Dynatrace instrumentation.

The actual decisioning should separate orchestration from policy. Java code or a BPMN-style workflow would explicitly manage the adjudication sequence: validation, eligibility, history/limit checks, policy evaluation, payment determination, pend/deny/approve routing, and downstream handoff. DMN decision tables would be a strong fit for transparent LFP policy decisions such as eligibility, rate selection, exclusions, limits, and reason codes; Drools could be used where genuine rule interaction is required. The result should be a versioned decision record containing the normalized claim, context facts used, policy/rule version, decision stages executed, outcome, reason codes, and any calculated payment recommendation. The mainframe can initially remain the authoritative writer for financial claim status, payment, and remittance, with the Java service submitting a controlled outcome through an adapter or API.

The architecture also needs supporting state and operations capabilities outside the rule engine: a durable decision-evidence store, an append-oriented LFP event/history model for reversals and re-adjudication, controlled retry/replay behavior, exception routing, reconciliation, and reporting. Salesforce could consume events to provide work queues, manual-review cases, provider communication, and operational dashboards, but should not be the financial ledger or primary adjudication runtime. Dynatrace would provide technical traces and dependency monitoring, while the adjudication platform retains the authoritative business audit trail. Over time, legacy adapters and mainframe-backed history can be replaced by modern claim-history and payment capabilities, allowing the LFP flow to become progressively independent without requiring an immediate full DPP replacement.

## Modern Health Standards

**API-first should be standards-based**, but that does **not** mean every LFP adjudication API must be FHIR. Establish enterprise API standards for contract-first design, versioned schemas, business-oriented resources, OpenAPI specifications, OAuth/OIDC-based service security, idempotency, correlation IDs, consistent errors/statuses, audit events, and testable contracts. The API should abstract mainframe tables and stored procedures rather than expose them. This aligns with Government of Canada API guidance to use common information models where appropriate, avoid raw backend data structures, make APIs discoverable, and design modular, loosely coupled services. ([canada.ca](https://www.canada.ca/en/government/system/digital-government/policies-standards/government-canada-enterprise-architecture-framework.html?utm_source=openai))

Use **FHIR selectively at health-system interoperability boundaries**—for example, when exchanging patient, practitioner, organization, encounter, medication, clinical-document, coverage, or authorization information with EMRs, pharmacy systems, clinical-review applications, or Salesforce Health Cloud. FHIR includes financial resources such as `Claim` and `ClaimResponse`; the latter represents adjudication results and can support re-adjudication and reversals. However, the FHIR financial resources are relatively less mature than core clinical resources, and LFP-specific concepts such as B.C. payment categories, cross-setting enforcement, operational controls, tariff calculations, and adjudication sequencing will need a constrained profile and likely extensions. FHIR is valuable only when a concrete Canadian/provincial profile, partner need, or reuse case justifies the added terminology and conformance work. ([hl7.org](https://hl7.org/fhir/claimresponse.html?utm_source=openai))

Inside the adjudication core, use concise **domain APIs and events** rather than forcing the rules engine to process a complete FHIR graph. For example: `SubmitLfpClaim`, `GetAdjudicationContext`, `EvaluateLfpDecision`, `RecordAdjudicationOutcome`, and `GetLfpHistory`. The internal `AdjudicationContext` should contain only the normalized, versioned facts required for the decision, while adapters translate from FHIR, EMR-specific formats, Salesforce, or legacy records at the edges. This gives the program a standards-based architecture without conflating “standards-based” with “FHIR everywhere,” and it preserves a clean migration boundary away from mainframe-specific data structures.

**a Java/Spring Boot service using HAPI FHIR could make sense for LFP**, but primarily as an **interoperability and information-access layer**, not as the complete adjudication runtime or financial system of record. For LFP, it could expose normalized clinical and administrative facts needed by the new adjudication flow: patient/client, practitioner, clinic/organization, coverage/eligibility, service context, relevant clinical evidence, and perhaps claim/request and adjudication-response representations. FHIR has relevant financial resources such as `Claim`, `ClaimResponse`, `Coverage`, `ExplanationOfBenefit`, and workflow patterns for re-adjudication, reversals, status, and payment-related interactions. ([build.fhir.org](https://build.fhir.org/financial-module.html?utm_source=openai)) This could be particularly useful at boundaries with EMRs, clinical systems, special-authority processes, or Salesforce Health Cloud.

However, I would avoid making the FHIR layer the place where all LFP-specific adjudication logic lives. LFP requires purpose-specific capabilities—payment sequencing, cross-setting enforcement, accumulators, concurrency control, duplicate prevention, reversals, re-adjudication, financial posting, and operational controls. A modern Java adjudication service should consume a compact internal `AdjudicationContext`, derived through the FHIR layer or other domain APIs, then execute explicit orchestration plus DMN/Drools rules. The service should persist its own decision evidence and events; it should not rely on a FHIR server alone to provide the financial ledger or audit model.

The RIM lineage is helpful for semantic consistency, but it should not become a constraint. HL7 describes the RIM as an abstract model created for HL7 standards development, explicitly **not** as a logical or physical database model. ([hl7.org](https://www.hl7.org/cda/stds/online-navigation/2024May/infrastructure/rim/rim.htm?utm_source=openai)) So use the existing RIM-informed Oracle model as a valuable starting point, map only the needed concepts into constrained FHIR profiles, and keep a clean anti-corruption layer between it and LFP adjudication. The practical target would be: **FHIR at clinical/interoperability edges; Java domain APIs and events in the adjudication core; Oracle-backed persistence where appropriate; and a controlled mainframe adapter until authoritative claims history and financial posting can move.**
