# Risk register: Tasks and Teams platform

Likelihood and impact are judgements for discussion (low, medium, high), not measurements. Update them when you measure.

| Id | Risk | Scenario | Likelihood | Impact | Mitigation in the design | Trigger to act | Owner |
|---|---|---|---|---|---|---|---|
| R1 | A leaked or revoked token keeps working until it expires | Q4 | Medium | High | Short access token life, refresh token rotation, tokens never logged | A review demands immediate revocation for some operation | Platform maintainers |
| R2 | Business rules in database functions are harder to unit test and need a migration to change | Q5 | Medium | Medium | One shared implementation, a smoke script for the functions, numbered migrations | A rule changes more often than migrations can be reviewed | Platform maintainers |
| R3 | The identity realm is imported once, so later edits made by hand drift away from the file in the repository | Q4 | Medium | Medium | Document changes made through the admin interface and export them back | A second environment differs from the file | Platform maintainers |
| R4 | The design has one PostgreSQL database with no replica, so its failure stops every operation | Q4 | Low | High | Backups and a tested restore described in a runbook (not yet written), replicas considered in the scaling lesson at level 301 | A recovery objective is agreed that one instance cannot meet | Platform maintainers |
| R5 | Backends could drift from the contract in areas the conformance script does not cover: it runs 14 API checks and the contract has 27 operations | Q3 | Medium | Medium | Backend capstone tests for the remaining operations | A client bug traced to an unchecked operation | Backend owners |
