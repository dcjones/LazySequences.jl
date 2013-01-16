
# Lazy Sequences in Julia

A lazy sequence is simply a linked list, in which in place of a tail pointer,
there is a function that evaluates to the next node in the list. This allows one
to create and process infinite lists.

A canonical example is Fibonacci numbers.

```julia
using Seq

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

Lazy sequences can also be thought of as an alternative to iterators, but the
implementation here is backwards compatible: you can iterate through values in a
sequence using a for loop, for example.

## Seq interface

Each node in a sequence must be something deriving from the abstract type
`Seqable`. For such objects, there must be a `first` function that gives the
next thing in the sequence, and a `rest` function that returns either a new
`Seqable` objects or `nothing` to indicate the end of the sequence.

The implementation here borrows heavily from Clojure. Function names and macros
are have similar names. For more information check out the Clojure documentation
on [sequences](http://clojure.org/sequences).

## Macros

There are two important macros in Seq.

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



