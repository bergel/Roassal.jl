export Layout
export FlowLayout, ForceBasedLayout, HorizontalLineLayout, GridLayout, VerticalLineLayout
export apply
export TreeLayout

abstract type Layout end

function apply(l::Layout, canvas::RCanvas)
    apply(l, convert(Vector{BoundedShape}, get_nodes(canvas)))
end

function apply(l::Layout, shapes::Vector{BoundedShape})
    error("Application not defined for $(typeof(l))")
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

function _get_line_count(l::GridLayout, shapes::Vector{T}) where T <: BoundedShape
    l.line_count > 0 && return l.line_count

    nb_shapes = length(shapes)
    height = trunc(ceil(sqrt(nb_shapes * 0.618034)))
    width = trunc(ceil(nb_shapes / height))
    return width
end

function apply(l::GridLayout, shapes::Vector{BoundedShape})
    lc = _get_line_count(l, shapes)

    local position_h = 0
    local position_v = 0
    local max_height = 0
    for (index, s) in enumerate(shapes)
        translate_topleft_to!(s, (position_h, position_v))

        max_height = max(max_height, get_height(s))
        if mod(index, lc) == 0
            position_v = position_v + max_height + l.gap
            position_h = 0
            max_height = 0
        else
            position_h = position_h + get_width(s) + l.gap
        end
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

function apply(l::HorizontalLineLayout, shapes::Vector{BoundedShape})
    g = GridLayout(l.gap, length(shapes))
    apply(g, shapes)
end
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

struct VerticalLineLayout <: Layout
    gap::Int64

    function VerticalLineLayout(gap::Int64)
        return new(gap)
    end

    VerticalLineLayout() = VerticalLineLayout(5)
end

function apply(l::VerticalLineLayout, shapes::Vector{BoundedShape})
    g = GridLayout(l.gap, 1)
    apply(g, shapes)
end
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

# https://faculty.washington.edu/joelross/courses/archive/s13/cs261/lab/k/

struct FlowLayout <: Layout
    gap::Int64
    max_width::Int64

    FlowLayout(gap::Int64, max_width::Int64) = new(gap, max_width)
    FlowLayout(gap::Int64) = FlowLayout(gap, -1)
    FlowLayout() = FlowLayout(5)
end

function _compute_max_width(l::FlowLayout, shapes::Vector{T}) where T <: Shape
    total_width_shapes = sum(map(s -> get_width(s) + 2*l.gap, shapes))
    #height = trunc(ceil(sqrt(total_width_shapes * 0.9)))
    #width = trunc(ceil(total_width_shapes / height))
    return total_width_shapes / 5
end

function apply(l::FlowLayout, shapes::Vector{BoundedShape})
    if l.max_width == -1
        max_width = _compute_max_width(l, shapes)
    else
        max_width = l.max_width
    end

    local position_h = 0
    local position_v = 0
    local max_height = 0
    for (_, s) in enumerate(shapes)
        translate_topleft_to!(s, (position_h, position_v))

        max_height = max(max_height, get_height(s))
        if position_h > max_width
            position_v = position_v + max_height + l.gap
            position_h = 0
            max_height = 0
        else
            position_h = position_h + get_width(s) + l.gap
        end
    end
end
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

struct ForceBasedLayout <: Layout
    iterations::Int64
    C::Number
    K::Number
    gravity::Tuple{Number,Number}
    friction::Number
    #theta::Number
    ForceBasedLayout() = new(50, 0.2, 1.0)
    ForceBasedLayout(C::Number, K::Number) = new(50, C, K)
    ForceBasedLayout(iterations::Int64) = new(iterations, 0.2, 1.0)
    ForceBasedLayout(iterations::Int64, C::Number, K::Number) = new(iterations, C, K)
end

function _before_apply(l::ForceBasedLayout, shapes::Vector{BoundedShape})
    apply(GridLayout(), shapes)
end

function _after_apply(l::ForceBasedLayout, shapes::Vector{BoundedShape})
end

function _step_node_repulsion(l::ForceBasedLayout, shapes::Vector{BoundedShape})
    repulsions = Dict{Shape,Tuple{Number,Number}}()
    for s in shapes
        repulsions[s] = (0.0, 0.0)
    end

    for s1 in shapes
        for s2 in shapes
            s1 == s2 && continue
            d = pos(s1) .- pos(s2)
            distance = sqrt(d[1]*d[1] + d[2]*d[2])
            norm = d ./ distance
            r = -1 * l.C * l.K * l.K / distance
            repulsions[s1] = repulsions[s1] .- (norm[1]*r, norm[2]*r)
            repulsions[s2] = repulsions[s2] .+ (norm[1]*r, norm[2]*r)
        end
    end
    return repulsions
end

