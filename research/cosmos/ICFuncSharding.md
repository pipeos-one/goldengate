# InterChain Functional Data Sharding

This is a technique that generalizes state bridging, side chains, data sharding, replay and transaction mirroring.

## Selectable Function

Given a set of chains C, and a set of functions F, we compose an operation ID oID in the following way (encode):

- consider f = |F| (cardinality of f)
- c = |C|
- O = pow(2, (c * log(2, f)))
- an operation is a number in the range 0 - O

decode:

- given a number oID in range 0 - O
- divide oID into c ranges of bytes
- for every non-zero range at index cID that has value fID, perform the function with the id specified by the fID, on the chain specified by the cID

### Special Functions

- The Nothing function (recommended to have fID = 0)
- The Identity function (fID = 1)
- increment (fID = 2)
- hash (fID = 3)
- sum
