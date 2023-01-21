export Layout, HorizontalLineLayout, GridLayout
export apply

abstract type Layout end

function apply(l::Layout, canvas::RCanvas)
    apply(l, get_shapes(canvas))
end

function apply(::Layout, shapes::Vector{Shape})
    error("Application not defined")
end

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
struct GridLayout <: Layout
    gap::Int64
    line_count::Int64

    function GridLayout(gap::Int64, line_count::Int64)
        return new(gap, line_count)
    end

    GridLayout() = GridLayout(5, -1)
end

function _get_line_count(l::GridLayout, shapes::Vector{T}) where T <: Shape
    l.line_count > 0 && return l.line_count

    nb_shapes = length(shapes)
    height = trunc(ceil(sqrt(nb_shapes * 0.618034)))
    width = trunc(ceil(nb_shapes / height))
    return width
end

function apply(l::GridLayout, shapes::Vector{Shape})
    lc = _get_line_count(l, shapes)

    position_h = 0
    position_v = 0
    for (index, s) in enumerate(shapes)
        if index > 1
            position_h = position_h + get_width(s) / 2
        end

        translate_to!(s, (position_h, position_v))

        position_h = position_h + get_width(s) / 2 + l.gap
    end
end
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

struct HorizontalLineLayout <: Layout
    gap::Int64

    function HorizontalLineLayout(gap::Int64)
        return new(gap)
    end

    HorizontalLineLayout() = HorizontalLineLayout(5)
end

function apply(l::HorizontalLineLayout, shapes::Vector{Shape})
    g = GridLayout(l.gap, length(shapes))
    apply(g, shapes)
end
