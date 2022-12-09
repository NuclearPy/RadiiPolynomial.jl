abstract type Symmetry end

struct NoSymmetry <: Symmetry end

Base.issubset(::Symmetry, ::Symmetry) = false
Base.issubset(::T, ::T) where {T<:Symmetry} = true
Base.intersect(::Symmetry, ::Symmetry) = NoSymmetry()
Base.intersect(::T, ::T) where {T<:Symmetry} = T()
Base.union(::Symmetry, ::Symmetry) = NoSymmetry()
Base.union(::T, ::T) where {T<:Symmetry} = T()

image(::typeof(+), ::Symmetry, ::Symmetry) = NoSymmetry()
image(::typeof(*), ::Symmetry, ::Symmetry) = NoSymmetry()
image(::SpecialOperator, ::Symmetry) = NoSymmetry()





###############





struct SymBaseSpace{T<:Symmetry,S<:BaseSpace} <: BaseSpace
    symmetry :: T
    space :: S
    SymBaseSpace{T,S}(symmetry::T, space::S) where {T<:Symmetry,S<:BaseSpace} =
        new{T,S}(symmetry, space)
    SymBaseSpace{NoSymmetry,S}(::NoSymmetry, space::S) where {S<:BaseSpace} =
        space
    SymBaseSpace{NoSymmetry,S}(::NoSymmetry, space::S) where {S<:SymBaseSpace} =
        desymmetrize(space)
    SymBaseSpace{T,S}(::T, space::S) where {T<:Symmetry,S<:SymBaseSpace{T}} =
        space
    SymBaseSpace{T,S}(::T, ::S) where {T<:Symmetry,S<:SymBaseSpace} =
        throw(ArgumentError("nesting symmetries is not supported"))
end

SymBaseSpace(symmetry::T, space::S) where {T<:Symmetry,S<:BaseSpace} = SymBaseSpace{T,S}(symmetry, space)

(::Type{T})(s::BaseSpace) where {T<:Symmetry} = SymBaseSpace(T(), s)

symmetry(s::SymBaseSpace) = s.symmetry
symmetry(::BaseSpace) = NoSymmetry()
symmetry(s::TensorSpace) = map(symmetry, spaces(s))
desymmetrize(s::SymBaseSpace) = s.space
desymmetrize(s::TensorSpace) = TensorSpace(map(desymmetrize, spaces(s)))
desymmetrize(s::BaseSpace) = s

# vector space methods

order(s::SymBaseSpace) = order(desymmetrize(s))
frequency(s::SymBaseSpace) = frequency(desymmetrize(s))

Base.:(==)(s₁::SymBaseSpace, s₂::SymBaseSpace) = (symmetry(s₁) == symmetry(s₂)) & (desymmetrize(s₁) == desymmetrize(s₂))
Base.issubset(s₁::SymBaseSpace, s₂::SymBaseSpace) = issubset(symmetry(s₁), symmetry(s₂)) & issubset(desymmetrize(s₁), desymmetrize(s₂))
Base.issubset(s₁::SymBaseSpace, s₂::BaseSpace) = issubset(desymmetrize(s₁), s₂)
Base.intersect(s₁::SymBaseSpace, s₂::SymBaseSpace) = SymBaseSpace(intersect(symmetry(s₁), symmetry(s₂)), intersect(desymmetrize(s₁), desymmetrize(s₂)))
Base.intersect(s₁::SymBaseSpace, s₂::BaseSpace) = SymBaseSpace(symmetry(s₁), intersect(desymmetrize(s₁), s₂))
Base.intersect(s₁::BaseSpace, s₂::SymBaseSpace) = SymBaseSpace(symmetry(s₂), intersect(s₁, desymmetrize(s₂)))
Base.union(s₁::SymBaseSpace, s₂::SymBaseSpace) = SymBaseSpace(union(symmetry(s₁), symmetry(s₂)), union(desymmetrize(s₁), desymmetrize(s₂)))
Base.union(s₁::SymBaseSpace, s₂::BaseSpace) = union(desymmetrize(s₁), s₂)
Base.union(s₁::BaseSpace, s₂::SymBaseSpace) = union(s₁, desymmetrize(s₂))

_findposition(u::AbstractVector{Int}, s::SymBaseSpace) = map(i -> _findposition(i, s), u)
_findposition(c::Colon, ::SymBaseSpace) = c

