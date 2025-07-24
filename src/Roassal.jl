module Roassal

# ------------------------------------
# Graphic
using Gtk, Graphics
# ------------------------------------
# Modeling
export Shape
export pos, extent, compute_encompassing_rectangle
export translate_to!, translate_topleft_to!, extent!, translate_by!
export get_width, get_height

export random_color

export RBox, get_color, set_color!
export RCircle, set_size!

export RText

export RLine

export RColor, RColor_BLUE, RColor_GREEN, RColor_RED

export RCanvas
export number_of_shapes, add!, remove_shape!, rshow
export rendererVisitor
export get_shape_at_position
export offset_from_canvas_to_screen, offsetFromScreenToCanvas
export get_shapes, get_nodes, get_edges
export center!, refresh, get_shape, push_lines_back

export Callback
export numberOfCallbacks, add_callback!, trigger_callback

export get_model

export highlightable
export popup

# ------------------------------------
"""
Shape definitions
"""
abstract type Shape end
abstract type BoundedShape <: Shape end


get_model(shape::Shape) = shape.model

function set_model!(shape::Shape, value::Any)
    shape.model = value
end

# ------------------------------------
"""
Model a box
"""
mutable struct RBox <: BoundedShape
    color
    x
    y
    width
    height
    callbacks
    canvas
    outgoing_edges
    incoming_edges
    model
end

function RBox(;color=RColor(),
        x::Int64=0, y::Int64=0,
        width::Int64=10, height::Int64=10, size::Int64=0, model=nothing)

    size > 0 && return RBox(color, x, y, size, size, [], nothing, [], [], model)
    return RBox(color, x, y, width, height, [], nothing, [], [], model)
end

# Base.show(io::IO, b::RBox) = Base.show(io, MIME"text/plain", b)

function Base.show(io::IO, b::RBox)
    print(io, "RBox{ pos:$((b.x, b.y)), width: $(b.width), height: $(b.height), color:$(b.color), model:$(b.model) }")
end

pos(s::BoundedShape) = (s.x, s.y)
extent(s::BoundedShape) = (s.width, s.height)
get_width(s::BoundedShape) = extent(s)[1]
get_height(s::BoundedShape) = extent(s)[2]

mutable struct RCircle <: BoundedShape
    color
    x
    y
    width
    height
    callbacks
    canvas
    outgoing_edges
    incoming_edges
    model
end

function RCircle(;
    color=RColor(),
    x=0, y=0,
    radius=10,
    width=0,
    height=0,
    model=nothing,
)
    if radius > 0 && width == 0 && height == 0
        width = radius * 2
        height = radius * 2
    end
    return RCircle(color, x, y, width, height, [], nothing, [], [], model)
end

function Base.show(io::IO, c::RCircle)
    print(io, "RCircle{ pos:$((c.x, c.y)), color:$(c.color), model:$(c.model) }")
end

function set_size!(circle::RCircle, size::Float64)
    circle.width = size
    circle.height = size
end

function set_color!(s::Shape, color)
    s.color = color
end

function get_color(s::Shape)
    return s.color
end

function extent!(s::BoundedShape, width, height)
    s.width = width
    s.height = height
    return s
end

translate_to!(s::BoundedShape, p::Tuple{Number, Number}) =  translate_to!(s, p[1], p[2])

function translate_to!(s::BoundedShape, x::Number, y::Number)
    s.x = x
    s.y = y
    return s
end

translate_topleft_to!(s::BoundedShape, p::Tuple{Number, Number}) = translate_topleft_to!(s, p[1], p[2])

function translate_topleft_to!(s::BoundedShape, x::Number, y::Number)
    s.x = x + s.width / 2
    s.y = y + s.height / 2
    return s
end

translate_by!(s::BoundedShape, p::Tuple{Number, Number}) = translate_by!(s, p[1], p[2])

function translate_by!(s::BoundedShape, dx::Number, dy::Number)
    s.x = s.x + dx
    s.y = s.y + dy
    return s
end

# Return (x, y, w, h)
function compute_encompassing_rectangle(s::BoundedShape)
    x = s.x - (s.width / 2)
    y = s.y - (s.height / 2)
    return (x, y, s.width, s.height)
end

