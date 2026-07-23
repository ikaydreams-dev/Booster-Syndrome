using Plots
using Statistics

module GraphPlotter
    export create_line_plot, create_scatter_plot, create_histogram

    function create_line_plot(x::Vector, y::Vector, title::String="Line Plot")
        plot(x, y,
             title=title,
             xlabel="X Axis",
             ylabel="Y Axis",
             linewidth=2,
             legend=false)
    end

    function create_scatter_plot(x::Vector, y::Vector, title::String="Scatter Plot")
        scatter(x, y,
                title=title,
                xlabel="X Axis",
                ylabel="Y Axis",
                markersize=5,
                legend=false)
    end

    function create_histogram(data::Vector, bins::Int=30, title::String="Histogram")
        histogram(data,
                  bins=bins,
                  title=title,
                  xlabel="Value",
                  ylabel="Frequency",
                  legend=false)
    end

    function create_multi_line_plot(datasets::Vector{Tuple{Vector, Vector, String}})
        p = plot()

        for (x, y, label) in datasets
            plot!(p, x, y, label=label, linewidth=2)
        end

        return p
    end

    function create_box_plot(data::Vector{Vector{Float64}}, labels::Vector{String})
        boxplot(labels, data,
                xlabel="Category",
                ylabel="Value",
                legend=false)
    end

    function save_plot(p, filename::String)
        savefig(p, filename)
    end

    function calculate_moving_average(data::Vector{Float64}, window::Int)
        n = length(data)
        result = zeros(n)

        for i in 1:n
            start_idx = max(1, i - window + 1)
            result[i] = mean(data[start_idx:i])
        end

        return result
    end
end
