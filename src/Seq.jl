
module Seq

export seq, first, rest, cons, Seqable, @lazyseq, chain

import Base.start, Base.next, Base.done, Base.map

abstract Seqable



# Cons
# ----

type Cons <: Seqable
    first
    rest::Seqable
end

first(s::Cons) = s.first
rest(s::Cons) = s.rest

cons(first, rest::Seqable) = Cons(first, rest)


# Common operations
# -----------------

type Chain <: Seqable
    a::Seqable
    b::Seqable
end

first(s::Chain) = first(s.a)

function rest(s::Chain)
    a = rest(s.a)
    a === nothing ? s.b : Chain(a, s.b)
end

chain(a::Seqable) = a
chain(a::Seqable, bs::Seqable...) = Chain(a, chain(bs...))


# Lazy-seq
# --------

type LazySeq <: Seqable
    realize::Function
    realized::Bool
    value

    function LazySeq(realize::Function)
        new(realize, false, nothing)
    end
end


function first(s::LazySeq)
    if !s.realized
        s.value = s.realize()
    end
    first(s.value)
end


function rest(s::LazySeq)
    if !s.realized
        s.value = s.realize()
    end
    rest(s.value)
end


macro lazyseq(body)
    quote
        LazySeq(() -> $(esc(body)))
    end
end


# Lazy chain
# ----------

#macro lazychain(
    #quote

    #end
#end


# Backward compatibility
# ----------------------

start(s::Seqable) = s

function next(::Seqable, s::Seqable)
    first(s), rest(s)
end

done(::Seqable, s::Nothing) = true
done(::Seqable, s::Any) = false


# Seq realizations
# ----------------

type AbstractArraySeq <: Seqable
    xs::AbstractArray
    i::Int
end

function seq(xs::AbstractArray)
    AbstractArraySeq(xs, 1)
end

first(s::AbstractArraySeq) = s.xs[s.i]
rest(s::AbstractArraySeq) =
    s.i >= length(s.xs) ? nothing :  AbstractArraySeq(s.xs, s.i + 1)



# TODO
function zip(a::Seqable, b::Seqable)
end


function map(f::Function, xs::Seqable)
    v = first(xs)
    v === nothing ? nothing : cons(v, @lazyseq map(f, rest(xs)))
end


end # end module

