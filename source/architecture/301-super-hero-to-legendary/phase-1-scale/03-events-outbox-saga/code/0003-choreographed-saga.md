# ADR 0003: Choreographed order saga with Orders owning the final state

Status: Proposed
Date: 2026-11-23
Owner: P07 learner team

## Context
Placing an order touches Inventory, Payments and Fulfilment, each with its own database. No single transaction can cover them, so each step is a local transaction and a failure is repaired by compensation. Someone must decide when an order is confirmed or cancelled, and what happens when a step never answers.

## Options
- Orchestration: Orders sends a command to each service in turn and decides what to do on each reply. Cost: Orders knows every step and becomes a central point of change.
- Choreography: each service reacts to events and publishes the next one. Cost: the whole flow exists only as the sum of reactions, so it is harder to see and to debug.
- Choreography for the steps, with Orders listening to every outcome, owning the order state and owning the timeout. Cost: Orders still needs a reliable view of all outcomes.

## Decision
Use choreography for the steps. Orders records each outcome in the order state machine and owns the timeout that cancels an order that stalls.

## Consequences
- Benefit: services stay decoupled and Orders alone answers "what state is this order in".
- Cost or risk: the flow must be documented by diagrams and traced end to end, or nobody can see it.

## Revisit when
The flow grows beyond what one diagram can show, or compensation rules need one owner that sees all steps. Reviewer: the P07 learner team.
