module Roassal

# ------------------------------------
# Graphic
using Gtk, Graphics
using Cairo: Cairo, show_text, move_to, stroke, set_font_size, read_from_png, set_source_surface

# ------------------------------------
# Utility
using Dates: now

# ------------------------------------
# Modeling
export Shape
export pos, extent, compute_encompassing_rectangle
export pos_in_window
export translate_to!, translate_topleft_to!, extent!, translate_by!
export get_width, get_height
export shapes_nearby

export random_color

export RBox, get_color, set_color!
export RCircle, set_size!, bottom_center, top_center, is_intersecting

export RText

export RLine

export RImage

export RColor, RColor_BLUE, RColor_GREEN, RColor_RED

export RCanvas
export number_of_shapes, add!, remove_shape!, rshow, rclose
export rendererVisitor
export get_shape_at_position
export offset_from_canvas_to_screen, offsetFromScreenToCanvas
export get_shapes, get_nodes, get_edges
export center!, refresh, get_shape, push_lines_back
export visible_shapes

export Callback
export numberOfCallbacks, add_callback!, trigger_callback

export get_model

export highlightable
export popup

export Animation

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

# Return the position of the shape in the window. Top-left is (0,0)
pos_in_window(s::Shape) = round.(Int, (s.x + s.canvas.offset_X + s.canvas.width/2, s.y + s.canvas.offset_Y + s.canvas.height/2))

mutable struct RImage <: BoundedShape
    # color
    x
    y
    width
    height
    callbacks
    canvas
    outgoing_edges
    incoming_edges
    model

    image_cache
    filename::String
    scale_x::Float64
    scale_y::Float64
end

function RImage(filename::String; x=0, y=0, model=nothing, width=0, height=0, image_cache=nothing)
    isnothing(image_cache) && (image_cache = read_from_png(filename))
    real_width = round(Int, Cairo.width(image_cache))
    real_height = round(Int, Cairo.height(image_cache))

    if width == 0
        scale_x = 1.0
        width = real_width
    else
        scale_x = width / real_width
    end

    if height == 0
        scale_y = 1.0
        height = real_height
    else
        scale_y = height / real_height
    end

    return RImage(
        x,
        y,
        width,
        height,
        [],
        nothing,
        [],
        [],
        model,
        image_cache,
        filename,
        scale_x,
        scale_y
    )
end

# function RImage(filename::String; x=0, y=0, model=nothing, scale_x=0, scale_y=0, image_cache=nothing)
#     isnothing(image_cache) && (image_cache = read_from_png(filename))
#     width = round(Int, Cairo.width(image_cache))
#     height = round(Int, Cairo.height(image_cache))
#     scale_x == 0 && (scale_x = width)
#     scale_y == 0 && (scale_y = height)
#     return RImage(
#         x,
#         y,
#         width,
#         height,
#         [],
#         nothing,
#         [],
#         [],
#         model,
#         image_cache,
#         filename,
#         scale_x,
#         scale_y
#     )
# end

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
    color=:blue,
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

function bottom_center(s::BoundedShape)
    s = compute_encompassing_rectangle(s)
    return (s[1] + s[3] / 2, s[2] + s[4])
end

function top_center(s::BoundedShape)
    s = compute_encompassing_rectangle(s)
    return (s[1] + s[3] / 2, s[2])
end

function is_intersecting(s1::BoundedShape, s2::BoundedShape)
    # Check if two shapes intersect
    r1 = compute_encompassing_rectangle(s1)
    r2 = compute_encompassing_rectangle(s2)

    return is_intersecting(r1, r2)
end

# Each tuple is (x, y, w, h)
function is_intersecting(
    rect1::Tuple{Number, Number, Number, Number},
    rect2::Tuple{Number, Number, Number, Number}
)
    # Check if two rectangles intersect
    return !(rect1[1] + rect1[3] < rect2[1] ||  # rect1 is left of rect2
             rect1[1] > rect2[1] + rect2[3] ||  # rect1 is right of rect2
             rect1[2] + rect1[4] < rect2[2] ||  # rect1 is above rect2
             rect1[2] > rect2[2] + rect2[4])    # rect1 is below rect2
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

    value::String
    font_size::Int64
end

function RText(value::String; color=RColor_WHITE, font_size::Int64=12)
    return RText(color, 0, 0, 0, 0, [], nothing, [], [], nothing, value, font_size)
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
RColor_WHITE = RColor(1, 1, 1)
RColor_GRAY = RColor(0.8, 0.8, 0.8)

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
    width::Int  # Given by the size of the window
    height::Int # Given by the size of the window
