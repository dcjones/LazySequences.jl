#!/usr/bin/env julia

using Seq

fibs = cat([0, 1], @lazyseq map(+, rest(fibs), fibs))

for k in take(10, fibs)
    println(k)
end


