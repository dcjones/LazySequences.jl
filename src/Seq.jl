
module Seq

export seq, first, rest, cons, Seqable, @lazyseq, @lazycat, cat, map, zip, take

import Base.start, Base.next, Base.done, Base.map, Base.zip, Base.cat

abstract Seqable

seq(s::Seqable) = s


# Cons
# ----

type Cons <: Seqable
    first

    # This must be something with a seq function.
    rest
end


first(s::Cons) = s.first


function rest(s::Cons)
    # This effectively caches lazy-lists.
    s.rest = seq(s.rest)
end


cons(first, rest) = Cons(first, rest)


# Common operations
# -----------------

type Cat <: Seqable
    a::Seqable
    b # Something with a seq function.
end


first(s::Cat) = first(s.a)


function rest(s::Cat)
    a = rest(s.a)
    if a === nothing
        s.b = seq(s.b) # caching lazy seqs
    else
        Cat(a, s.b)
    end
end


cat(a) = seq(a)
cat(a, b) = Cat(seq(a), b)
can(a, b, cs...) = Cat(seq(a), cat(b, cs...))


type Take <: Seqable
    n::Int
    a::Seqable
end


first(s::Take) = first(s.a)


function rest(s::Take)
    a = rest(s.a)
    a === nothing || s.n <= 1 ? nothing : Take(s.n - 1, a)
end


function take(n::Int, a)
    if n <= 0
        nothing
    else
        Take(n, seq(a))
    end
end


# Lazy-seq
# --------

# This is no good, is it?
# Now when we do cons(1, @lazyseq foo), we have to evaluate foo...

# So when we do this:
#    f(x) = cons(x, @lazyseq f(x + 1))
# We have problems since this will just keep valuating...


# This seems wrong. We are no longer caching values.
# Argghh. Why is this so difficult. Maybe we can handle caching in rest(::Cons)

type LazySeq
    realize::Function
end


seq(s::LazySeq) = s.realize()


macro lazyseq(body)
    quote
        LazySeq(() -> $(esc(body)))
    end
end


# Lazy cat
# --------

macro lazycat(ss...)
    quote
        cat($([:(@lazyseq $(s)) for s in ss]...))
    end
end


# Backward compatibility
# ----------------------

start(s::LazySeq) = s.realize()
start(s::Seqable) = s


function next(::Seqable, s::Seqable)
    first(s), rest(s)
end


done(::Seqable, s::Nothing) = true
done(::Seqable, s::Any) = false


# Realizations
# ------------

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


type Zip <: Seqable
    ts::Vector
end


function first(s::Zip)
    tuple({first(t) for t in s.ts}...)
end


function rest(s::Zip)
    ts = {rest(t) for t in s.ts}
    if any(t -> t === nothing, ts)
        nothing
    else
        Zip(ts)
    end
end


function zip(ss::Union(LazySeq, Seqable)...)
    ss = Seqable[seq(s) for s in ss]
    if any(s -> s === nothing, ss)
        nothing
    else
        Zip(ss)
    end
end


map(f::Function, ::Nothing) = nothing


function map(f::Function, s::Seqable)
    v = first(s)
    v === nothing ? nothing : cons(f(v), @lazyseq map(f, rest(s)))
end


function map(f::Function, s0::Seqable, s1::Seqable, ss::Seqable...)
    map(v -> apply(f, v), zip(s0, s1, ss...))
end


end # end module

