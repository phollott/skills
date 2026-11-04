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