end
RCanvas() = RCanvas("Roassal")
RCanvas(window_title::String) = RCanvas([], [], RBox(), 0, 0, nothing, [], window_title, 0, 0)

number_of_shapes(c::RCanvas) = length(c.shapes)

function add!(c::RCanvas, s::T) where T <: Shape
    push!(c.shapes, s)
    s.canvas = c
    return c
end

# Base.show(io::IO, c::RCanvas) = Base.show(io, MIME"text/plain", c)

function Base.show(io::IO, c::RCanvas)
    print(io, "RCanvas{ $(number_of_shapes(c)) shapes, offset:($(c.offset_X), $(c.offset_Y)), size:($(c.width), $(c.height))) }")
end

get_shapes(c::RCanvas) = Vector(c.shapes)
get_nodes(c::RCanvas) = filter(s -> !(s isa RLine), get_shapes(c))
get_edges(c::RCanvas) = filter(s -> s isa RLine, get_shapes(c))

# Return shapes bear by `shape` within `radius`
function shapes_nearby(shape::Shape, radius::Number=20)
    return shapes_nearby(shape.canvas, shape, radius)
end
function shapes_nearby(canvas::RCanvas, shape::Shape, radius::Number=20)
    result = Shape[]
    p = pos(shape)
    for s in canvas.shapes
        if s !== shape
            p2 = pos(s)
            dist = sqrt((p[1] - p2[1])^2 + (p[2] - p2[2])^2)
            if dist <= radius
                push!(result, s)
            end
        end
    end
    return result
end

function get_shape(c::RCanvas, model::Any)
    for s in c.shapes
        if s.model == model
            return s
        end
    end
    return nothing
end

# Return (x, y, w, h)
function compute_encompassing_rectangle(c::RCanvas)
    return (
            -c.offset_X - c.width/2,
            -c.offset_Y - c.height/2,
            c.width,
            c.height)
    # return (-c.offset_X - c.width/2, -c.offset_Y - c.height/2, c.width/2, c.height/2)
end

# Return the list of shapes visible in the canvas
function visible_shapes(c::RCanvas)
    return filter(s -> is_intersecting(c, s), c.shapes)
end

function is_intersecting(c::RCanvas, shape::Shape)
    return is_intersecting(
        compute_encompassing_rectangle(c),
        compute_encompassing_rectangle(shape)
    )
end

function is_intersecting(shape::Shape, c::RCanvas)
    return is_intersecting(
        compute_encompassing_rectangle(c),
        compute_encompassing_rectangle(shape)
    )
end

function redraw(canvas::RCanvas, c::GtkCanvas)
    @guarded draw(c) do widget
        h = height(c)
        w = width(c)
        ctx = getgc(c)
        save(ctx)
        rectangle(ctx, 0, 0, w, h)
        set_source_rgb(ctx, 0.2, 0.2, 0.2)
        fill(ctx)
        restore(ctx)

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

# Does not work unfortunately
function rclose(canvas::RCanvas)
    !isnothing(canvas.host_window) && destroy(canvas.host_window)
    canvas.host_window = nothing
end

