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

export Callback
export numberOfCallbacks, add_callback!, trigger_callback

export highlightable
export popup

# ------------------------------------
"""
Shape definitions
"""
abstract type Shape end
abstract type BoundedShape <: Shape end
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
end

function RBox(;color=RColor(),
        x=0, y=0,
        width=10, height=10, size::Int64=0)

    size > 0 && return RBox(color, x, y, size, size, [], nothing, [], [])
    return RBox(color, x, y, width, height, [], nothing, [], [])
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
end
RCircle(;color=RColor(),
        x=0, y=0,
        width=10, height=10) = RCircle(color, x, y, width, height, [], nothing, [], [])

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
end

function translate_to!(s::BoundedShape, p::Tuple{Number, Number})
    translate_to!(s, p[1], p[2])
end

function translate_to!(s::BoundedShape, x::Number, y::Number)
    s.x = x
    s.y = y
end

function translate_topleft_to!(s::BoundedShape, p::Tuple{Number, Number})
    translate_topleft_to!(s, p[1], p[2])
end

function translate_topleft_to!(s::BoundedShape, x::Number, y::Number)
    s.x = x + s.width / 2
    s.y = y + s.height / 2
end

function translate_by!(s::BoundedShape, p::Tuple{Number, Number})
    translate_by!(s, p[1], p[2])
end

function translate_by!(s::BoundedShape, dx::Number, dy::Number)
    s.x = s.x + dx
    s.y = s.y + dy
end

# Return (x, y, w, h)
function compute_encompassing_rectangle(s::BoundedShape)
    x = s.x - (s.width / 2)
    y = s.y - (s.height / 2)
    return (x, y, s.width, s.height)
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

# ------------------------------------
"""
Canvas
"""
mutable struct RCanvas
    shapes::Array{Shape}
    callbacks
    shapeBeingPointed
    offset_X::Int64
    offset_Y::Int64
end
RCanvas() = RCanvas([], [], RBox(), 0, 0)

number_of_shapes(c::RCanvas) = length(c.shapes)

function add!(c::RCanvas, s::T) where T <: Shape
    push!(c.shapes, s)
    s.canvas = c
end

get_shapes(c::RCanvas) = c.shapes
get_nodes(c::RCanvas) = filter(s -> !(s isa RLine), get_shapes(c))
get_edges(c::RCanvas) = filter(s -> s isa RLine, get_shapes(c))


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

function translate_to!(canvas::RCanvas, new_position::Tuple{Int64,Int64})
    translate_to!(canvas, new_position[1], new_position[2])
end

function translate_to!(canvas::RCanvas, new_X::Int64, new_Y::Int64)
    canvas.offset_X = new_X
    canvas.offset_Y = new_Y
end

function translate_by!(canvas::RCanvas, delta::Tuple{Int64,Int64})
    translate_by!(canvas, delta[1], delta[2])
end

function translate_by!(canvas::RCanvas, delta_X::Int64, delta_Y::Int64)
    canvas.offset_X = canvas.offset_X + delta_X
    canvas.offset_Y = canvas.offset_Y + delta_Y
end

global previous_win = nothing

function rshow(canvas::RCanvas)
    c = @GtkCanvas()
    !isnothing(previous_win) && destroy(previous_win)

    win = GtkWindow(c, "Roassal")
    global previous_win = win
    redraw(canvas, c)

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

function rendererVisitor(box::RBox, gtk::GtkCanvas=GtkCanvas(), offset_x::Int64=0, offset_y::Int64=0)
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

function rendererVisitor(circle::RCircle, gtk::GtkCanvas=GtkCanvas(), offset_x::Int64=0, offset_y::Int64=0)
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

function rendererVisitor(text::RText, gtk::GtkCanvas=GtkCanvas(), offset_x::Int64=0, offset_y::Int64=0)
    ctx = getgc(gtk)
    _offsetFromCameraToScreen = offset_from_canvas_to_screen(gtk)
    label = GtkLabel("Hello")
    push!(gtk, label)
end

function rendererVisitor(line::RLine, gtk::GtkCanvas=GtkCanvas(), offset_x::Int64=0, offset_y::Int64=0)
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

    println("DEBUG: $color $from_position $to_position")

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

# ------------------------------------
# Interactions
function highlightable(canvas::RCanvas)
    foreach(shape -> highlightable(shape), get_shapes(canvas))
end

function highlightable(shapes::Vector{Shape})
    foreach(shape -> highlightable(shape), shapes)
end
#=
function highlightable(shape::Shape)
    oldColor = nothing
    function recordOld()
        oldColor = get_color(s)
        set_color!(shape, RColor_BLUE)
        print("Recorded!")
        println(oldColor)
    end
    function giveOldColor()
        println("mouse leave!")
        set_color!(shape, oldColor)
    end

    #add_callback!(shape, Callback(:mouseEnter, (event, s) -> recordOld(s)))
    #add_callback!(shape, Callback(:mouseLeave, (event, s) -> giveOldColor(s)))
    add_callback!(shape, Callback(:mouseEnter, recordOld))
    add_callback!(shape, Callback(:mouseLeave, giveOldColor))
    return shape
end =#

highlighted_shapes = Dict{Shape,RColor}()
function highlightable(shape::Shape)
    function recordColor()
        global highlighted_shapes[shape] = get_color(shape)
        #print("Recorded! $shape \n")
        set_color!(shape, RColor_BLUE)
    end
    function restoreColor()
        #println("mouse leave! $(haskey(highlighted_shapes, shape))\n")
        if(haskey(highlighted_shapes, shape))
            set_color!(shape, highlighted_shapes[shape])
            delete!(highlighted_shapes, shape)
        end
    end

    add_callback!(shape, Callback(:mouseEnter, recordColor))
    add_callback!(shape, Callback(:mouseLeave, restoreColor))
    return shape
end

function reset_highlight()
    global highlighted_shapes = Dict{Shape,RColor}()
end

# ------------------------------------
last_popup = nothing
function popup(shape::Shape)
    function addPopup()
        removePopup()
        global last_popup = RBox(width=40, height=15)
        add!(shape.canvas, last_popup)
        translate_to!(last_popup, pos(shape) .- (20, 20))
    end
    function removePopup()
        if(!isnothing(last_popup))
            remove_shape!(shape.canvas, last_popup)
            global last_popup = nothing
        end
    end

    add_callback!(shape, Callback(:mouseEnter, addPopup))
    add_callback!(shape, Callback(:mouseLeave, removePopup))
    return shape
end
# ------------------------------------


include("layouts.jl")


end
