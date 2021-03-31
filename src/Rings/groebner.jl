export  groebner_basis, groebner_basis_with_transformation_matrix, leading_ideal, syzygy_generators

# groebner stuff #######################################################
@doc Markdown.doc"""
    groebner_assure(I::MPolyIdeal)

**Note**: Internal function, subject to change, do not use.

Given an ideal `I` in a multivariate polynomial ring this function assures that a
Groebner basis w.r.t. the given monomial ordering is attached to `I` in `I.gb`.

# Examples
```jldoctest
julia> R,(x,y) = PolynomialRing(QQ, ["x","y"], ordering=:degrevlex)
(Multivariate Polynomial Ring in x, y over Rational Field, fmpq_mpoly[x, y])

julia> I = ideal([x*y-3*x,y^3-2*x^2*y])
ideal generated by: x*y - 3*x, -2*x^2*y + y^3

julia> Oscar.groebner_assure(I)
3-element Array{fmpq_mpoly,1}:
 x*y - 3*x
 y^3 - 6*x^2
 x^3 - 9//2*x

julia> I.gb
Oscar.BiPolyArray{fmpq_mpoly}(fmpq_mpoly[x*y - 3*x, y^3 - 6*x^2, x^3 - 9//2*x], Singular Ideal over Singular Polynomial Ring (QQ),(x,y),(dp(2),C) with generators (x*y - 3*x, y^3 - 6*x^2, x^3 - 9//2*x), Multivariate Polynomial Ring in x, y over Rational Field, Singular Polynomial Ring (QQ),(x,y),(dp(2),C), false, #undef)
```
"""
function groebner_assure(I::MPolyIdeal)
  if !isdefined(I, :gb)
    singular_assure(I)
#    @show "std on", I.gens.S
    I.gb = BiPolyArray(I.gens.Ox, Singular.std(I.gens.S))
  end
end

@doc Markdown.doc"""
    groebner_basis(B::BiPolyArray; ord::Symbol = :degrevlex, complete_reduction::Bool = false)

**Note**: Internal function, subject to change, do not use.

Given an `BiPolyArray` `B` and optional parameters `ord` for a monomial ordering and `complete_reduction`
this function computes a Groebner basis (if `complete_reduction = true` the reduced Groebner basis) of the
ideal spanned by the elements in `B` w.r.t. the given monomial ordering `ord`. The Groebner basis is then
returned in `B.S`.

# Examples
```jldoctest
julia> R, (x, y) = PolynomialRing(QQ, ["x", "y"], ordering=:degrevlex)
(Multivariate Polynomial Ring in x, y over Rational Field, fmpq_mpoly[x, y])

julia> A = Oscar.BiPolyArray([x*y-3*x,y^3-2*x^2*y])
Oscar.BiPolyArray{fmpq_mpoly}(fmpq_mpoly[x*y - 3*x, -2*x^2*y + y^3], #undef, Multivariate Polynomial Ring in x, y over Rational Field, Singular Polynomial Ring (QQ),(x,y),(dp(2),C), false, #undef)

julia> B = groebner_basis(A)
Oscar.BiPolyArray{fmpq_mpoly}(fmpq_mpoly[#undef, #undef, #undef], Singular Ideal over Singular Polynomial Ring (QQ),(x,y),(dp(2),C) with generators (x*y - 3*x, y^3 - 6*x^2, 2*x^3 - 9*x), Multivariate Polynomial Ring in x, y over Rational Field, Singular Polynomial Ring (QQ),(x,y),(dp(2),C), true, #undef)
```
"""
function groebner_basis(B::BiPolyArray; ord::Symbol = :degrevlex, complete_reduction::Bool = false)
  # if ord != :degrevlex
    R = singular_ring(B.Ox, ord)
    i = Singular.Ideal(R, [R(x) for x = B])