function rshow(
    canvas::RCanvas
    ;
    center::Bool = true,
    resize::Bool=true,
    max_window_size::Tuple{Number, Number}=(800, 600),
    min_window_size::Tuple{Number, Number}=(200, 200),
    size::Tuple{Number, Number}=(0, 0),
)
    local c
    if size != (0, 0)
        c = @GtkCanvas(size[1], size[2])
    else
        c = @GtkCanvas()
    end
    !isnothing(previous_win) && destroy(previous_win)

    # We keep a reference to allow for refresh and animations
    canvas.host_window = c

    win = GtkWindow(c, canvas.window_title)
    global previous_win = win
    redraw(canvas, c)

    center && center!(canvas, resize)

    if size == (0, 0) && resize
        es = compute_encompassing_rectangle(get_shapes(canvas))
        new_width = max(min(es[3] + 10, max_window_size[1]), min_window_size[1])
        new_height = max(min(es[4] + 10, max_window_size[2]), min_window_size[2])
        resize!(win, round(Int, new_width), round(Int, new_height))
        canvas.width = round(Int, new_width)
        canvas.height = round(Int, new_height)
    end

    if size != (0, 0)
        canvas.width = size[1]
        canvas.height = size[2]
        resize!(win, size[1], size[2])
    end

    signal_connect(win, "size-allocate") do widget, allocation
        # Update the canvas size when the window is resized
        canvas.width = allocation.width
        canvas.height = allocation.height
        redraw(canvas, c)
    end

    signal_connect(win, "key-release-event") do widget, event
        try
            # println("You released key ", event.keyval)
            # offset = offsetFromScreenToCanvas(c)
            # shape_or_canvas_under_mouse = get_shape_at_position(canvas, event.x + offset[1], event.y + offset[2])
            trigger_callback(canvas, :keyRelease, event)
        catch e
            println("Error in key-released-event callback: $e")
            @error "Something went wrong1" exception=(e, catch_backtrace())

        end
    end

    signal_connect(win, "key-press-event") do widget, event
        try
            # println("You pressed key ", event.keyval)
            # offset = offsetFromScreenToCanvas(c)
            # shape_or_canvas_under_mouse = get_shape_at_position(canvas, event.x + offset[1], event.y + offset[2])
            trigger_callback(canvas, :keyPress, event)
            # step = 20
            # big_step = step * 5
            # event.keyval == 65361 && translate_by!(canvas, step, 0)
            # event.keyval == 65363 && translate_by!(canvas, -step, 0)
            # event.keyval == 65364 && translate_by!(canvas, 0, -step)
            # event.keyval == 65362 && translate_by!(canvas, 0, step)

            # event.keyval == 97 && translate_by!(canvas, big_step, 0)
            # event.keyval == 100 && translate_by!(canvas, -big_step, 0)
            # event.keyval == 119 && translate_by!(canvas, 0, -big_step)
            # event.keyval == 115 && translate_by!(canvas, 0, big_step)
            redraw(canvas, c)
        catch e
            println("Error in key-press-event callback: $e")
            @error "Something went wrong2" exception=(e, catch_backtrace())
        end
    end

    # When the window is closed
    signal_connect(win, "delete-event") do widget, event
        # Remove all animations when the window is closed
        for a in canvas.animations
            a.is_running = false
        end
        canvas.animations = []
        # Return FALSE to allow the default handler to proceed with window destruction
        return false
    end

    c.mouse.motion = @guarded (widget, event) -> begin
        try
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
        catch e
            println("Error in mouse motion callback: $e")
        end
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
                    a.is_running || continue
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
    # o = offset_from_canvas_to_screen(gtk)
    # er_canvas = compute_encompassing_rectangle(canvas)
    for shape in canvas.shapes
        # @info "Considering shape: $shape"

        # er = compute_encompassing_rectangle(shape)
        # er = (er[1] - o[1], er[2] - o[2], er[3], er[4])
        # er = (er[1] + o[1] + canvas.offset_X, er[2] + o[2] + canvas.offset_Y, er[3], er[4])
        # if is_intersecting(er, er_canvas)
        #     @info "Rendering shape: $shape"
            rendererVisitor(shape, gtk, canvas.offset_X, canvas.offset_Y)
        # end
    end
end

function rendererVisitor(box::RBox, gtk::GtkCanvas=GtkCanvas(), offset_x::Number=0, offset_y::Number=0)
    ctx = getgc(gtk)
    save(ctx)
    encompassingRectangle = compute_encompassing_rectangle(box)
    _offsetFromCameraToScreen = offset_from_canvas_to_screen(gtk)

    if encompassingRectangle[3] <= 0 || encompassingRectangle[4] <= 0
        return
    end

    if encompassingRectangle[1] + _offsetFromCameraToScreen[1] + offset_x > width(gtk) ||
       encompassingRectangle[1] + _offsetFromCameraToScreen[1] + offset_x + encompassingRectangle[3] < 0 ||

       encompassingRectangle[2] + _offsetFromCameraToScreen[2] + offset_y > height(gtk) ||
       encompassingRectangle[2] + _offsetFromCameraToScreen[2] + offset_y + encompassingRectangle[4] < 0
        return
    end

    rectangle(ctx,
                encompassingRectangle[1] + _offsetFromCameraToScreen[1] + offset_x,
                encompassingRectangle[2] + _offsetFromCameraToScreen[2] + offset_y,
                encompassingRectangle[3],
                encompassingRectangle[4])
    set_color(ctx, box.color)
    fill(ctx)
    restore(ctx)
    # println("DEBUG visiting box: $encompassingRectangle $offset_x $offset_y")
end