Base.convert(::Type{T}, s::T) where {T<:SymBaseSpace} = s
Base.convert(::Type{SymBaseSpace{T,S}}, s::SymBaseSpace) where {T<:Symmetry,S<:BaseSpace} =
    SymBaseSpace{T,S}(convert(T, symmetry(s)), convert(S, desymmetrize(s)))

Base.promote_rule(::Type{T}, ::Type{T}) where {T<:SymBaseSpace} = T
Base.promote_rule(::Type{SymBaseSpace{T₁,S₁}}, ::Type{SymBaseSpace{T₂,S₂}}) where {T₁<:Symmetry,S₁<:BaseSpace,T₂<:Symmetry,S₂<:BaseSpace} =
    SymBaseSpace{promote_type(T₁, T₂), promote_type(S₁, S₂)}

_iscompatible(s₁::SymBaseSpace, s₂::SymBaseSpace) =
    (symmetry(s₁) == symmetry(s₂)) & _iscompatible(desymmetrize(s₁), desymmetrize(s₂))

# arithmetic methods

image(::typeof(+), s₁::SymBaseSpace, s₂::SymBaseSpace) =
    SymBaseSpace(image(+, symmetry(s₁), symmetry(s₂)), image(+, desymmetrize(s₁), desymmetrize(s₂)))

image(::typeof(*), s₁::SymBaseSpace, s₂::SymBaseSpace) =
    SymBaseSpace(image(*, symmetry(s₁), symmetry(s₂)), image(*, desymmetrize(s₁), desymmetrize(s₂)))

image(A::SpecialOperator, s::SymBaseSpace) = SymBaseSpace(image(A, symmetry(s)), image(A, desymmetrize(s)))





###############

struct Even <: Symmetry end

indices(s::SymBaseSpace{Even,<:Fourier}) = 0:order(s)

_findindex_constant(s::SymBaseSpace{Even,<:Fourier}) = 0
_findposition(i::Int, ::SymBaseSpace{Even,<:Fourier}) = i + 1
_findposition(u::AbstractRange{Int}, ::SymBaseSpace{Even,<:Fourier}) = u .+ 1

#

struct Odd <: Symmetry end

indices(s::SymBaseSpace{Odd,<:Fourier}) = 1:order(s)

_findindex_constant(s::SymBaseSpace{Odd,<:Fourier}) = 1
_findposition(i::Int, ::SymBaseSpace{Odd,<:Fourier}) = i
_findposition(u::AbstractRange{Int}, ::SymBaseSpace{Odd,<:Fourier}) = u

#

image(::typeof(+), ::Even, ::Even) = Even()
image(::typeof(*), ::Even, ::Even) = Even()
image(::typeof(add_bar), ::Even, ::Even) = Even()
image(::typeof(mul_bar), ::Even, ::Even) = Even()

image(::typeof(+), ::Odd, ::Odd) = Odd()
image(::typeof(*), ::Odd, ::Odd) = Even()
image(::typeof(add_bar), ::Odd, ::Odd) = Odd()
image(::typeof(mul_bar), ::Odd, ::Odd) = Even()

# Convolution

_convolution_indices(s₁::SymBaseSpace{Even,<:Fourier}, s₂::SymBaseSpace{Even,<:Fourier}, i) =
    _convolution_indices(Chebyshev(order(s₁)), Chebyshev(order(s₂)), i)

# Derivative

image(𝒟::Derivative, s::SymBaseSpace{Even,<:Fourier}) = iseven(order(𝒟)) ? s : throw(DomainError) # SymBaseSpace(Odd(), desymmetrize(s))

_coeftype(::Derivative, ::SymBaseSpace{Even,Fourier{T}}, ::Type{S}) where {T,S} = typeof(zero(T)*0*zero(S))

function _apply!(c::Sequence{<:SymBaseSpace{Even,<:Fourier}}, 𝒟::Derivative, a)
    n = order(𝒟)
    if n == 0
        coefficients(c) .= coefficients(a)
    else
        ω = one(eltype(a))*frequency(a)
        @inbounds c[0] = zero(eltype(c))
        iⁿ_real = ifelse(n%4 == 0, 1, -1)
        @inbounds for j ∈ 1:order(c)
            iⁿωⁿjⁿ_real = iⁿ_real*(ω*j)^n
            c[j] = iⁿωⁿjⁿ_real * a[j]
        end
    end
    return c
