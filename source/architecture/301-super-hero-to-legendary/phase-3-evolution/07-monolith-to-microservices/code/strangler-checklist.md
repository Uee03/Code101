# Strangler migration checklist

Before you start:
- [ ] The part to extract has a clear interface and owns its data, or you have a plan to split the data.
- [ ] A facade exists that can route by path or by feature flag.
- [ ] Metrics, traces and alerts exist for the old and the new part.
- [ ] A rollback is defined: how traffic returns to the old part, and how long it stays ready.

During:
- [ ] The new part receives copies of traffic first, and differences are reviewed.
- [ ] A small share of real traffic is routed, then increased in steps agreed in advance.
- [ ] Data is moved with a plan that handles writes during the move, and counts are compared at the end.
- [ ] The new part calls the old one only through its public interface, never through shared tables.

After:
- [ ] The old code and its data are removed after the agreed waiting period.
- [ ] Documents and diagrams show only the new structure.
- [ ] The decision and the measured outcome are recorded in an ADR.
