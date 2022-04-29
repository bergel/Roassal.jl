module Roassal

# ------------------------------------
# Graphic
using Gtk, Graphics
# ------------------------------------
# Modeling
export Shape
export pos, extent, compute_encompassing_rectangle
export translate_to!, extent!

export RBox, getColor, setColor!

export RColor

export RCanvas
export number_of_shapes, add!, remove_shape!, rshow
export rendererVisitor
export get_shape_at_position
export offset_from_canvas_to_screen, offsetFromScreenToCanvas
export get_shapes

export Callback
export numberOfCallbacks, add_callback!, triggerCallback

export riHighlightable

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
end
RBox(;color=RColor(), x=0, y=0, width=10, height=10) = RBox(color, x, y, width, height, [])

pos(s::BoundedShape) = (s.x, s.y)
extent(s::BoundedShape) = (s.width, s.height)

function setColor!(s, color)
    s.color = color
end

function getColor(s::Shape)
    return s.color
end

function extent!(s::BoundedShape, width, height)
    s.width = width
    s.height = height
end

function translate_to!(s::BoundedShape, x, y)
    s.x = x
    s.y = y
end

# Return (x, y, w, h)
function compute_encompassing_rectangle(s::BoundedShape)
    x = s.x - (s.width / 2)
    y = s.y - (s.height / 2)
    return (x, y, s.width, s.height)
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

# ------------------------------------
"""
Canvas
"""
mutable struct RCanvas
    shapes::Array{Shape}
    callbacks
    shapeBeingPointed
end
RCanvas() = RCanvas([], [], RBox())

number_of_shapes(c::RCanvas) = length(c.shapes)
add!(c::RCanvas, s::Shape) = push!(c.shapes, s)
get_shapes(c::RCanvas) = c.shapes

function TODELETEshow(canvas::RCanvas)
    c = @GtkCanvas()
    win = GtkWindow(c, "Roassal")
    @guarded draw(c) do widget
        ctx = getgc(c)
        h = height(c)
        w = width(c)
        # Paint red rectangle
        rectangle(ctx, 0, 0, w, h / 2)
        set_source_rgb(ctx, 1, 0, 0)
        fill(ctx)
        # Paint blue rectangle
        rectangle(ctx, 0, 3h / 4, w, h / 4)
        set_source_rgb(ctx, 0, 0, 1)
        fill(ctx)
    end
    show(c)
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

function rshow(canvas::RCanvas)
    c = @GtkCanvas()
    win = GtkWindow(c, "Roassal")
    redraw(canvas, c)

    signal_connect(win, "key-press-event") do widget, event
        println("You pressed key ", event.keyval)
    end

    c.mouse.motion = @guarded (widget, event) -> begin
        offset = offsetFromScreenToCanvas(c)
        shapeOrCanvas = get_shape_at_position(canvas, event.x + offset[1], event.y + offset[2])
        #print("($(event.x), $(event.y)) -> ")
        #println(typeof(shapeOrCanvas))
        triggerCallback(shapeOrCanvas, :mouseMove, event)

        # Emit the enter / leave event
        if (canvas.shapeBeingPointed !== shapeOrCanvas)
            triggerCallback(shapeOrCanvas, :mouseLeave, event)
            canvas.shapeBeingPointed = shapeOrCanvas
            triggerCallback(shapeOrCanvas, :mouseEnter, event)
        end

        #Probably triggerCallback should indicates whether there has been some trigger.
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
        shapeOrCanvas = get_shape_at_position(canvas, event.x + offset[1], event.y + offset[2])
        triggerCallback(shapeOrCanvas, :mouseClick, event)

        #Probably triggerCallback should indicates whether there has been some trigger.
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
        rendererVisitor(shape, gtk)
    end
end

function rendererVisitor(box::RBox, gtk::GtkCanvas=GtkCanvas())
    ctx = getgc(gtk)
    encompassingRectangle = compute_encompassing_rectangle(box)
    _offsetFromCameraToScreen = offset_from_canvas_to_screen(gtk)
    rectangle(ctx,
                encompassingRectangle[1] + _offsetFromCameraToScreen[1],
                encompassingRectangle[2] + _offsetFromCameraToScreen[2],
                encompassingRectangle[3],
                encompassingRectangle[4])
    color = box.color
    set_source_rgb(ctx, color.r, color.g, color.b)
    fill(ctx)
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
    f
end

function add_callback!(shapeOrCanvas, callback::Callback)
    push!(shapeOrCanvas.callbacks, callback)
end

function add_callback!(anArray::Array{Shape}, callback::Callback)
    for aShape in anArray
        add_callback!(aShape, callback::Callback)
    end
end

function numberOfCallbacks(shapeOrCanvas)
    return length(shapeOrCanvas.callbacks)
end

function triggerCallback(shapeOrCanvas, name::Symbol, event)
    for c in shapeOrCanvas.callbacks
        if (c.name == name)
            c.f(event, shapeOrCanvas)
        end
    end
end

# ------------------------------------
# Interactions

function riHighlightable(shape::Shape)
    oldColor = nothing
    function recordOld(s)
        oldColor = getColor(s)
        setColor!(s, RColor(0, 0, 1.0))
        print("Recorded!")
        println(oldColor)
    end
    function giveOldColor(s)
        println("mouse leave!")
        setColor!(s, oldColor)
    end

    add_callback!(shape, Callback(:mouseEnter, (event, s) -> recordOld(s)))
    add_callback!(shape, Callback(:mouseLeave, (event, s) -> giveOldColor(s)))
    return shape
end

# ------------------------------------


end
