# arc42 summary: Community Library

The Community Library is an invented small system: members borrow books from branches. Complete the three sections.

## 1. Introduction and goals
The system lets members find books, borrow and return them at any branch, and lets librarians see who holds which copy. Top quality goals: a loan is never recorded twice for one copy, members' personal data stays private, and a branch can keep lending when the network is down for a short time.

## 3. Context and scope
Members use a web app and librarians use a staff screen. The system talks to an e-mail service for reminders and to a sign-in service for identities. Payments and book purchasing are outside the scope.

## 11. Risks and technical debt
- Risk: two branches lend the same copy at the same moment. Possible mitigation: one place decides loan state and refuses a second active loan for a copy.
- Risk: the e-mail service is down when reminders are due. Possible mitigation: queue reminders and retry later, and show overdue items on the staff screen.