function set_color(ctx, color)
    if color isa Symbol
        color == :red && set_source_rgb(ctx, 1.0, 0.0, 0.0)
        color == :green && set_source_rgb(ctx, 0.0, 1.0, 0.0)
        color == :dark_green && set_source_rgb(ctx, 0.0, 0.5, 0.0)
        color == :blue && set_source_rgb(ctx, 0.0, 0.0, 1.0)
        color == :yellow && set_source_rgb(ctx, 1.0, 1.0, 0.0)
        color == :black && set_source_rgb(ctx, 0.0, 0.0, 0.0)
        color == :white && set_source_rgb(ctx, 1.0, 1.0, 1.0)
        color == :gray && set_source_rgb(ctx, 0.5, 0.5, 0.5)
        color == :purple && set_source_rgb(ctx, 0.9, 0.0, 0.9)
        color == :brown && set_source_rgb(ctx, 0.6, 0.3, 0.0)
    else
        set_source_rgb(ctx, color.r, color.g, color.b)
    end
end

function rendererVisitor(circle::RCircle, gtk::GtkCanvas=GtkCanvas(), offset_x::Number=0, offset_y::Number=0)
    ctx = getgc(gtk)
    save(ctx)
    _offsetFromCameraToScreen = offset_from_canvas_to_screen(gtk)

    # if encompassingRectangle[3] <= 0 || encompassingRectangle[4] <= 0
    #     return
    # end

    if circle.x + _offsetFromCameraToScreen[1] + offset_x > width(gtk) ||
       circle.x + _offsetFromCameraToScreen[1] + offset_x + circle.width < 0 ||

       circle.y + _offsetFromCameraToScreen[2] + offset_y > height(gtk) ||
       circle.y + _offsetFromCameraToScreen[2] + offset_y + circle.width < 0
        return
    end

    arc(ctx,
        circle.x + _offsetFromCameraToScreen[1] + offset_x,
        circle.y + _offsetFromCameraToScreen[2] + offset_y,
        circle.width / 2,
        0,
        2pi)
    set_color(ctx, circle.color)
    fill(ctx)
    restore(ctx)
end

function rendererVisitor(text::RText, gtk::GtkCanvas=GtkCanvas(), offset_x::Number=0, offset_y::Number=0)
    ctx = getgc(gtk)
    save(ctx)

    _offsetFromCameraToScreen = offset_from_canvas_to_screen(gtk)
    move_to(ctx,
        text.x + _offsetFromCameraToScreen[1] + offset_x,
        text.y + _offsetFromCameraToScreen[2] + offset_y)
    set_color(ctx, text.color)
    set_font_size(ctx, text.font_size)
    show_text(ctx, text.value)
    stroke(ctx);

    restore(ctx)
end

function rendererVisitor(image::RImage, gtk::GtkCanvas=GtkCanvas(), offset_x::Number=0, offset_y::Number=0)
    ctx = getgc(gtk)
    save(ctx)
    _offsetFromCameraToScreen = offset_from_canvas_to_screen(gtk)

    dx = image.x + _offsetFromCameraToScreen[1] + offset_x
    dy = image.y + _offsetFromCameraToScreen[2] + offset_y
    # move_to(ctx,
    #     image.x + _offsetFromCameraToScreen[1] + offset_x,
    #     image.y + _offsetFromCameraToScreen[2] + offset_y)
    # scale(ctx, image.scale_x/image.width, image.scale_y/image.height);
    translate(ctx, dx + -0.5*image.width, dy + -0.5*image.height);
    # scale(ctx, image.scale_x/image.width, image.scale_y/image.height);
    scale(ctx, image.scale_x, image.scale_y);

    # translate(ctx, dx , dy );

    set_source_surface(ctx, image.image_cache, 0, 0)
    paint(ctx)
    restore(ctx)

end

function rendererVisitor(line::RLine, gtk::GtkCanvas=GtkCanvas(), offset_x::Number=0, offset_y::Number=0)
    ctx = getgc(gtk)
    save(ctx)
    set_color(ctx, line.color)

    _offsetFromCameraToScreen = offset_from_canvas_to_screen(gtk)
    from_position = pos(line.from) .+ _offsetFromCameraToScreen .+ (offset_x, offset_y)
    to_position = pos(line.to) .+ _offsetFromCameraToScreen .+ (offset_x, offset_y)
    move_to(ctx, from_position...)
    line_to(ctx, to_position...)
    set_line_width(ctx, 2.0)
    stroke(ctx)

    restore(ctx)
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
            c.f(event, shape_or_canvas_under_mouse)
            # c.f()
        end
    end
end

include("layouts.jl")
include("interactions.jl")

end
