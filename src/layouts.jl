abstract type Layout end

function apply(::Layout, canvas::RCanvas)
    error("Application not defined")
end

struct GridLayout <: Layout
    gap_size::Int64
    line_count::Int64

    function GridLayout(gap_size::Int64, line_count::Int64)
        return new(gap_size, line_count)
    end
end
