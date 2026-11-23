# ATAM-lite run sheet

ATAM is the Architecture Tradeoff Analysis Method. This short form fits a team of two to five people and one to two hours.

1. State the system, its purpose and the scope of the review in three sentences.
2. List the business drivers: why the system exists and what must not go wrong.
3. Build a utility tree: quality attributes at the top, concrete scenarios at the leaves.
4. Rate each scenario for importance and for difficulty, high, medium or low, and discuss disagreements.
5. For each scenario rated high on both, name the architecture decision that serves it and ask how it could fail.
6. Record each finding as one of: risk, non-risk, sensitivity point or trade-off point.
7. Write the risks into the register with a mitigation, a trigger and an owner.

Finding types:
- Risk: a decision that may cause a scenario to fail.
- Non-risk: a decision that is sound for the scenario and why.
- Sensitivity point: a property where a small change strongly affects a quality.
- Trade-off point: one decision that improves one quality and worsens another.
