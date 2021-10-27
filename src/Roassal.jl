module Roassal

# ------------------------------------
# Graphic 
using Gtk, Graphics
# ------------------------------------
# Modelling
export Shape
export pos, extent, computeEncompassingRectangle
export translateTo!, extent!

export RBox
export RColor

export RCanvas
export numberOfShapes, add!, rshow
export rendererVisitor



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
end
RBox(;color= RColor(), x=0, y=0, width=10, height=10) = RBox(color, x, y, width, height)

# ------------------------------------
"""
Operation on shapes
"""
pos(s::BoundedShape) = (s.x, s.y)
extent(s::BoundedShape) = (s.width, s.height)
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
end
RCanvas() = RCanvas([])

# ------------------------------------
"""
Operation on a canvas
"""
numberOfShapes(c::RCanvas) = length(c.shapes)
add!(c::RCanvas, s::Shape) = push!(c.shapes, s)

function TODELETEshow(canvas::RCanvas)
    c = @GtkCanvas()
    win = GtkWindow(c, "Roassal")
    @guarded draw(c) do widget
        ctx = getgc(c)
        h = height(c)
        w = width(c)
        # Paint red rectangle
        rectangle(ctx, 0, 0, w, h/2)
        set_source_rgb(ctx, 1, 0, 0)
        fill(ctx)
        # Paint blue rectangle
        rectangle(ctx, 0, 3h/4, w, h/4)
        set_source_rgb(ctx, 0, 0, 1)
        fill(ctx)
    end
    show(c)
end
function rshow(canvas::RCanvas)
    c = @GtkCanvas()
    win = GtkWindow(c, "Roassal")
    @guarded draw(c) do widget
        h = height(c)
        w = width(c)
        rendererVisitor(canvas, c)
    end
    show(c)
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
    offsetFromCameraToScreen = (width(gtk) / 2, height(gtk) / 2)
    # println("DEBUG1: " * string(encompassingRectangle))
    # println("DEBUG2: " * string(box))
    rectangle(ctx, 
                encompassingRectangle[1]+offsetFromCameraToScreen[1], 
                encompassingRectangle[2]+offsetFromCameraToScreen[2], 
                encompassingRectangle[3], 
                encompassingRectangle[4])
    color = box.color
    set_source_rgb(ctx, color.r, color.g, color.b)
    fill(ctx)
end
end
