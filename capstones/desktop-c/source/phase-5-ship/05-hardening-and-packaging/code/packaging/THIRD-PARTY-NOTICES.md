# Third-party notices

The `tasksteams` program is built from the Code101 desktop-c capstone sources and links the libraries below.
Each library keeps its own licence; the licence texts come with the packages that vcpkg installs
(`vcpkg_installed/<triplet>/share/<port>/copyright`) and with the Nuklear repository. This list is a
starting point for a release: check the real licence files of the versions you ship before you distribute.

| Library | Used for | Licence (as published by the project) |
|---------|----------|----------------------------------------|
| SDL3 | window, input, threads, clock | zlib licence |
| Nuklear (tag v4.13.4) and its SDL3 renderer backend | user interface | public domain or MIT, at your choice |
| libcurl | HTTP and TLS client | curl licence (MIT-like) |
| cJSON | JSON parsing and writing | MIT |
| OpenSSL | random numbers and SHA-256 | Apache licence 2.0 (OpenSSL 3.x) |

No secret, token, key or personal data is part of this package. The file `keycloak/tasks-desktop-client.json`
is public configuration for a public OAuth client.
