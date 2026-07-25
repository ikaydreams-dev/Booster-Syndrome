module Statistics

export mean, median, variance, std_dev, correlation, quantile

function mean(data::Vector{<:Real})
    return sum(data) / length(data)
end

function median(data::Vector{<:Real})
    sorted = sort(data)
    n = length(sorted)
    
    if n % 2 == 0
        return (sorted[n÷2] + sorted[n÷2 + 1]) / 2
    else
        return sorted[n÷2 + 1]
    end
end

function variance(data::Vector{<:Real})
    m = mean(data)
    return sum((x - m)^2 for x in data) / length(data)
end

function std_dev(data::Vector{<:Real})
    return sqrt(variance(data))
end

function correlation(x::Vector{<:Real}, y::Vector{<:Real})
    if length(x) != length(y)
        error("Vectors must have same length")
    end
    
    mx = mean(x)
    my = mean(y)
    
    numerator = sum((x[i] - mx) * (y[i] - my) for i in 1:length(x))
    denominator = sqrt(sum((x[i] - mx)^2 for i in 1:length(x)) * 
                       sum((y[i] - my)^2 for i in 1:length(y)))
    
    return numerator / denominator
end

function quantile(data::Vector{<:Real}, q::Real)
    if q < 0 || q > 1
        error("Quantile must be between 0 and 1")
    end
    
    sorted = sort(data)
    n = length(sorted)
    index = q * (n - 1) + 1
    
    if index == floor(index)
        return sorted[Int(index)]
    else
        lower = sorted[Int(floor(index))]
        upper = sorted[Int(ceil(index))]
        return lower + (upper - lower) * (index - floor(index))
    end
end

function covariance(x::Vector{<:Real}, y::Vector{<:Real})
    if length(x) != length(y)
        error("Vectors must have same length")
    end
    
    mx = mean(x)
    my = mean(y)
    
    return sum((x[i] - mx) * (y[i] - my) for i in 1:length(x)) / length(x)
end

end
