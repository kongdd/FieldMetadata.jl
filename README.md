# FieldMetadata

[![CI](https://github.com/kongdd/FieldMetadata.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/kongdd/FieldMetadata.jl/actions/workflows/CI.yml)
[![codecov](https://codecov.io/gh/kongdd/FieldMetadata.jl/graph/badge.svg)](https://codecov.io/gh/kongdd/FieldMetadata.jl/tree/master/src)

This package lets you define metadata about fields in a struct, like tags
in Go. It uses a similar syntax to Parameters.jl, with a `|` bar instead of `=`.
You can use it as a minimalist replacement for Parameters.jl with the aid of
[FieldDefaults.jl](https://github.com/rafaqz/FieldDefaults.jl). 

Note that development effort has shifted to [ModelParameters.jl](https://github.com/rafaqz/ModelParameters.jl),
which achieves similar goals  in an arguably cleaner way.

FieldMetadata on nested structs can be flattened into a vector or tuple very efficiently with [Flatten.jl](https://github.com/rafaqz/Flatten.jl), where they are also used to exclude fields from flattening.

This example that adds string description metadata to fields in a struct:

```julia
using FieldMetadata
@metadata describe ""

@describe mutable struct Described
   a::Int     | "an Int with a description"  
   b::Float64 | "a Float with a description"
end

d = Described(1, 1.0)

julia> describe(d, :a) 
"an Int with a description"  

julia> describe(d, :b) 
"a Float with a description"  

julia> describe(d, :c) 
""  
```

A more complex example. Here we type-check metadata for `describe` to be 
`String` and `bounds` to be `Tuple`, by passing an extra argument to the macro:

```julia
using Parameters
@metadata describe "" String
@metadata bounds (0, 1) Tuple

@bounds @describe @with_kw struct WithKeyword{T}
    a::T = 3 | (0, 100) | "a field with a range, description and default"
    b::T = 5 | (2, 9)   | "another field with a range, description and default"
end

k = WithKeyword()

julia> describe(k, :b) 
"another field with a range, description and default"

julia> bounds(k, :a) 
(0, 100)
""  
```

You can chain as many metadata macros together as you want. As of
FieldMetadata.jl v0.2, macros are written in the same order as the metadata
columns, as opposed to the opposite order which was the syntax in v0.1

However, @with_kw from Parameters.jl must be the last macro and the first field, 
if it is used. 

Metadata annotations are optional — fields without a `|` separator are simply
skipped and will return the default value for that metadata type. When mixing
with Parameters.jl's `@with_kw`, you can freely omit metadata for any field:

```julia
@bounds @with_kw struct PartialBounds{T}
    a::T = 0.5 | (0.0, 1.0)  # has bounds metadata
    b::T = 1.0                # no bounds metadata; bounds(x, :b) returns (0.0, 1.0) (default)
end

x = PartialBounds{Float64}()
bounds(x, :a)  # (0.0, 1.0)
bounds(x, :b)  # (0.0, 1.0)  ← the global default
```

You can also use `_` as a placeholder to explicitly opt out of metadata for a
field while keeping the `|` separator for other metadata in the same line:

```julia
@bounds @describe @with_kw struct Mixed{T}
    a::T = 0 | _                | "no bounds, has description"
    b::T = 0 | (0.0, 1.0)      | "has bounds and description"
end
```


You can also update or add fields on a type that is already declared using a
`begin` block syntax. You don't need to include all fields or their types.

This is another change from the syntax in v0.1, where `@re` was prepended
to update using the same struct syntax.

```julia
julia> describe(d)                                                                                                     
("an Int with a description", "a Float with a description")  

@describe Described begin
   b | "a much better description"
end

julia> d = Described(1, 1.0)

julia> describe(d)
("an Int with a description", "a much better description")
```

We can use `typeof(x)` and a little meta-programming instead of the type name, 
which can be useful for anonymous function parameters:

```
@describe :($(typeof(d))) begin
   a | "a description without using the type"
end

julia> describe(d)
("a description without using the type", "a much better desc ription")
```


# Metadata placeholders

FieldMetadata provides an api of some simple metadata tags to be used across
packages: 

| Metadata    | Default    | Type   | Use case                                        |
| ----------- | ---------- | ------ | ----------------------------------------------- |
| default     | nothing    | Any    | Default values (see FieldDefaults.jl)           |
| units       | 1          | Any    | Unitful.jl unit                                 |
| prior       | nothing    | Any    | Prior probability distributions                 |
| label       | ""         | String | Short labels                                    |
| description | ""         | String | Complete descriptions                           |
| bounds      | (0.0, 1.0) | Tuple  | Upper and lower bounds in optimisers            |
| limits      | (0.0, 1.0) | Tuple  | Legacy - use `bounds`                           |
| logscaled   | false      | Bool   | For log sliders or log plots                    |
| flattenable | true       | Bool   | For flattening structs with Flatten.jl          |
| plottable   | true       | Bool   | For finding plottable content in nested structs |
| selectable  | Nothing    | Bool   | Supertypes to select child constructors from    |

To use them, call:

```julia
import FieldMetadata: @prior, prior
```

You _must_ `import` at least the function to use these placeholders, `using` is
not enough as you are effectively adding methods for you own types. 

Calling `@prior` or similar on someone else's struct may be type piracy and
shouldn't be done in a published package unless the macro is also defined there.
However, it can be useful in scripts.
