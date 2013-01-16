#!/usr/bin/env julia

using Seq

natural_numbers = cons(1, @lazyseq map(n -> n + 1, natural_numbers))

for k in take(10, natural_numbers)
    println(k)
end

