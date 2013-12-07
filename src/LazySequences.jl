
module LazySequences

export seq, first, rest, cons, Seqable, @lazyseq, @lazycat, cat, map, zip, take

import Base.start, Base.next, Base.done, Base.map, Base.zip, Base.cat,
       Base.first

abstract Seqable

seq(s::Seqable) = s
seq(::Nothing) = nothing


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

function getindex(s::Cat, n::Int64)
    sequence = Any[]
    for i in take(n, s)
        push!(sequence, i)
    end
    sequence[end]
end

cat(a) = seq(a)
cat(a, b) = Cat(seq(a), b)
can(a, b, cs...) = Cat(seq(a), cat(b, cs...))


immutable Take <: Seqable
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

immutable LazySeq
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

immutable AbstractArraySeq <: Seqable
    xs::AbstractArray
    i::Int
end


function seq(xs::AbstractArray)
    AbstractArraySeq(xs, 1)
end


first(s::AbstractArraySeq) = s.xs[s.i]
rest(s::AbstractArraySeq) =
    s.i >= length(s.xs) ? nothing :  AbstractArraySeq(s.xs, s.i + 1)


immutable Zip <: Seqable
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
map(f::Function, s::Seqable) = cons(f(first(s)), @lazyseq map(f, rest(s)))


function map(f::Function, s0::Seqable, s1::Seqable, ss::Seqable...)
    map(v -> apply(f, v), zip(s0, s1, ss...))
end


# Lazy character streams from IO objects.
# ---------------------------------------

function seq(io::IO)
    eof(io) ? nothing : cons(read(io, Char), @lazyseq seq(io))
end


function seqlines(io::IO)
    eof(io) ? nothing : cons(readline(io), @lazyseq seqlines(io))
end


end # end module
