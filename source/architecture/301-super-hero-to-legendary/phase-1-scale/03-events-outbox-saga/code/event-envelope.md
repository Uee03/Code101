# Event envelope and rules

Every event carries the same envelope. The fields follow the practice capstone P07, section 6; the exact names are this lesson's choice.

| Field | Meaning |
|---|---|
| id | A stable unique id of this event, used by consumers to recognise a repeat |
| type | The name of the fact in the past tense, for example OrderPlaced |
| schema_version | The version of the payload shape, a whole number |
| producer | The service that published it |
| occurred_at | When the fact happened, in UTC |
| correlation_id | Ties together every event and request of one order |
| trace_context | The trace identifiers that let one trace follow the order across services |
| data | The facts a consumer needs, kept small |

Rules:
- An event states a fact that already happened. A command asks someone to do something and has a different name and an owner.
- Change an event only by adding optional fields. Removing or renaming a field needs a new schema_version and a period in which both are supported.
- Do not put secrets or card data in an event; anyone who can read the broker can read it.
- Consumers ignore fields they do not know.
