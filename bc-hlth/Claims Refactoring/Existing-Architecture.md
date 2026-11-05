# Existing Claims Architecture

## E&E System (Edits and Eligibility)

Batch system that primarily validates claim information:
- patient coverage against subscriber databases via Common Eligibility Module;
- practitioner, payee and fee against MPIF/MCDB databases (Practitioner Information and Claims in Progress)

Interfaces with ICBC & WSBC external agencies
Application coded in PL/I, COBOL, DB2, IMS

## Adjudication System

Batch system that primarily adjudicates claims, using patient previous medical history
Interfaces with ICBC external agency
Application in PL/I, COBOL, DB2

## DPP Apex

Flow is from Claims Mainframe through File Transfer Service to Enterprise Data Warehouse accessed through Apex App

### From the PIA for DPP/APEX

**Out of Scope:**

There may be other future enhancements after the successful implementation of Stage 1. The following elements will not be included in the initial launch of this initiative and are considered out of scope for this PIA. 

**Expand to Multiple time Period Limits & Provider Based Adjudication**

The future stages will focus on including additional adjudication rules such as the number of services, checking for overlapping times and enforcing multiple PBD time-period limits (e.g. a daily limit and a 14-day limit).

**Future objectives:**

- Allowing reference patient-based LFP billings and pay the time-based billings based on findings by storing patient-LFP fee items (e.g. interactions) from the Regular Mainline in a database that the New Mainline could look up. 
•	Create adjudication rules, e.g. overlapping times.
•	Enforce multiple time-period limits (e.g. a daily limit enforced in Stage 1 and a new 14-day limit for the same fee item enforced in Stage 2)