# Return (x, y, w, h)
function compute_encompassing_rectangle(shapes::Vector{Shape})
    isempty(shapes) && return (0, 0, 0, 0)

    # Compute the encompassing rectangle of all shapes
    es = map(compute_encompassing_rectangle, shapes)
    topleft_x = minimum(t -> t[1], es)
    topleft_y = minimum(t -> t[2], es)
    bottomright_x = maximum(t -> t[1] + t[3], es)
    bottomright_y = maximum(t -> t[2] + t[4], es)
    return (topleft_x, topleft_y, bottomright_x, bottomright_y)
end

# ------------------------------------

mutable struct RLine <: Shape
    from
    to
    color
    canvas
end

function RLine(from::Shape, to::Shape; color=RColor_BLUE)
    a_line = RLine(from, to, color, nothing)
    push!(from.outgoing_edges, a_line)
    push!(to.incoming_edges, a_line)
    return a_line
end

function compute_encompassing_rectangle(line::RLine)
    return (0, 0, 0, 0)
end

# ------------------------------------

mutable struct RText <: BoundedShape
    value::String
    color
    x
    y
    width
    height
    canvas
end

function RText(value::String; color=RColor_BLUE)
    return RText(value, color, 0, 0, 0, 0, nothing)
end

# ------------------------------------
"""
Color
"""
mutable struct RColor
    r
    g
    b
end
RColor() = RColor(0.8, 0.8, 0.8)

RColor_BLUE = RColor(0, 0, 1)
RColor_GREEN = RColor(0, 1, 0)
RColor_RED = RColor(1, 0, 0)

random_color()=RColor(rand(), rand(), rand())

# ------------------------------------
"""
Canvas
"""
mutable struct RCanvas
    shapes::Array{Shape}
    callbacks
    shapeBeingPointed
    offset_X::Number
    offset_Y::Number
    host_window         # type of GtkCanvas
    animations::Vector
    window_title::String
end
RCanvas() = RCanvas("Roassal")
RCanvas(window_title::String) = RCanvas([], [], RBox(), 0, 0, nothing, [], window_title)

number_of_shapes(c::RCanvas) = length(c.shapes)

function add!(c::RCanvas, s::T) where T <: Shape
    push!(c.shapes, s)
    s.canvas = c
    return c
end

# Base.show(io::IO, c::RCanvas) = Base.show(io, MIME"text/plain", c)

function Base.show(io::IO, c::RCanvas)
    print(io, "RCanvas{ $(number_of_shapes(c)) shapes }")
end

get_shapes(c::RCanvas) = c.shapes
get_nodes(c::RCanvas) = filter(s -> !(s isa RLine), get_shapes(c))
get_edges(c::RCanvas) = filter(s -> s isa RLine, get_shapes(c))

function get_shape(c::RCanvas, model::Any)
    for s in c.shapes
        if s.model == model
            return s
        end
    end
    return nothing
end

function redraw(canvas::RCanvas, c::GtkCanvas)
    @guarded draw(c) do widget
        h = height(c)
        w = width(c)
        ctx = getgc(c)
        rectangle(ctx, 0, 0, w, h)
        set_source_rgb(ctx, 0.2, 0.2, 0.2)
        fill(ctx)

        rendererVisitor(canvas, c)
    end
end

function translate_to!(canvas::RCanvas, new_position::Tuple{Number,Number})
    return translate_to!(canvas, new_position[1], new_position[2])
end

function translate_to!(canvas::RCanvas, new_X::Number, new_Y::Number)
    canvas.offset_X = new_X
    canvas.offset_Y = new_Y
    return canvas
end

function translate_by!(canvas::RCanvas, delta::Tuple{Number,Number})
    return translate_by!(canvas, delta[1], delta[2])
end

function translate_by!(canvas::RCanvas, delta_X::Number, delta_Y::Number)
    canvas.offset_X = canvas.offset_X + delta_X
    canvas.offset_Y = canvas.offset_Y + delta_Y
    return canvas
end

function push_lines_back(c::RCanvas)
    # This is a workaround to ensure that lines are drawn on top of boxes
    # and circles, which are added after the lines.
    all_lines = filter(s -> s isa RLine, c.shapes)
    all_shapes = filter(s -> !(s isa RLine), c.shapes)
    c.shapes = all_lines
    append!(c.shapes, all_shapes)
end

global previous_win = nothing

