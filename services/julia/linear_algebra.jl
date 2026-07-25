module LinearAlgebra

export matrix_multiply, matrix_transpose, matrix_inverse, solve_linear_system

# Matrix operations
function matrix_multiply(A::Matrix, B::Matrix)
    m, n = size(A)
    n2, p = size(B)
    
    if n != n2
        error("Matrix dimensions incompatible for multiplication")
    end
    
    C = zeros(m, p)
    for i in 1:m
        for j in 1:p
            for k in 1:n
                C[i, j] += A[i, k] * B[k, j]
            end
        end
    end
    
    return C
end

function matrix_transpose(A::Matrix)
    m, n = size(A)
    B = zeros(n, m)
    
    for i in 1:m
        for j in 1:n
            B[j, i] = A[i, j]
        end
    end
    
    return B
end

# Vector operations
function dot_product(a::Vector, b::Vector)
    if length(a) != length(b)
        error("Vectors must have same length")
    end
    
    sum = 0.0
    for i in 1:length(a)
        sum += a[i] * b[i]
    end
    
    return sum
end

function cross_product(a::Vector, b::Vector)
    if length(a) != 3 || length(b) != 3
        error("Cross product only defined for 3D vectors")
    end
    
    return [
        a[2]*b[3] - a[3]*b[2],
        a[3]*b[1] - a[1]*b[3],
        a[1]*b[2] - a[2]*b[1]
    ]
end

function vector_norm(v::Vector, p::Int=2)
    if p == 1
        return sum(abs.(v))
    elseif p == 2
        return sqrt(sum(v.^2))
    else
        return (sum(abs.(v).^p))^(1/p)
    end
end

# Solve Ax = b
function solve_linear_system(A::Matrix, b::Vector)
    # Using Gaussian elimination
    n = length(b)
    Ab = hcat(A, reshape(b, n, 1))
    
    # Forward elimination
    for i in 1:n-1
        for j in i+1:n
            factor = Ab[j, i] / Ab[i, i]
            Ab[j, :] = Ab[j, :] - factor * Ab[i, :]
        end
    end
    
    # Back substitution
    x = zeros(n)
    for i in n:-1:1
        x[i] = (Ab[i, n+1] - sum(Ab[i, i+1:n] .* x[i+1:n])) / Ab[i, i]
    end
    
    return x
end

end
