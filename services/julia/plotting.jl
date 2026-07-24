module Plotting

export plot_line, plot_scatter, plot_bar, plot_histogram, plot_heatmap

struct Point
    x::Float64
    y::Float64
end

struct PlotData
    points::Vector{Point}
    title::String
    xlabel::String
    ylabel::String
end

function plot_line(x::Vector{Float64}, y::Vector{Float64}; title="Line Plot", xlabel="X", ylabel="Y")
    points = [Point(xi, yi) for (xi, yi) in zip(x, y)]
    PlotData(points, title, xlabel, ylabel)
end

function plot_scatter(x::Vector{Float64}, y::Vector{Float64}; title="Scatter Plot", xlabel="X", ylabel="Y")
    points = [Point(xi, yi) for (xi, yi) in zip(x, y)]
    PlotData(points, title, xlabel, ylabel)
end

function plot_bar(categories::Vector{String}, values::Vector{Float64}; title="Bar Chart")
    points = [Point(Float64(i), v) for (i, v) in enumerate(values)]
    PlotData(points, title, "Category", "Value")
end

function plot_histogram(data::Vector{Float64}, bins::Int=10; title="Histogram")
    min_val = minimum(data)
    max_val = maximum(data)
    bin_width = (max_val - min_val) / bins

    counts = zeros(Int, bins)
    for value in data
        bin = min(bins, max(1, Int(floor((value - min_val) / bin_width)) + 1))
        counts[bin] += 1
    end

    points = [Point(min_val + (i-0.5)*bin_width, Float64(counts[i])) for i in 1:bins]
    PlotData(points, title, "Value", "Frequency")
end

function plot_heatmap(matrix::Matrix{Float64}; title="Heatmap")
    rows, cols = size(matrix)
    points = Point[]

    for i in 1:rows
        for j in 1:cols
            push!(points, Point(Float64(j), Float64(i)))
        end
    end

    PlotData(points, title, "X", "Y")
end

function normalize(data::Vector{Float64})
    min_val = minimum(data)
    max_val = maximum(data)
    [(x - min_val) / (max_val - min_val) for x in data]
end

function smooth(data::Vector{Float64}, window::Int)
    n = length(data)
    smoothed = similar(data)

    for i in 1:n
        start_idx = max(1, i - window ÷ 2)
        end_idx = min(n, i + window ÷ 2)
        smoothed[i] = mean(data[start_idx:end_idx])
    end

    smoothed
end

function trend_line(x::Vector{Float64}, y::Vector{Float64})
    n = length(x)
    x_mean = mean(x)
    y_mean = mean(y)

    numerator = sum((x .- x_mean) .* (y .- y_mean))
    denominator = sum((x .- x_mean).^2)

    slope = numerator / denominator
    intercept = y_mean - slope * x_mean

    (slope, intercept)
end

function correlation(x::Vector{Float64}, y::Vector{Float64})
    n = length(x)
    x_mean = mean(x)
    y_mean = mean(y)

    numerator = sum((x .- x_mean) .* (y .- y_mean))
    denominator = sqrt(sum((x .- x_mean).^2) * sum((y .- y_mean).^2))

    numerator / denominator
end

function moving_average(data::Vector{Float64}, window::Int)
    n = length(data)
    result = zeros(n)

    for i in window:n
        result[i] = mean(data[(i-window+1):i])
    end

    result
end

function exponential_moving_average(data::Vector{Float64}, alpha::Float64)
    n = length(data)
    result = zeros(n)
    result[1] = data[1]

    for i in 2:n
        result[i] = alpha * data[i] + (1 - alpha) * result[i-1]
    end

    result
end

function detect_peaks(data::Vector{Float64}, threshold::Float64)
    peaks = Int[]

    for i in 2:(length(data)-1)
        if data[i] > data[i-1] && data[i] > data[i+1] && data[i] > threshold
            push!(peaks, i)
        end
    end

    peaks
end

function interpolate(x::Vector{Float64}, y::Vector{Float64}, x_new::Vector{Float64})
    y_new = similar(x_new)

    for (i, xi) in enumerate(x_new)
        idx = searchsortedfirst(x, xi)

        if idx == 1
            y_new[i] = y[1]
        elseif idx > length(x)
            y_new[i] = y[end]
        else
            x1, x2 = x[idx-1], x[idx]
            y1, y2 = y[idx-1], y[idx]
            y_new[i] = y1 + (y2 - y1) * (xi - x1) / (x2 - x1)
        end
    end

    y_new
end

end # module