function rshow(
    canvas::RCanvas
    ;
    center::Bool = true,
    resize::Bool=true,
    max_window_size::Tuple{Number, Number}=(800, 600),
    min_window_size::Tuple{Number, Number}=(200, 200),
)
    c = @GtkCanvas()
    !isnothing(previous_win) && destroy(previous_win)

    # We keep a reference to allow for refresh and animations
    canvas.host_window = c

    win = GtkWindow(c, canvas.window_title)
    global previous_win = win
    redraw(canvas, c)

    center && center!(canvas, resize)
    if resize
        es = compute_encompassing_rectangle(get_shapes(canvas))
        new_width = max(min(es[3] + 10, max_window_size[1]), min_window_size[1])
        new_height = max(min(es[4] + 10, max_window_size[2]), min_window_size[2])
        resize!(win, round(Int, new_width), round(Int, new_height))
    end

    signal_connect(win, "key-press-event") do widget, event
        #println("You pressed key ", event.keyval)
        step = 20
        big_step = step * 5
        event.keyval == 65361 && translate_by!(canvas, step, 0)
        event.keyval == 65363 && translate_by!(canvas, -step, 0)
        event.keyval == 65364 && translate_by!(canvas, 0, -step)
        event.keyval == 65362 && translate_by!(canvas, 0, step)

        event.keyval == 97 && translate_by!(canvas, big_step, 0)
        event.keyval == 100 && translate_by!(canvas, -big_step, 0)
        event.keyval == 119 && translate_by!(canvas, 0, -big_step)
        event.keyval == 115 && translate_by!(canvas, 0, big_step)
        redraw(canvas, c)
    end

    c.mouse.motion = @guarded (widget, event) -> begin
        offset = offsetFromScreenToCanvas(c)
        shape_or_canvas_under_mouse = get_shape_at_position(canvas, event.x + offset[1], event.y + offset[2])
        #println("($(event.x), $(event.y)) -> $(typeof(shape_or_canvas_under_mouse))")
        trigger_callback(shape_or_canvas_under_mouse, :mouseMove, event)

        # Emit the enter / leave event
        if (canvas.shapeBeingPointed !== shape_or_canvas_under_mouse)
            #println("CHANGE SHAPE/CANVAS\n")
            trigger_callback(canvas.shapeBeingPointed, :mouseLeave, event)
            canvas.shapeBeingPointed = shape_or_canvas_under_mouse
            trigger_callback(shape_or_canvas_under_mouse, :mouseEnter, event)
        end

        #Probably trigger_callback should indicates whether there has been some trigger.
        redraw(canvas, c)
        reveal(widget)
        #println("refresh!!")
    end

    c.mouse.button1press = @guarded (widget, event) -> begin
        # ctx = getgc(widget)
        # set_source_rgb(ctx, 0, 1, 0)
        # arc(ctx, event.x, event.y, 5, 0, 2pi)
        # stroke(ctx)
        #reveal(widget)
        offset = offsetFromScreenToCanvas(c)
        shape_or_canvas_under_mouse = get_shape_at_position(canvas, event.x + offset[1], event.y + offset[2])
        trigger_callback(shape_or_canvas_under_mouse, :mouseClick, event)

        #Probably trigger_callback should indicates whether there has been some trigger.
        redraw(canvas, c)
        reveal(widget)
        #println("refresh!!")
    end

    show(c)

    if !isempty(canvas.animations)
        @async begin
            while !isempty(canvas.animations)
                for a in canvas.animations
                    if (now() - a.start_time).value / 1000 > a.duration
                        a.is_running = false
                    else
                        a.callback(a)
                    end

                end
                refresh(canvas)
                sleep(0.001)  # Avoid busy waiting
                canvas.animations = filter(a -> a.is_running, canvas.animations)
            end
        end
    end
end

function center!(canvas::RCanvas, resize::Bool=true)
    e = compute_encompassing_rectangle(get_shapes(canvas))
    translate_to!(canvas, -(e[1] + e[3])/2, -(e[2] + e[4])/2)
    return canvas
end

# Refresh the Roassal canvas, useful for animations
function refresh(canvas::RCanvas)
    isnothing(canvas.host_window) || redraw(canvas, canvas.host_window)
end

function get_shape_at_position(canvas::RCanvas, x::Number, y::Number)
    for shape in canvas.shapes
        c = compute_encompassing_rectangle(shape)
        if c[1] <= x && c[2] <= y && (c[3] + c[1]) > x && (c[4] + c[2]) > y
            return shape
        end
    end
    return canvas
end

