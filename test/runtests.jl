using Roassal
using Test
# ------------------------------------
function testColor()
    aColor = RColor()
    @test aColor.r == aColor.g
    @test aColor.r == aColor.b 
end

function testBox01() 
    aColor = RColor()
    box1 = RBox(color=aColor)
    @test box1.color == aColor
    @test pos(box1) == (0,0)
    @test extent(box1) == (10,10)
    @test computeEncompassingRectangle(box1) == (-5, -5, 10, 10)

    c = getColor(box1)
    @test c === aColor
    anotherColor = RColor(1.0, 1.0, 0.5)
    setColor!(box1, anotherColor)
    @test getColor(box1) === anotherColor
end

function testBox02() 
    box = RBox()
    @test box.x == 0
    @test box.color != RColor()
end

function testCanvas() 
    box1 = RBox(color=RColor(0.4, 0.1, 0.3))
    box = RBox()
    canvas = RCanvas()
    @test numberOfShapes(canvas) == 0
    add!(canvas, box1)
    @test numberOfShapes(canvas) == 1
    add!(canvas, box)
    @test numberOfShapes(canvas) == 2
end

function testCanvas02()
    canvas = RCanvas()
    @test isempty(shapesOf(canvas))
    box1 = RBox
    box2 = RBox
    add!(canvas, box1)
    add!(canvas, box2)
    @test length(shapeOf(canvas)) == 2
    @test shapesOf(canvas)[1] === box1
    @test shapesOf(canvas)[2] === box2
end

function testRemovingShape()
    canvas = RCanvas()
    box1 = RBox()
    box2 = RBox()
    box3 = RBox()
    add!(canvas, box1)
    add!(canvas, box2)
    add!(canvas, box3)

    removeShape!(canvas, box2)
    @test numberOfShapes(canvas) == 2
    @test shapesOf(canvas)[1] === box1
    @test shapesOf(canvas)[2] === box3

    removeShape!(canvas, box1)
    @test numberOfShapes(canvas) == 1
    @test shapesOf(canvas)[1] === box3

    # Not in the canvas!
    removeShape!(canvas, box1)
    @test numberOfShapes(canvas) == 1
    @test shapesOf(canvas)[1] === box3

    removeShape!(canvas, box3)
end

# ------------------------------------
function testFetchingShape()
    canvas = RCanvas()
    box = RBox()
    add!(canvas, box)
    translateTo!(box, 50, 50)
    @test pos(box) == (50, 50)

    #@test isPositionWithinEncompassingRectangleOf(box, 50, 50)
    #@test !isPositionWithinEncompassingRectangleOf(box, -50, 50)
    #@test !isPositionWithinEncompassingRectangleOf(box, -50, -50)

    @test getShapeAtPosition(canvas, 50, 50) === box
    @test getShapeAtPosition(canvas, 50, 50) == box
    @test getShapeAtPosition(canvas, -50, -50) == canvas
    @test getShapeAtPosition(canvas, -50, -50) === canvas
end

# ------------------------------------
function testCallbacks01()
    box = RBox()
    @test numberOfCallbacks(box) == 0
    addCallback!(box, Callback(:mouseMove, (event, shape) -> println("enter box")))
    @test numberOfCallbacks(box) == 1
end

function testCallbacks02()
    box = RBox()
    a = 0

    # Does not do much since there is no callback
    triggerCallback(box, :mouseMove, "not an event")
    triggerCallback(box, :mouseMove, "not an event")

    addCallback!(box, Callback(:mouseMove, (event, shape) -> a = a + 1))
    @test numberOfCallbacks(box) == 1
    @test a == 0
    triggerCallback(box, :mouseMove, "not an event")
    @test a == 1
    triggerCallback(box, :mouseMove, "not an event")
    @test a == 2

    triggerCallback(box, :mouseMove, "not an event2")
    @test a == 3

    triggerCallback(box, :mouseMoveNot, "not an event")
    @test a == 3
end

function testCallbacks03()
    canvas = RCanvas()
    @test numberOfCallbacks(canvas) == 0
    a = 0
    
    # Does not do much since there is no callback
    triggerCallback(canvas, :mouseMove, "not an event")
    triggerCallback(canvas, :mouseMove, "not an event")

    addCallback!(canvas, Callback(:mouseMove, (event, shape) -> a = a + 1))
    @test numberOfCallbacks(canvas) == 1
    @test a == 0
    triggerCallback(canvas, :mouseMove, "not an event")
    @test a == 1
    triggerCallback(canvas, :mouseMove, "not an event")
    @test a == 2

    triggerCallback(canvas, :mouseMove, "not an event2")
    @test a == 3

    triggerCallback(canvas, :mouseMoveNot, "not an event")
    @test a == 3
end

function testCallbacks04()
    canvas = RCanvas()
    t = nothing
    addCallback!(canvas, Callback(:mouseMove, (event, shape) -> t = (event, shape)))
    @test isnothing(t)
    @test numberOfCallbacks(canvas) == 1

    triggerCallback(canvas, :mouseMove, "not an event")
    @test length(t) == 2
    @test t[1] == "not an event"
    @test t[2] == canvas
end

function testCallback05() 
    canvas = RCanvas()
    box1 = RBox()
    box2 = RBox()
    add!(canvas, box1)
    add!(canvas, box2)
    addCallback!(shapesOf(canvas), Callback(:mouseMove, (event, shape) -> 42))
    @test numberOfCallbacks(box1) == 1
    @test numberOfCallbacks(box2) == 1

    addCallback!(shapesOf(canvas)[1], Callback(:mouseMove, (event, shape) -> 42))
    @test numberOfCallbacks(box1) == 2
    @test numberOfCallbacks(box2) == 1

    addCallback!(shapesOf(canvas), Callback(:mouseMove, (event, shape) -> 42))
    @test numberOfCallbacks(box1) == 3
    @test numberOfCallbacks(box2) == 2
end

function testOffsetFromAndToScreen()
    gtk = GtkCanvas()
    @test offsetFromCanvasToScreen(gtk) != (0, 0)
    @test offsetFromScreenToCanvas(gtk) != (0, 0)
    @test (offsetFromCanvasToScreen(gtk) + offsetFromScreenToCanvas(gtk)) == (0, 0)
end

# ------------------------------------
@testset "Roassal.jl" begin
    testColor()
    testBox01()
    testBox02()
    testCanvas()
    testFetchingShape()
    testCallbacks01()
    testCallbacks02()
    testCallbacks04()
end