#    @show "std on", i, B
    i = Singular.std(i, complete_reduction = complete_reduction)
    return BiPolyArray(B.Ox, i)
  # end
  if !isdefined(B, :S)
    B.S = Singular.Ideal(B.Sx, [B.Sx(x) for x = B.O])
  end
#  @show "dtd", B.S
  return BiPolyArray(B.Ox, Singular.std(B.S, complete_reduction = complete_reduction))
end

@doc Markdown.doc"""
    groebner_basis(I::MPolyIdeal)

Given an ideal `I` this function computes a Groebner basis
w.r.t. the given monomial ordering of the polynomial ring. The Groebner basis is then
returned as an array of multivariate polynomials.

# Examples
```jldoctest
julia> R, (x, y) = PolynomialRing(QQ, ["x", "y"], ordering=:degrevlex)
(Multivariate Polynomial Ring in x, y over Rational Field, fmpq_mpoly[x, y])

julia> I = ideal([x*y-3*x,y^3-2*x^2*y])
ideal generated by: x*y - 3*x, -2*x^2*y + y^3

julia> G = groebner_basis(I)
3-element Array{fmpq_mpoly,1}:
 x*y - 3*x
 y^3 - 6*x^2
 x^3 - 9//2*x
```
"""
function groebner_basis(I::MPolyIdeal)
  groebner_assure(I)
  return collect(I.gb)
end

@doc Markdown.doc"""
    groebner_basis(I::MPolyIdeal, ord::Symbol = :degrevlex; complete_reduction::Bool=false)

Given an ideal `I`, a monomial ordering `ord` and an optional parameter `complete_reduction`
this function computes a Groebner basis (if `complete_reduction = true` the reduced Groebner basis) of `I`
w.r.t. the given monomial ordering `ord`. The Groebner basis is then
returned as an array of multivariate polynomials.

# Examples
```jldoctest
julia> R, (x, y) = PolynomialRing(QQ, ["x", "y"], ordering=:degrevlex)
(Multivariate Polynomial Ring in x, y over Rational Field, fmpq_mpoly[x, y])

julia> I = ideal([x*y-3*x,y^3-2*x^2*y])
ideal generated by: x*y - 3*x, -2*x^2*y + y^3

julia> H = groebner_basis(I, ord=:lex)
3-element Array{fmpq_mpoly,1}:
 y^4 - 3*y^3
 x*y - 3*x
 -1//6*y^3 + x^2
```
"""
function groebner_basis(I::MPolyIdeal, ord::Symbol; complete_reduction::Bool=false)
  R = singular_ring(base_ring(I), ord)
  !Oscar.Singular.has_global_ordering(R) && error("The ordering has to be a global ordering.")
  i = Singular.std(Singular.Ideal(R, [R(x) for x = gens(I)]), complete_reduction = complete_reduction)
  return collect(BiPolyArray(base_ring(I), i))
end

@doc Markdown.doc"""
    groebner_basis_with_transform(B::BiPolyArray; ord::Symbol = :degrevlex, complete_reduction::Bool = false)

**Note**: Internal function, subject to change, do not use.

Given an `BiPolyArray` `B` and optional parameters `ord` for a monomial ordering and `complete_reduction`
this function computes a Groebner basis (if `complete_reduction = true` the reduced Groebner basis) of the
ideal spanned by the elements in `B` w.r.t. the given monomial ordering `ord` and the transformation matrix from the ideal to the Groebner basis. Return value is a BiPolyArray together with a map.

# Examples
```jldoctest
julia> R, (x, y) = PolynomialRing(QQ, ["x", "y"], ordering=:degrevlex)
(Multivariate Polynomial Ring in x, y over Rational Field, fmpq_mpoly[x, y])

julia> A = Oscar.BiPolyArray([x*y-3*x,y^3-2*x^2*y])
Oscar.BiPolyArray{fmpq_mpoly}(fmpq_mpoly[x*y - 3*x, -2*x^2*y + y^3], #undef, Multivariate Polynomial Ring in x, y over Rational Field, Singular Polynomial Ring (QQ),(x,y),(dp(2),C), false, #undef)

julia> B,m = Oscar.groebner_basis_with_transform(A)
(Oscar.BiPolyArray{fmpq_mpoly}(fmpq_mpoly[#undef, #undef, #undef], Singular Ideal over Singular Polynomial Ring (QQ),(x,y),(dp(2),C) with generators (x*y - 3*x, y^3 - 6*x^2, 6*x^3 - 27*x), Multivariate Polynomial Ring in x, y over Rational Field, Singular Polynomial Ring (QQ),(x,y),(dp(2),C), false, #undef), [1 2*x -2*x^2+y^2+3*y+9; 0 1 -x])
```
"""
function groebner_basis_with_transform(B::BiPolyArray; ord::Symbol = :degrevlex, complete_reduction::Bool = false)
  if ord != :degrevlex
    R = singular_ring(B.Ox, ord)
    i = Singular.Ideal(R, [R(x) for x = B])