end

function _apply!(C::AbstractArray{T}, 𝒟::Derivative, space::SymBaseSpace{Even,<:Fourier}, A) where {T}
    n = order(𝒟)
    if n == 0
        C .= A
    else
        ord = order(space)
        ω = one(eltype(A))*frequency(space)
        @inbounds selectdim(C, 1, 1) .= zero(T)
        iⁿ_real = ifelse(n%4 == 0, 1, -1)
        @inbounds for j ∈ 1:ord
            iⁿωⁿjⁿ_real = iⁿ_real*(ω*j)^n
            selectdim(C, 1, j+1) .= iⁿωⁿjⁿ_real .* selectdim(A, 1, j+1)
        end
    end
    return C
end

function _apply(𝒟::Derivative, space::SymBaseSpace{Even,<:Fourier}, ::Val{D}, A::AbstractArray{T,N}) where {D,T,N}
    n = order(𝒟)
    CoefType = _coeftype(𝒟, space, T)
    if n == 0
        return convert(Array{CoefType,N}, A)
    else
        C = Array{CoefType,N}(undef, size(A))
        ord = order(space)
        ω = one(T)*frequency(space)
        @inbounds selectdim(C, D, 1) .= zero(CoefType)
        iⁿ_real = ifelse(n%4 == 0, 1, -1)
        @inbounds for j ∈ 1:ord
            iⁿωⁿjⁿ_real = iⁿ_real*(ω*j)^n
            selectdim(C, D, j+1) .= iⁿωⁿjⁿ_real .* selectdim(A, D, j+1)
        end
        return C
    end
end

function _nzind_domain(::Derivative, domain::SymBaseSpace{Even,<:Fourier}, codomain::SymBaseSpace{Even,<:Fourier})
    ω₁ = frequency(domain)
    ω₂ = frequency(codomain)
    ω₁ == ω₂ || return throw(ArgumentError("frequencies must be equal: s₁ has frequency $ω₁, s₂ has frequency $ω₂"))
    ord = min(order(domain), order(codomain))
    return 1:ord
end

function _nzind_codomain(::Derivative, domain::SymBaseSpace{Even,<:Fourier}, codomain::SymBaseSpace{Even,<:Fourier})
    ω₁ = frequency(domain)
    ω₂ = frequency(codomain)
    ω₁ == ω₂ || return throw(ArgumentError("frequencies must be equal: s₁ has frequency $ω₁, s₂ has frequency $ω₂"))
    ord = min(order(domain), order(codomain))
    return 1:ord
end

function _nzval(𝒟::Derivative, domain::SymBaseSpace{Even,<:Fourier}, ::SymBaseSpace{Even,<:Fourier}, ::Type{T}, i, j) where {T}
    n = order(𝒟)
    if n == 0
        return one(T)
    else
        ωⁿjⁿ = (one(T)*frequency(domain)*j)^n
        r = n % 4
        if r == 0
            return convert(T, ωⁿjⁿ)
        else
            return convert(T, -ωⁿjⁿ)
        end
    end
end

# Evaluation

_memo(::SymBaseSpace{Even,<:Fourier}, ::Type{T}) where {T} = Dict{Int,T}()

image(::Evaluation{Nothing}, s::SymBaseSpace{Even,<:Fourier}) = s
image(::Evaluation, s::SymBaseSpace{Even,<:Fourier}) = SymBaseSpace(symmetry(s), Fourier(0, frequency(s)))

_coeftype(::Evaluation{Nothing}, ::SymBaseSpace{Even,<:Fourier}, ::Type{T}) where {T} = T
_coeftype(::Evaluation{T}, s::SymBaseSpace{Even,<:Fourier}, ::Type{S}) where {T,S} =
    promote_type(typeof(cos(frequency(s)*zero(T))), S)

function _apply!(c::Sequence{<:SymBaseSpace{Even,<:Fourier}}, ::Evaluation{Nothing}, a)
    coefficients(c) .= coefficients(a)
    return c