function remove_shape!(canvas::RCanvas, shape::Shape)
    deleteat!(canvas.shapes, findall(s -> s == shape, canvas.shapes))
end
# ------------------------------------
"""
Rendering using a visitor
"""
function rendererVisitor(canvas::RCanvas, gtk::GtkCanvas=GtkCanvas())
    for shape in canvas.shapes
        rendererVisitor(shape, gtk, canvas.offset_X, canvas.offset_Y)
    end
end

function rendererVisitor(box::RBox, gtk::GtkCanvas=GtkCanvas(), offset_x::Number=0, offset_y::Number=0)
    ctx = getgc(gtk)
    encompassingRectangle = compute_encompassing_rectangle(box)
    _offsetFromCameraToScreen = offset_from_canvas_to_screen(gtk)
    rectangle(ctx,
                encompassingRectangle[1] + _offsetFromCameraToScreen[1] + offset_x,
                encompassingRectangle[2] + _offsetFromCameraToScreen[2] + offset_y,
                encompassingRectangle[3],
                encompassingRectangle[4])
    color = box.color
    set_source_rgb(ctx, color.r, color.g, color.b)
    fill(ctx)
end

function rendererVisitor(circle::RCircle, gtk::GtkCanvas=GtkCanvas(), offset_x::Number=0, offset_y::Number=0)
    ctx = getgc(gtk)
    _offsetFromCameraToScreen = offset_from_canvas_to_screen(gtk)

    arc(ctx,
        circle.x + _offsetFromCameraToScreen[1] + offset_x,
        circle.y + _offsetFromCameraToScreen[2] + offset_y,
        circle.width / 2,
        0,
        2pi)
    color = circle.color
    set_source_rgb(ctx, color.r, color.g, color.b)
    fill(ctx)
end

function rendererVisitor(text::RText, gtk::GtkCanvas=GtkCanvas(), offset_x::Number=0, offset_y::Number=0)
    ctx = getgc(gtk)
    _offsetFromCameraToScreen = offset_from_canvas_to_screen(gtk)
    label = GtkLabel("Hello")
    push!(gtk, label)
end

function rendererVisitor(line::RLine, gtk::GtkCanvas=GtkCanvas(), offset_x::Number=0, offset_y::Number=0)
    ctx = getgc(gtk)

    color = line.color
    set_source_rgb(ctx, color.r, color.g, color.b)

    _offsetFromCameraToScreen = offset_from_canvas_to_screen(gtk)
    from_position = pos(line.from) .+ _offsetFromCameraToScreen .+ (offset_x, offset_y)
    to_position = pos(line.to) .+ _offsetFromCameraToScreen .+ (offset_x, offset_y)
    move_to(ctx, from_position...)
    line_to(ctx, to_position...)
    set_line_width(ctx, 2.0)
    stroke(ctx)

    # println("DEBUG: $color $from_position $to_position")

#=     fill(ctx)
    paint(cr)
 =##=
    rectangle(ctx,
                encompassingRectangle[1] + _offsetFromCameraToScreen[1],
                encompassingRectangle[2] + _offsetFromCameraToScreen[2],
                encompassingRectangle[3],
                encompassingRectangle[4])
    color = box.color
    set_source_rgb(ctx, color.r, color.g, color.b)
    fill(ctx) =#
end

function offset_from_canvas_to_screen(gtk::GtkCanvas)
    return (width(gtk) / 2, height(gtk) / 2)
end

function offsetFromScreenToCanvas(gtk::GtkCanvas)
    return offset_from_canvas_to_screen(gtk) .* -1
end

# ------------------------------------
"""
Callbacks
"""
mutable struct Callback
    name::Symbol
    f::Function
end

function add_callback!(shape_or_canvas_under_mouse, callback::Callback)
    push!(shape_or_canvas_under_mouse.callbacks, callback)
end

function add_callback!(anArray::Array{Shape}, callback::Callback)
    for aShape in anArray
        add_callback!(aShape, callback::Callback)
    end
end

function numberOfCallbacks(shape_or_canvas_under_mouse)
    return length(shape_or_canvas_under_mouse.callbacks)
end

function trigger_callback(shape_or_canvas_under_mouse, name::Symbol, event=nothing)
    # Can be better written
    for c in shape_or_canvas_under_mouse.callbacks
        if (c.name == name)
            #c.f(event, shape_or_canvas_under_mouse)
            c.f()
        end
    end
end

include("layouts.jl")
include("interactions.jl")

end
