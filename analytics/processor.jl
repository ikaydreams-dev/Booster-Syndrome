# Booster Syndrome Julia Data Processor
using DataFrames
using Statistics
using Dates

struct Event
    id::String
    event_type::String
    user_id::Union{String, Nothing}
    timestamp::DateTime
    properties::Dict{String, Any}
end

function process_events(events::Vector{Event})
    df = DataFrame(
        id = [e.id for e in events],
        event_type = [e.event_type for e in events],
        user_id = [e.user_id for e in events],
        timestamp = [e.timestamp for e in events]
    )
    return df
end

function calculate_metrics(df::DataFrame)
    metrics = Dict{String, Any}()

    metrics["total_events"] = nrow(df)
    metrics["unique_users"] = length(unique(skipmissing(df.user_id)))
    metrics["event_types"] = combine(groupby(df, :event_type), nrow => :count)

    return metrics
end

function aggregate_by_hour(df::DataFrame)
    df.hour = Dates.hour.(df.timestamp)

    hourly_counts = combine(groupby(df, :hour), nrow => :count)
    sort!(hourly_counts, :hour)

    return hourly_counts
end

function filter_by_date_range(df::DataFrame, start_date::DateTime, end_date::DateTime)
    return filter(row -> start_date <= row.timestamp <= end_date, df)
end

function calculate_conversion_rate(df::DataFrame, step1::String, step2::String)
    users_step1 = unique(filter(row -> row.event_type == step1, df).user_id)
    users_step2 = unique(filter(row -> row.event_type == step2, df).user_id)

    if length(users_step1) == 0
        return 0.0
    end

    conversion = length(users_step2) / length(users_step1) * 100
    return round(conversion, digits=2)
end

function get_top_events(df::DataFrame, n::Int=10)
    event_counts = combine(groupby(df, :event_type), nrow => :count)
    sort!(event_counts, :count, rev=true)
    return first(event_counts, n)
end

function calculate_daily_active_users(df::DataFrame)
    df.date = Date.(df.timestamp)

    dau = combine(groupby(df, :date)) do group
        DataFrame(
            date = first(group.date),
            active_users = length(unique(skipmissing(group.user_id)))
        )
    end

    sort!(dau, :date)
    return dau
end

function export_to_csv(df::DataFrame, filename::String)
    CSV.write(filename, df)
    println("Exported to: ", filename)
end

function parallel_process(events::Vector{Event}, n_workers::Int=4)
    chunks = partition(events, n_workers)

    results = @distributed (vcat) for chunk in chunks
        process_events(chunk)
    end

    return results
end

function partition(vec::Vector{T}, n::Int) where T
    chunk_size = ceil(Int, length(vec) / n)
    return [vec[i:min(i+chunk_size-1, end)] for i in 1:chunk_size:length(vec)]
end
