using LazySequences

# Cons
c = cons(1, [0])
@assert first(c) == 1
@assert first(rest(c)) == 0

# Test getindex implementation
fibs = cat([0, 1], @lazyseq map(+, rest(fibs), fibs))
@assert fibs[1] == 0
@assert fibs[2] == 1
