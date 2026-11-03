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
