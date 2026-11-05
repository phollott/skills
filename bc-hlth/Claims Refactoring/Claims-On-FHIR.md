For an LFP-oriented medical claims system, the most relevant FHIR resources would be a **small, constrained set**—not the entire FHIR model. Use them mainly for interoperability and a normalized claims-context layer; keep the internal adjudication API and decision model focused on the facts needed for LFP.

## Core claims and adjudication

| Resource | Likely LFP use |
|---|---|
| **Claim** | Represents the provider’s submitted claim or LFP activity/payment request, including patient, provider/requestor, coverage, care team, service lines, dates, and submitted amounts. |
| **ClaimResponse** | Represents the adjudication result: complete/partial/queued/error outcome, line-level adjudication, reason/disposition, approved amounts, and references to the original claim. |
| **ExplanationOfBenefit** | Provider/citizen-facing or downstream reporting representation combining claim and adjudication information. It should not necessarily be the authoritative operational record. |
| **PaymentNotice** | Indicates that payment has occurred, is expected, or was cancelled. |
| **PaymentReconciliation** | Supports bulk payment/remittance reconciliation—linking payments to adjudicated claims or claim responses. |

FHIR distinguishes a `ClaimResponse`—the adjudication/authorization response—from a `PaymentReconciliation`, which associates payment amounts with adjudicated claims. A `ClaimResponse` alone does not prove payment occurred. ([hl7.org](https://hl7.org/fhir/R4B/paymentreconciliation.html?utm_source=openai))

## People, providers, clinics, and coverage

| Resource | Likely LFP use |
|---|---|
| **Patient** | The person receiving services. |
| **Practitioner** | The physician/provider as an individual. |
| **PractitionerRole** | The provider’s role, specialty, organization/clinic association, location, and potentially the effective period of a role—often more useful than `Practitioner` alone for eligibility context. |
| **Organization** | Clinic, health authority, insurer/payer, or other organizational participant. |
| **OrganizationAffiliation** | Where required, models relationships between organizations, such as clinic/network/program relationships. |
| **Coverage** | Patient-specific public or employment-based coverage/entitlement context. |
| **InsurancePlan** | Plan/product definition, if LFP needs a reusable representation of plan-level coverage information. |
| **RelatedPerson** | Potentially relevant where a non-patient individual is a claimant/contact, though probably not central to provider-service claims. |

`Coverage` is intended to represent the plan/coverage information for a specific individual, while `InsurancePlan` represents the broader plan definition. ([hl7.org](https://hl7.org/fhir/R4/coverage.html?utm_source=openai)) `PractitionerRole` is useful because practitioner roles can vary by organization and be time-bounded. ([fhir.hl7.org](https://fhir.hl7.org/fhir/practitioner.html?utm_source=openai))

## Care context and LFP-specific inputs

| Resource | Likely LFP use |
|---|---|
| **Encounter** | Optional context for a direct patient interaction, where relevant. |
| **EpisodeOfCare** | Potentially useful to represent an ongoing patient–organization/provider relationship or longitudinal-care episode; useful conceptually, but do not force it unless the source data supports it. |
| **CareTeam** | Represents providers participating in coordinated patient care; may help where responsible/billing and contributing providers need to be distinguished. |
| **Condition** | Clinical conditions when policy eligibility or special program context requires them. |
| **Observation** | Clinical facts, assessments, or measured data where relevant to a policy criterion. |
| **Procedure** | Clinical/professional service performed, if needed beyond the service coding carried in `Claim`. |
| **DocumentReference** / **Binary** | Links to supporting documents, correspondence, or evidence; do not put large documents directly in the adjudication payload. |
| **Questionnaire** / **QuestionnaireResponse** | Useful for structured provider, clinic, or citizen attestations/application data where LFP or exception workflows require it. |

`EpisodeOfCare` can represent a patient’s association with an organization and providers for a period in which the organization assumes responsibility; HL7 explicitly notes uses including government reporting or billing. ([hl7.org](https://hl7.org/fhir/R4/episodeofcare.html?utm_source=openai))

## Eligibility, authorization, workflow, and controls

| Resource | Likely LFP use |
|---|---|
| **CoverageEligibilityRequest** / **CoverageEligibilityResponse** | Pre-adjudication inquiry about eligibility or benefit coverage; useful if LFP needs a separate eligibility check. |
| **Task** | Human or system work item: request more information, route to MOA/adjudicator, request review, or track manual steps. |
| **ServiceRequest** | Possible representation of a requested service or authorization-related request; more likely useful in special-authority or clinical workflows than core LFP claims. |
| **Communication** / **CommunicationRequest** | Provider/patient correspondence, requests for clarification, and notifications. |
| **Consent** | Applicable where consent directives affect permitted information sharing. |
| **Contract** | Potentially relevant for provider agreements or reimbursement arrangements, but it is unlikely to be sufficient on its own for detailed tariff/LFP policy administration. |
| **Provenance** | Captures who/what created or transformed a resource; useful for interoperability and data lineage. |
| **AuditEvent** | Security/access audit events—who accessed or acted on FHIR resources. It complements, but does not replace, your adjudication decision evidence store. |

## What should probably *not* be modelled as raw FHIR resources

For the actual LFP adjudication core, keep these as explicit domain concepts/services, even if they have FHIR mappings at an external boundary:

- `LfpAdjudicationContext`
- `LfpPaymentPeriod` and cumulative limits/accumulators
- Cross-setting enforcement state
- Adjudication sequencing and stage outcomes
- Rule-set/policy effective version
- Decision trace and reason-code evidence
- Idempotency/replay state
- Financial posting command
- Re-adjudication, reversal, and reconciliation control state

FHIR `Claim` and `ClaimResponse` can model an exchange of claim and adjudication information, but they do not replace the internal orchestration, history, concurrency, and financial-control model required for a claims mainline. For example, `ClaimResponse` has an overall processing outcome and can reference the original `Claim`; it supports “queued,” “complete,” “error,” or “partial” processing outcomes. ([hl7.org](https://hl7.org/fhir/R4/claimresponse.html?utm_source=openai))

## Practical LFP FHIR starter profile

For a proof of concept, I would start with:

```text
Patient
Practitioner
PractitionerRole
Organization
Coverage
Claim
ClaimResponse
DocumentReference
Task
Provenance
AuditEvent
```

Then add only where the business case needs them:

```text
EpisodeOfCare / CareTeam       longitudinal-care relationship context
CoverageEligibility*           pre-adjudication eligibility inquiry
ExplanationOfBenefit           provider/patient-facing explanation
PaymentNotice/Reconciliation   payment/remittance integration
Condition/Observation          clinically driven eligibility or exception criteria
```

The key design work would be a **BC/LFP implementation profile**: agreed identifiers, required fields, local code systems, value sets, extensions, security, terminology, and mappings to existing DPP/Teleplan/mainframe data. Without profiles, using generic FHIR resources alone will not solve ambiguity around LFP-specific categories, practice settings, payment rules, or cross-setting enforcement.

## Information from DPP PIA

> APEX will be searchable by Practitioner Number and will display practitioner name, and beneficiary PHN in the results, among other claim details. 
> Current MAXPatH claim data that will be replicated in the new APEX application is shown below. 
> Each transaction record for a Patient Claim within the MSP claims system and associated applications such as MAXPath and APEX is considered to be and treated as PI data. 
>   PATIENT_CLAIM_SK
>	HEALTH_IDENTIFIER
>	PROVINCE_CODE
>	NEW_BORN_FLAG
>	DATA_CENTRE_NUMBER
>	PAID_DATE
>	CLAIM_SEQ_NUMBER
>	EXPLANATORY_CD_1
>	EXPLANATORY_CD_2
>	EXPLANATORY_CD_3
>	RECORD_TYPE
>	SERVICE_DATE_TXT
>	SERVICE_DATE
>	HISTORY_YEAR
>	PAID_AMOUNT
>	CLAIM_RECORD_CD
>	SERVICE_TO_DATE
>	PAID_SERVICE_CD
>	PAID_SERVICE_UNITS
>	PAID_FEE_ITEM
>	PAY_TO_CD
>	SERVICE_WHERE_CD
>	INSURER_CD
>	PRACT_NUMBER
>	PRACT_SPECIALTY_CD
>	PAYEE_NUMBER
>	SUBMISSION_CD
>	CORRESPONDENCE_CD
>	BILLED_SERVICE_CLARIFICATION
>	BILLED_SERVICE_UNITS
>	BILLED_FEE_ITEM
>	BILLED_AMOUNT
>	SERVICE_TIME_START
>	SERVICE_TIME_FINISH
>	ANESTHESTIC_PROCEDURAL_UNITS
>	CLAIM_NUMBER
>	SERVICE_LOCN_CD
>	ROUTINE_BLOCK_CD
>	REFERRING_PRACT_1_CD
>	REFERRING_PRACT_1_NUMBER
>	REFERRING_PRACT_1_STATUS
>	REFERRING_PRACT_2_CD
>	REFERRING_PRACT_2_NUMBER
>	DIAGNOSTIC_CD_1
>	DIAGNOSTIC_CD_2
>	DIAGNOSTIC_CD_3
>	PLAN_REF_NUMBER
>	REJECT_CD
>	SPECIAL_PROCESSING_CD
>	FACILITY_NUMBER
>	FACILITY_SUB_NUMBER
>	PRSNL_ID_NUMBER
>	DW_CREATE_TS
>	DW_UPDATE_TS


## Proof of Concept Specification

Yes. It makes sense **as an architecture proof of concept**, provided you are explicit that it is not a production recommendation to make FHIR the core LFP claims platform.

A HAPI FHIR backend gives you a credible stand-in for the unavailable legacy components: it can hold synthetic providers, clinics, patients, coverage, submitted claims, prior adjudication outcomes, and supporting references. Your Java LFP service can then retrieve a normalized context through APIs, apply DMN rules and explicit sequencing, and persist its own decision evidence. This demonstrates the separation you want to explore:

```text
Synthetic claim and history context
    → standards-based API / FHIR façade
    → Java LFP orchestration service
    → DMN policy decisions
    → decision trace, audit record, and outcome
```

Use FHIR resources such as `Practitioner`, `PractitionerRole`, `Organization`, `Patient`, `Coverage`, `Claim`, `ClaimResponse`, and possibly `Task` for a pend/manual-review path. Keep LFP-specific concepts—time accumulators, cross-setting checks, payment-period limits, sequencing stages, idempotency, and financial-posting commands—in your own compact Java domain model rather than trying to force all of them into generic FHIR resources.

The prototype’s value is to test architectural questions, not FHIR conformance alone:

- Can TeleMax-like routing identify an LFP claim and invoke a separate service?
- Can the service construct an adjudication context without direct database coupling?
- Can policy be represented visibly in DMN?
- Can claim history influence a decision?
- Can the process distinguish approve, deny, pend, and manual review?
- Can it produce an understandable decision trace for an MOA/adjudicator?
- What minimum APIs would be needed from E&E and payment in a real transition?

Use only synthetic data and label the components clearly: **“FHIR-backed mock claims context,”** **“simulated E&E eligibility service,”** and **“simulated payment-posting endpoint.”** That avoids implying that the prototype proves integration with the actual DPP environment.

A sensible Docker-based prototype might include:

```text
HAPI FHIR JPA Server + PostgreSQL
    - synthetic provider, clinic, coverage, Claim and ClaimResponse data

Spring Boot LFP Adjudication Service
    - REST API
    - context assembly from FHIR
    - Java sequencing
    - DMN evaluation
    - decision-evidence persistence

Mock E&E / Payment API
    - eligibility/edit response
    - controlled payment-status or posting response

Optional simple UI / Swagger
    - submit claim
    - inspect decision, trace, history, and manual-review queue
```
This is a strong personal proof of concept because it illustrates the desired **architectural boundary and adjudication flow**, while remaining honest that a real implementation may later use Db2- or domain-API-backed services instead of FHIR.
