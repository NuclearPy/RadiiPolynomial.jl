# sparse

SparseArrays.sparse(a::Sequence) = Sequence(space(a), sparse(coefficients(a)))
SparseArrays.sparse(A::LinearOperator) = LinearOperator(domain(A), codomain(A), sparse(coefficients(A)))

# condition number

LinearAlgebra.cond(A::LinearOperator, p::Real=2) = cond(coefficients(A), p)

# transpose, adjoint

LinearAlgebra.transpose(a::Sequence) = LinearOperator(space(a), ParameterSpace(), transpose(coefficients(a)))
LinearAlgebra.transpose(A::LinearOperator) = LinearOperator(codomain(A), domain(A), transpose(coefficients(A)))

LinearAlgebra.adjoint(a::Sequence) = LinearOperator(space(a), ParameterSpace(), adjoint(coefficients(a)))
LinearAlgebra.adjoint(A::LinearOperator) = LinearOperator(codomain(A), domain(A), adjoint(coefficients(A)))

# eigen

function LinearAlgebra.eigvals(A::LinearOperator; kwargs...)
    domain_A = domain(A)
    codomain_A = codomain(A)
    domain_A == codomain_A || return throw(ArgumentError("spaces must be equal: A has domain $domain_A, A has codomain $codomain_A"))
    return eigvals(coefficients(A); kwargs...)
end

function LinearAlgebra.eigvecs(A::LinearOperator; kwargs...)
    domain_A = domain(A)
    codomain_A = codomain(A)
    domain_A == codomain_A || return throw(ArgumentError("spaces must be equal: A has domain $domain_A, A has codomain $codomain_A"))
    Ξ = eigvecs(coefficients(A); kwargs...)
    return LinearOperator(ParameterSpace()^size(Ξ, 2), domain(A), Ξ)
end

function LinearAlgebra.eigen(A::LinearOperator; kwargs...)
    domain_A = domain(A)
    codomain_A = codomain(A)
    domain_A == codomain_A || return throw(ArgumentError("spaces must be equal: A has domain $domain_A, A has codomain $codomain_A"))
    Λ, Ξ = eigen(coefficients(A); kwargs...)
    return Λ, LinearOperator(ParameterSpace()^size(Ξ, 2), domain(A), Ξ)
end

# kernel

function LinearAlgebra.nullspace(A::LinearOperator; kwargs...)
    Ξ = nullspace(coefficients(A); kwargs...)
    return LinearOperator(ParameterSpace()^size(Ξ, 2), domain(A), Ξ)
end
