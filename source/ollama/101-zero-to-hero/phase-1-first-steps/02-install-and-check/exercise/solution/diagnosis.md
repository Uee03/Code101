# Invented setup scenario, not captured terminal output

The executable was found. No Ollama process was observed. Port 11434 has no listener.
A request to /api/version did not connect.
Diagnosis: the client is installed, but no server is listening on the expected port.
Next action requiring explicit permission: open the native app or start the native service.
Health check to repeat without starting the app: request GET /api/version on loopback.
Command to avoid as an initial health check: ollama list, because it may start the app.
