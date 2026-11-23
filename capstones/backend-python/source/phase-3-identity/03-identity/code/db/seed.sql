-- Demo data. The three users match the Keycloak realm import: the id is the Keycloak `sub`.
-- Every insert below is recorded in audit_log with alice as the actor.
SELECT set_config('app.current_user_id', 'a11ce000-0000-4000-8000-000000000001', false);

INSERT INTO users (id, username, email, display_name) VALUES
    ('a11ce000-0000-4000-8000-000000000001', 'alice', 'alice@tasksteams.test', 'Alice Admin'),
    ('b0b00000-0000-4000-8000-000000000002', 'bob', 'bob@tasksteams.test', 'Bob Member'),
    ('ca401000-0000-4000-8000-000000000003', 'carol', 'carol@tasksteams.test', 'Carol Member');

INSERT INTO teams (id, name, description, created_by) VALUES
    ('7ea00000-0000-4000-8000-000000000001', 'Platform Team', 'Builds and runs the shared platform.', 'a11ce000-0000-4000-8000-000000000001'),
    ('7ea00000-0000-4000-8000-000000000002', 'Mobile Team', 'Builds the phone apps.', 'a11ce000-0000-4000-8000-000000000001');

INSERT INTO team_members (team_id, user_id, role) VALUES
    ('7ea00000-0000-4000-8000-000000000001', 'a11ce000-0000-4000-8000-000000000001', 'lead'),
    ('7ea00000-0000-4000-8000-000000000001', 'b0b00000-0000-4000-8000-000000000002', 'member'),
    ('7ea00000-0000-4000-8000-000000000001', 'ca401000-0000-4000-8000-000000000003', 'member'),
    ('7ea00000-0000-4000-8000-000000000002', 'ca401000-0000-4000-8000-000000000003', 'lead'),
    ('7ea00000-0000-4000-8000-000000000002', 'b0b00000-0000-4000-8000-000000000002', 'member');

INSERT INTO projects (id, team_id, key, name, description, created_by) VALUES
    ('9a000000-0000-4000-8000-000000000001', '7ea00000-0000-4000-8000-000000000001', 'PLAT', 'Platform Launch', 'Get the first release out.', 'a11ce000-0000-4000-8000-000000000001'),
    ('9a000000-0000-4000-8000-000000000002', '7ea00000-0000-4000-8000-000000000001', 'DOCS', 'Documentation', 'Guides and API reference.', 'a11ce000-0000-4000-8000-000000000001'),
    ('9a000000-0000-4000-8000-000000000003', '7ea00000-0000-4000-8000-000000000002', 'MOB', 'Mobile App', 'The Flutter and Kotlin clients.', 'ca401000-0000-4000-8000-000000000003');

INSERT INTO tasks (id, project_id, title, description, status, priority, assignee_id, due_date, created_by) VALUES
    ('7a500000-0000-4000-8000-000000000001', '9a000000-0000-4000-8000-000000000001', 'Write the OpenAPI contract', 'Every endpoint and schema.', 'done', 'high', 'a11ce000-0000-4000-8000-000000000001', '2027-01-15', 'a11ce000-0000-4000-8000-000000000001'),
    ('7a500000-0000-4000-8000-000000000002', '9a000000-0000-4000-8000-000000000001', 'Design the database', 'Tables, indexes, stored procedures.', 'done', 'high', 'b0b00000-0000-4000-8000-000000000002', '2027-01-22', 'a11ce000-0000-4000-8000-000000000001'),
    ('7a500000-0000-4000-8000-000000000003', '9a000000-0000-4000-8000-000000000001', 'Configure Keycloak', 'Realm, clients, roles and users.', 'in_progress', 'urgent', 'ca401000-0000-4000-8000-000000000003', '2027-02-05', 'a11ce000-0000-4000-8000-000000000001'),
    ('7a500000-0000-4000-8000-000000000004', '9a000000-0000-4000-8000-000000000001', 'Run the conformance script', 'All checks green on every backend.', 'todo', 'medium', NULL, '2027-02-19', 'b0b00000-0000-4000-8000-000000000002'),
    ('7a500000-0000-4000-8000-000000000005', '9a000000-0000-4000-8000-000000000001', 'Add rate limiting', 'RateLimit headers and 429 responses.', 'blocked', 'medium', 'b0b00000-0000-4000-8000-000000000002', NULL, 'a11ce000-0000-4000-8000-000000000001'),
    ('7a500000-0000-4000-8000-000000000006', '9a000000-0000-4000-8000-000000000002', 'Write the getting started guide', 'From clone to first request.', 'todo', 'low', 'ca401000-0000-4000-8000-000000000003', '2027-03-01', 'a11ce000-0000-4000-8000-000000000001'),
    ('7a500000-0000-4000-8000-000000000007', '9a000000-0000-4000-8000-000000000003', 'Sign in with PKCE', 'Authorization code flow on a phone.', 'in_progress', 'high', 'ca401000-0000-4000-8000-000000000003', '2027-02-12', 'ca401000-0000-4000-8000-000000000003'),
    ('7a500000-0000-4000-8000-000000000008', '9a000000-0000-4000-8000-000000000003', 'Cache tasks offline', 'Show the last list without a network.', 'todo', 'medium', 'b0b00000-0000-4000-8000-000000000002', NULL, 'ca401000-0000-4000-8000-000000000003');

INSERT INTO comments (id, task_id, author_id, body) VALUES
    ('c0000000-0000-4000-8000-000000000001', '7a500000-0000-4000-8000-000000000003', 'a11ce000-0000-4000-8000-000000000001', 'Remember to turn on brute-force protection.'),
    ('c0000000-0000-4000-8000-000000000002', '7a500000-0000-4000-8000-000000000003', 'ca401000-0000-4000-8000-000000000003', 'Done in the realm file, checking the token lifetimes next.'),
    ('c0000000-0000-4000-8000-000000000003', '7a500000-0000-4000-8000-000000000007', 'b0b00000-0000-4000-8000-000000000002', 'The emulator needs adb reverse for port 8180.');