end
function _apply!(c::Sequence{<:SymBaseSpace{Even,<:Fourier}}, ℰ::Evaluation, a)
    x = value(ℰ)
    ord = order(a)
    @inbounds c[0] = a[ord]
    if ord > 0
        if iszero(x)
            @inbounds for j ∈ ord-1:-1:1
                c[0] += a[j]
            end
        else
            ωx = frequency(a)*x
            @inbounds c[0] *= cos(ωx*ord)
            @inbounds for j ∈ ord-1:-1:1
                c[0] += a[j] * cos(ωx*j)
            end
        end
        @inbounds c[0] = 2c[0] + a[0]
    end
    return c
end

function _apply!(C::AbstractArray, ::Evaluation{Nothing}, ::SymBaseSpace{Even,<:Fourier}, A)
    C .= A
    return C
end
function _apply!(C::AbstractArray, ℰ::Evaluation, space::SymBaseSpace{Even,<:Fourier}, A)
    x = value(ℰ)
    ord = order(space)
    @inbounds C .= selectdim(A, 1, ord+1)
    if ord > 0
        if iszero(x)
            @inbounds for j ∈ ord-1:-1:1
                C .+= selectdim(A, 1, j+1)
            end
        else
            ωx = frequency(space)*x
            C .*= cos(ωx*ord)
            @inbounds for j ∈ ord-1:-1:1
                C .+= selectdim(A, 1, j+1) .* cos(ωx*j)
            end
        end
        @inbounds C .= 2 .* C .+ selectdim(A, 1, 1)
    end
    return C
end

_apply(::Evaluation{Nothing}, ::SymBaseSpace{Even,<:Fourier}, ::Val, A::AbstractArray) = A
function _apply(ℰ::Evaluation, space::SymBaseSpace{Even,<:Fourier}, ::Val{D}, A::AbstractArray{T,N}) where {D,T,N}
    x = value(ℰ)
    CoefType = _coeftype(ℰ, space, T)
    ord = order(space)
    @inbounds C = convert(Array{CoefType,N-1}, selectdim(A, D, ord+1))
    if ord > 0
        if iszero(x)
            @inbounds for j ∈ ord-1:-1:1
                C .+= selectdim(A, D, j+1)
            end
        else
            ωx = frequency(space)*x
            C .*= cos(ωx*ord)
            @inbounds for j ∈ ord-1:-1:1
                C .+= selectdim(A, D, j+1) .* cos(ωx*j)
            end
        end
        @inbounds C .= 2 .* C .+ selectdim(A, D, 1)
    end
    return C
end

function _getindex(ℰ::Evaluation, domain::SymBaseSpace{Even,<:Fourier}, ::SymBaseSpace{Even,<:Fourier}, ::Type{T}, i, j, memo) where {T}
    if i == 0
        x = value(ℰ)
        if j == 0
            return one(T)
        elseif iszero(x)
            return convert(T, 2one(T))
        else
            return convert(T, 2cos(frequency(domain)*j*x))
        end
    else
        return zero(T)
    end
end

# Multiplication

function _project!(C::LinearOperator{<:SymBaseSpace{Even,<:Fourier},<:SymBaseSpace{Even,<:Fourier}}, ℳ::Multiplication)
    C_ = LinearOperator(Chebyshev(order(domain(C))), Chebyshev(order(codomain(C))), coefficients(C))
    a = sequence(ℳ)
    ℳ_ = Multiplication(Sequence(Chebyshev(order(space(a))), coefficients(a)))
    _project!(C_, ℳ_)
    return C
end

_mult_domain_indices(s::SymBaseSpace{Even,<:Fourier}) = _mult_domain_indices(Chebyshev(order(s)))
_isvalid(s::SymBaseSpace{Even,<:Fourier}, i::Int, j::Int) = _isvalid(Chebyshev(order(s)), i, j)
_extract_valid_index(s::SymBaseSpace{Even,<:Fourier}, i::Int, j::Int) = _extract_valid_index(Chebyshev(order(s)), i, j)

# Norm

_apply(::Ell2{IdentityWeight}, ::SymBaseSpace{Even,<:Fourier}, A::AbstractVector) =
    @inbounds sqrt(abs2(A[1]) + 2sum(abs2, view(A, 2:length(A))))
_apply_dual(::Ell2{IdentityWeight}, ::SymBaseSpace{Even,<:Fourier}, A::AbstractVector) =
    @inbounds sqrt(abs2(A[1]) + sum(abs2, view(A, 2:length(A)))/2)