function _step_edge_forces(l::ForceBasedLayout, lines::Vector{RLine})
    attractions = Dict{RLine,Number}()
    for line in lines
        dist = pos(line.to) .- pos(line.from)
        d_tmp = 30 - sqrt(dist[1]*dist[1] + dist[2]*dist[2])
        att = d_tmp*d_tmp / l.K
        attractions[line] = d_tmp > 0 ? att : att * -1
    end

    attractions_per_shape = Dict{Shape,Tuple{Number,Number}}()
    for line in lines
        attractions_per_shape[line.from] = (0.0, 0.0)
        attractions_per_shape[line.to] = (0.0, 0.0)
    end
    for line in lines
        d = (pos(line.to) .- pos(line.from))
        distance = sqrt(d[1]*d[1] + d[2]*d[2])
        norm = d ./ distance
        attractions_per_shape[line.from] = attractions_per_shape[line.from] .+ (norm .* attractions[line] .* -1)
        attractions_per_shape[line.to] = attractions_per_shape[line.to] .+ (norm .* attractions[line])
    end

    return attractions_per_shape
end

function _step(l::ForceBasedLayout, shapes::Vector{BoundedShape}, lines::Vector{RLine})
    attractions = _step_edge_forces(l, lines)
    #_step_gravity_force(l, shapes, lines)

    repulsions = _step_node_repulsion(l, shapes)

    println("DEB1: attractions=$(values(attractions))")
    println("DEB2: repulsions=$(values(repulsions))")

    # applying translation
    for s in shapes
        translate_by!(s, repulsions[s])
        haskey(attractions, s) && translate_by!(s, attractions[s])
    end
end

function apply(l::ForceBasedLayout, shapes::Vector{BoundedShape})
    lines = Vector{RLine}()
    for s in shapes
        !(s isa RLine) && push!(lines, s.outgoing_edges...)
    end

    apply(l, shapes, lines)
end

function apply(l::ForceBasedLayout, shapes::Vector{BoundedShape}, lines::Vector{RLine})
    _before_apply(l, shapes)
    for _ in 1:l.iterations
        _step(l, shapes, lines)
    end
    _after_apply(l, shapes)
end
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

struct TreeLayout <: Layout

end

struct TreeNode{T}
    value::T
    children::Vector{TreeNode{T}}
    parents::Vector{TreeNode{T}}
end
TreeNode{T}(value::T) where T = TreeNode(value, TreeNode{T}[], TreeNode{T}[])

function subtree_width(node::TreeNode)
    isempty(node.children) && return 1
    sum(subtree_width(c) for c in node.children)
end

function layout_tree(
    node::TreeNode,
    x::Float64,
    y::Float64,
    dx::Float64 = 1.0,
    dy::Float64 = 1.0,
    positions = Dict{TreeNode, Tuple{Float64, Float64}}()
)
    positions[node] = (x, y)

    if isempty(node.children)
        return positions
    end

    total_width = sum(subtree_width(c) for c in node.children)
    start_x = x - dx * total_width / 2

    current_x = start_x
    for child in node.children
        w = subtree_width(child)
        child_x = current_x + dx * w / 2
        layout_tree(child, child_x, y - dy, dx, dy, positions)
        current_x += dx * w
    end

    return positions
end

# Simplified version of Reingold–Tilford tidy tree layout.
function apply(l::TreeLayout, shapes::Vector{BoundedShape})
    # Build tree structure from shapes
    shape_to_tree_nodes = Dict{BoundedShape, TreeNode{BoundedShape}}()
    for s in shapes
        haskey(shape_to_tree_nodes, s) && continue
        node = TreeNode{BoundedShape}(s)
        shape_to_tree_nodes[s] = node
        for line in s.outgoing_edges
            isdefined(Main, :Infiltrator) && Main.infiltrate(@__MODULE__, Base.@locals, @__FILE__, @__LINE__)
            child_shape = line.to
            child_shape in shapes || continue
            haskey(shape_to_tree_nodes, child_shape) && continue
            child_node = TreeNode{BoundedShape}(child_shape)
            push!(node.children, child_node)
            push!(child_node.parents, node)
            shape_to_tree_nodes[child_shape] = child_node
        end
    end

    root_nodes = TreeNode{BoundedShape}[]
    for node in values(shape_to_tree_nodes)
        isempty(node.parents) && push!(root_nodes, node)
    end
isdefined(Main, :Infiltrator) && Main.infiltrate(@__MODULE__, Base.@locals, @__FILE__, @__LINE__)

    if isempty(root_nodes)
        @error "No root node found for tree layout"
        return
    end

    positions = layout_tree(root_nodes[1], 0.0, 0.0, 30.0, 30.0)

    for (node, (x, y)) in positions
        translate_to!(node.value, (x, y))
    end
isdefined(Main, :Infiltrator) && Main.infiltrate(@__MODULE__, Base.@locals, @__FILE__, @__LINE__)

    # error("Not implemented yet")
end