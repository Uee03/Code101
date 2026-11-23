# Saltmarsh Outfitters: split or not?

Facts from the P07 brief: one application takes orders, reserves stock, charges the card and books the courier in one database transaction. During a sale the courier was slow and checkout froze; stock was reserved twice for one pair of boots; about 40 orders were charged but never shipped.

| Question | Evidence in the brief | Verdict (one deployable or separate) and reason |
|---|---|---|
| Do teams block each other's releases? | TODO | TODO |
| Must one part keep running when another fails? | TODO | TODO |
| Are the data boundaries clear? | TODO | TODO |
| Must operations be strongly consistent across the parts? | TODO | TODO |

Overall recommendation for the business, and what you would try first: TODO