#    @show "std on", i, B
    i, m = Singular.lift_std(i, complete_reduction = complete_reduction)
    return BiPolyArray(B.Ox, i), map_entries(x->B.Ox(x), m)
  end
  if !isdefined(B, :S)
    B.S = Singular.Ideal(B.Sx, [B.Sx(x) for x = B.O])
  end
#  @show "dtd", B.S

  i, m = Singular.lift_std(B.S, complete_reduction = complete_reduction)
  return BiPolyArray(B.Ox, i), map_entries(x->B.Ox(x), m)
end


@doc Markdown.doc"""
    groebner_basis_with_transformation_matrix(I::MPolyIdeal; ord::Symbol = :degrevlex, complete_reduction::Bool=false)

Returns a pair `G, m` where `G` is a Groebner basis of the ideal `I` with respect to the
monomial ordering `ord`, and `m` is a transformation matrix from `gens(I)` to `G`. If
`complete_reduction` is set to `true` then `G` will be the reduced Groebner basis.

# Examples
```jldoctest
julia> R,(x,y) = PolynomialRing(QQ,["x","y"])
(Multivariate Polynomial Ring in x, y over Rational Field, fmpq_mpoly[x, y])

julia> I = ideal([x*y^2-1,x^3+y^2+x*y])
ideal generated by: x*y^2 - 1, x^3 + x*y + y^2

julia> G,m = groebner_basis_with_transformation_matrix(I)
(fmpq_mpoly[x*y^2 - 1, x^3 + x*y + y^2, x^2 + y^4 + y], fmpq_mpoly[1 0; 0 1; -x^2 - y y^2])

julia> m * gens(I) == G
true
```
"""
function groebner_basis_with_transformation_matrix(I::MPolyIdeal; ord::Symbol = :degrevlex, complete_reduction::Bool=false)
  G, m = Oscar.groebner_basis_with_transform(I, ord=ord, complete_reduction=complete_reduction)
  return G, Array(m)
end

# syzygies #######################################################
@doc Markdown.doc"""
    syzygy_generators(a::Array{<:MPolyElem, 1})

Given an array of multivariate polynomials this function returns the
generators of the syzygy module of the ideal generated by the given
array elements.

# Examples
```jldoctest
julia> R, (x, y) = PolynomialRing(QQ, ["x", "y"])
(Multivariate Polynomial Ring in x, y over Rational Field, fmpq_mpoly[x, y])

julia> S = syzygy_generators([x^3+y+2,x*y^2-13*x^2,y-14])
3-element Array{AbstractAlgebra.Generic.FreeModuleElem{fmpq_mpoly},1}:
 (0, -y + 14, -13*x^2 + x*y^2)
 (-169*y + 2366, -13*x*y + 182*x - 196*y + 2744, 13*x^2*y^2 - 2548*x^2 + 196*x*y^2 + 169*y + 338)
 (-13*x^2 + 196*x, -x^3 - 16, x^4*y + 14*x^4 + 13*x^2 + 16*x*y + 28*x)
```
"""
function syzygy_generators(a::Array{<:MPolyElem, 1})
  I = ideal(a)
  singular_assure(I)
  s = Singular.syz(I.gens.S)
  F = free_module(parent(a[1]), length(a))
  @assert rank(s) == length(a)
  return [F(s[i]) for i=1:Singular.ngens(s)]
