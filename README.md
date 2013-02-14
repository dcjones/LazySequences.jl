
# Lazy Sequences in Julia

A lazy sequence is simply a linked list, in which in place of a tail pointer,
there is a function that evaluates to the next node in the list. This allows one
to create and process infinite lists.

A canonical example is Fibonacci numbers.

```julia
using LazySequences

fibs = cat([0, 1], @lazyseq map(+, rest(fibs), fibs))

for k in take(10, fibs)
    println(k)
end
```

```
0
1
1
2
3
5
8
13
21
34
```

Here `fibs` is an infinite list of the Fibonacci numbers, which is realized as
needed. This example hinges on the `lazyseq` macro which takes an expression
that evaluates to a sequence, and hangs onto it until needed.

Seq is a separate interface than Julia iterators, but they compatible:
you can iterator through a sequence.


## Seq as an iterator construction kit

Iterators in Julia have an explicit state. Given that state, we should be able
to recover the value at that point in the sequence. This way we can always get
back to where we were in the iteration sequence if we hold onto a previous
state. This results in iterators that are easy to reason about and use. The
problem is, it can be sometimes quite difficult to define an explicit state
iterator. This is where Seq comes in.

Suppose we want to iterate over lines in a file. What do we keep as the
iterators state? We could keep a file position and rewind the file as needed,
but this is slow, and not all files are seekable. We could buffer every line
that's been read, but this is inefficient in the majority of cases where we
don't need to go backwards.

With Seq we do this quite easily:
```julia
function seqlines(io::IO)
    eof(io) ? nothing : cons(readline(io), @lazyseq seqlines(io))
end
```

Not only can we iterate through lines, reading them as needed, with `for line in
seqlines(file)`, but if we keep the head of the sequence, we can get back to the
beginning of the file.

The beauty of this approach, besides the fact that it's a one-liner, is that if
you "lose your head" (i.e. don't save the head of the sequence), the garbage
collector will free up the lines you've read but no longer need. It's on demand
buffering, in a sense.


## The Seqable interface

Each node in a sequence must be something deriving from the abstract type
`Seqable`. For such objects, there must be a `first` function that gives the
next thing in the sequence, and a `rest` function that returns either a new
`Seqable` objects or `nothing` to indicate the end of the sequence.

The implementation here borrows heavily from Clojure. Function names and macros
are have similar names. For more information check out the Clojure documentation
on [sequences](http://clojure.org/sequences).

## Macros

There are two important macros in LazySequences.

`lazyseq` : Take an expression evaluating to a Seqable object or nothing, but
don't evaluate it until needed.

`lazycat` : Lazily chain several expressions generating Seqables together.
For, example `@lazycat f(n) g(n)` will concatenate the lazy sequence
produced by `f` with that produced by `g`, avoiding evaluation until needed.

## Functions

Common functions over sequences are implemented: `cat`, `zip`, `map`, `take`.

## Defining sequences

Recursion combined with `@lazyseq` tends to be an elegant means of producing
lazy sequences. For example, the `map` function in Seq is defined just as:

```julia
map(f::Function, ::Nothing) = nothing
map(f::Function, s::Seqable) = cons(f(first(s)), @lazyseq map(f, rest(s)))
```



