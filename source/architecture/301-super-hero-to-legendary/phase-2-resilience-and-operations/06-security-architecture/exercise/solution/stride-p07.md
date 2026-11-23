# STRIDE for P07

| Flow or element | Category | Threat | Mitigation in the design | Open question |
|---|---|---|---|---|
| A service publishes events to the broker | Spoofing and tampering | A rogue process publishes a forged PaymentCaptured event | Each service has its own broker identity and may publish only its own event types; consumers check the producer field | Who may create broker identities? |
| Orders calls the payment fake | Information disclosure | Card data or tokens leak through logs or events | No card data in the system at all, as P07 requires; identifiers only in logs; TLS between services | Are payloads scrubbed in traces? |
| An operator replays dead-lettered messages | Repudiation and elevation of privilege | A replay changes orders and nobody can say who did it | Replay is restricted to named operators and every replay writes an audit entry with the operator and the message id | How is a replay approved for payment events? |
