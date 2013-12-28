using LazySequences

# Cons
c = cons(1, [42])
# Test first(s::Cons)
@assert first(c) == 1
# Test rest(s::Cons)
@assert first(rest(c)) == 42

ct = cat([1], [42])
# Test first(s::Cat)
@assert first(ct) == 1
# Test rest(s::Cat)


# Test getindex implementation
fibs = cat([0, 1], @lazyseq map(+, rest(fibs), fibs))
@assert fibs[1] == 0
@assert fibs[2] == 1
@assert fibs[3] == 1
@assert fibs[4] == 2
