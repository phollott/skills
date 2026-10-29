# BC CareConnect Upgrades

## Background and Context

### Viewer Timeouts

- CareConnect LSM and Lab Get Pre-fetch have a 10 second timeout, single retry if a page request fails
- Health Gateway retries twice, with a 30 second delay between failure and next attempt
- UCI timeout setting is configured at 1 minute and resend is configured to 0 seconds; UCI makes active calls to the PLIS endpoints

## CareConnect Metadata Population

Use Lab Summary requests to load all data for a Patient as soon as the Labs tab is opened to populate filter dropdowns.
The original design of LSM was to load 6 months at a time.

## CareConnect Observation Trending

Use Lab Get with Specimen Collection date range (no PDF) to load all General Laboratory results in bursts of 25 parallel Gets, which take place after LSM.

## CareConnect UI PageSize

Resulted in higher Battery density in LSM response messages; clinicians are more likely to use 200 battery page size.

## CareConnect Timeline View

Substantial increase in LSM volume as clinicians access Lab Summary data on home page, rather than Labs tab. This results in LA backlog and increased number of GET/LSM timeouts.
Additionally, CareConnect could load timeline using date range, rather than brute force "all the data". 

### CSI Recommendations

1. Double number of LSM consumers so that queues clear backlog more quickly
2. Increase CareConnect timeout for LSM/GET so that we can raise the threshold and avoid death spiral
3. If LA is involved, reroute/withhold LA Battery Event Distribution snippets, which is more in line with the FHIR API

### Test Evidence

#### 2026-10-26 Intentional LSM Precache Increase

Switched off after first hour or two, took remains of the day to stabilize.

- 1012 Lab Gets took 10 seconds or more end-to-end
- 4278 LSM requests took 10 seconds or more end-to-end

#### 2026-05-06 Accidental LSM Precache Increase
