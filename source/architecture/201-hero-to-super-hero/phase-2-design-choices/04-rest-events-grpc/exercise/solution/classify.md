# Choose a style for each interaction

| Interaction | Style (REST, event or gRPC) | Reason |
|---|---|---|
| A browser asks for the list of tasks | REST | The caller is a browser and waits for the answer; HTTP caching and the OpenAPI contract apply |
| The Orders service tells Inventory that an order was placed | Event | Orders must not wait for Inventory, and more parties will react later |
| The gateway asks the payment fake to charge an order | REST (HTTP) | A synchronous call to an external-style service; protect it with a timeout, a limited retry and an idempotency key |
| One internal service calls a pricing service many times per request and both teams share one schema | gRPC candidate | A strict shared contract and call volume make it worth testing, but only after measuring the REST cost |
| A weekly report must include every completed task | Event or batch read | The report can consume TaskCompleted events or read stored data later; no caller waits |
