# Saltmarsh Outfitters: split or not?

Facts from the P07 brief: one application takes orders, reserves stock, charges the card and books the courier in one database transaction. During a sale the courier was slow and checkout froze; stock was reserved twice for one pair of boots; about 40 orders were charged but never shipped.

| Question | Evidence in the brief | Verdict (one deployable or separate) and reason |
|---|---|---|
| Do teams block each other's releases? | The brief says nothing about teams or release conflicts | No evidence, so no case for splitting on this ground |
| Must one part keep running when another fails? | A slow courier froze the whole checkout | Evidence for isolating the courier call; a timeout and an asynchronous hand-off can achieve this inside one deployable |
| Are the data boundaries clear? | Orders, stock, payments and shipments are separate concepts but live in one transaction today | Boundaries are plausible; the first step is to make them explicit as modules |
| Must operations be strongly consistent across the parts? | Double stock reservation and charged-but-not-shipped orders show weak control today | Stock reservation needs one owner and an atomic step; it is easier to fix inside one database first |

Overall recommendation for the business, and what you would try first: the evidence supports fixing the courier call (timeout, queue, outbox) and the stock reservation inside a modular monolith before splitting. P07 chooses services because its learning goal is to practise the patterns; for the real shop the first move is the cheaper one, and extraction follows only when a measurement shows the need.
