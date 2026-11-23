# Async design checklist

| Question | Why it matters |
|---|---|
| What is the delivery guarantee? Assume at least once | Most brokers can deliver a message more than once, so the consumer must cope |
| Is the consumer idempotent? How is a repeat recognised? | A repeat must not create a second effect, for example a second charge |
| How many tries, with what waiting time between tries? | Unlimited immediate retries turn one failure into a flood |
| Where does a message go after the last try? | A dead-letter destination keeps the evidence and unblocks the rest |
| Does order matter? Per what key? | Strict global order limits parallel workers; order per entity is usually enough |
| What is the payload? | Send an id or a small fact; keep large files in storage and pass a reference |
| How do you see the backlog? | Queue depth and age of the oldest message show trouble before users do |
| What happens when producers are faster than consumers? | Without a limit the backlog grows; decide on a bound, a slower producer or more workers |
| Who can read the messages? | A broker holds copies of data; apply the same access rules as for the database |
