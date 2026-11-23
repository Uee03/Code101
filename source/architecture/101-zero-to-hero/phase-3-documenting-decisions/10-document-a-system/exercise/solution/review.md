# Community Library review

Audience: library staff and a new maintainer.
Question: how does a signed-in member view only their own loans?
Scope: read-only loan view; no reservations, payments or notifications.
Assumption: the library maintains member-to-identity mappings.
This is a learner design, not an existing Tasks and Teams feature.

## Review checklist
- [ ] Context and container boundaries both describe Community Library.
- [ ] Sequence participants match the container view.
- [ ] Every loan refers to one member and one book.
- [ ] The API identifies the member before reading loans.
- [ ] Both ADRs show alternatives and costs.
- [ ] A second reader can explain the journey and one failure case.
- [ ] Sources contain no secrets or real borrowing histories.
