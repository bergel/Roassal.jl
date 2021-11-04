module Roassal

# ------------------------------------
# Graphic 
using Gtk, Graphics
# ------------------------------------
# Modelling
export Shape
export pos, extent, computeEncompassingRectangle
export translateTo!, extent!

export RBox, getColor, setColor!

export RColor

export RCanvas
export numberOfShapes, add!, removeShape!, rshow
export rendererVisitor
export getShapeAtPosition
export offsetFromCanvasToScreen, offsetFromScreenToCanvas
export shapesOf

export Callback
export numberOfCallbacks, addCallback!, triggerCallback

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

function translateTo!(s::BoundedShape, x, y) 
    s.x = x
    s.y = y
end

# Return (x, y, w, h)
function computeEncompassingRectangle(s::BoundedShape)
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

numberOfShapes(c::RCanvas) = length(c.shapes)
add!(c::RCanvas, s::Shape) = push!(c.shapes, s)
shapesOf(c::RCanvas) = c.shapes

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
        shapeOrCanvas = getShapeAtPosition(canvas, event.x + offset[1], event.y + offset[2])
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
        shapeOrCanvas = getShapeAtPosition(canvas, event.x + offset[1], event.y + offset[2])
        triggerCallback(shapeOrCanvas, :mouseClick, event)

        #Probably triggerCallback should indicates whether there has been some trigger.
        redraw(canvas, c)
        reveal(widget)
        #println("refresh!!")
    end

    show(c)
end

function getShapeAtPosition(canvas::RCanvas, x::Number, y::Number)
    for shape in canvas.shapes
        c = computeEncompassingRectangle(shape)
        if c[1] <= x && c[2] <= y && (c[3] + c[1]) > x && (c[4] + c[2]) > y
            return shape
        end
    end
    return canvas
end

function removeShape!(canvas::RCanvas, shape::Shape)
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
    encompassingRectangle = computeEncompassingRectangle(box)
    _offsetFromCameraToScreen = offsetFromCanvasToScreen(gtk)
    rectangle(ctx, 
                encompassingRectangle[1] + _offsetFromCameraToScreen[1], 
                encompassingRectangle[2] + _offsetFromCameraToScreen[2], 
                encompassingRectangle[3], 
                encompassingRectangle[4])
    color = box.color
    set_source_rgb(ctx, color.r, color.g, color.b)
    fill(ctx)
end

function offsetFromCanvasToScreen(gtk::GtkCanvas)
    return (width(gtk) / 2, height(gtk) / 2)
end

function offsetFromScreenToCanvas(gtk::GtkCanvas)
    return offsetFromCanvasToScreen(gtk) .* -1
end

# ------------------------------------
"""
Callbacks
"""
mutable struct Callback
    name::Symbol
    f
end

function addCallback!(shapeOrCanvas, callback::Callback)
    push!(shapeOrCanvas.callbacks, callback)
end

function addCallback!(anArray::Array{Shape}, callback::Callback)
    for aShape in anArray
        addCallback!(aShape, callback::Callback)
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

    addCallback!(shape, Callback(:mouseEnter, (event, s) -> recordOld(s)))
    addCallback!(shape, Callback(:mouseLeave, (event, s) -> giveOldColor(s)))
    return shape
end

# ------------------------------------


end