end

# leading ideal #######################################################
@doc Markdown.doc"""
    leading_ideal(g::Array{T, 1}, args...) where { T <: MPolyElem }

Given an array of multivariate polynomials this function returns the
ideal generated by the leading monomials of the given array elements.
If not otherwise given as a further argument this is done w.r.t. the
degree reverse lexicographical monomial ordering.

# Examples
```jldoctest
julia> R, (x, y) = PolynomialRing(QQ, ["x", "y"])
(Multivariate Polynomial Ring in x, y over Rational Field, fmpq_mpoly[x, y])

julia> L = leading_ideal([x*y^2-3*x, x^3-14*y^5])
ideal generated by: x*y^2, x^3
```
"""
function leading_ideal(g::Array{T, 1}, args...) where { T <: MPolyElem }
  return ideal([ leading_monomial(f, args...) for f in g ])
end

@doc Markdown.doc"""
    leading_ideal(g::Array{Any, 1}, args...)

Given an array of fitting type this function returns the ideal 
generated by the leading monomials of the given array elements.
If not otherwise given as a further argument this is done w.r.t.
the degree reverse lexicographical monomial ordering.
"""
function leading_ideal(g::Array{Any, 1}, args...)
  return leading_ideal(typeof(g[1])[ f for f in g ], args...)
end

@doc Markdown.doc"""
    leading_ideal(Rx::MPolyRing, g::Array{Any, 1}, args...)

Given a multivariate polynomial ring `Rx` and an array of elements
this function generates an array of multivariate polynomials in `Rx`
and returns the leading ideal for the ideal generated by the given
array elements w.r.t. the given monomial ordering of `Rx`.

"""
function leading_ideal(Rx::MPolyRing, g::Array{Any, 1}, args...)
  h = elem_type(Rx)[ Rx(f) for f in g ]
  return leading_ideal(h, args...)
end

@doc Markdown.doc"""
    leading_ideal(I::MPolyIdeal)

Given a multivariate polynomial ideal `Ì` this function returns the
leading ideal for `I`. This is done w.r.t. the given monomial ordering
in the polynomial ring of `I`.

# Examples
```jldoctest
julia> R, (x, y) = PolynomialRing(QQ, ["x", "y"])
(Multivariate Polynomial Ring in x, y over Rational Field, fmpq_mpoly[x, y])

julia> I = ideal(R,[x*y^2-3*x, x^3-14*y^5])
ideal generated by: x*y^2 - 3*x, x^3 - 14*y^5

julia> L = leading_ideal(I)
ideal generated by: x*y^2, x^4, x^3
```
"""
function leading_ideal(I::MPolyIdeal)
  return leading_ideal(groebner_basis(I))
end

@doc Markdown.doc"""
    leading_ideal(I::MPolyIdeal, ord::Symbol)

Given a multivariate polynomial ideal `Ì` and a monomial ordering `ord`
this function returns the leading ideal for `I` w.r.t. `ord`.

# Examples
```jldoctest
julia> R, (x, y) = PolynomialRing(QQ, ["x", "y"])
(Multivariate Polynomial Ring in x, y over Rational Field, fmpq_mpoly[x, y])

julia> I = ideal(R,[x*y^2-3*x, x^3-14*y^5])
ideal generated by: x*y^2 - 3*x, x^3 - 14*y^5

julia> L = leading_ideal(I, :lex)
ideal generated by: y^7, x*y^2, x^3
```
"""
function leading_ideal(I::MPolyIdeal, ord::Symbol)
  return leading_ideal(groebner_basis(I, ord), ord)
end

