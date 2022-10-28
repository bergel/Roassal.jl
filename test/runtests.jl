using Roassal
using Test
using Gtk
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
    @test compute_encompassing_rectangle(box1) == (-5, -5, 10, 10)

    c = get_color(box1)
    @test c === aColor
    anotherColor = RColor(1.0, 1.0, 0.5)
    set_color!(box1, anotherColor)
    @test get_color(box1) === anotherColor
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
    @test number_of_shapes(canvas) == 0
    add!(canvas, box1)
    @test number_of_shapes(canvas) == 1
    add!(canvas, box)
    @test number_of_shapes(canvas) == 2
end

function testCanvas02()
    canvas = RCanvas()
    @test isempty(get_shapes(canvas))
    box1 = RBox
    box2 = RBox
    add!(canvas, box1)
    add!(canvas, box2)
    @test length(shapeOf(canvas)) == 2
    @test get_shapes(canvas)[1] === box1
    @test get_shapes(canvas)[2] === box2
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
    @test number_of_shapes(canvas) == 2
    @test get_shapes(canvas)[1] === box1
    @test get_shapes(canvas)[2] === box3

    removeShape!(canvas, box1)
    @test number_of_shapes(canvas) == 1
    @test get_shapes(canvas)[1] === box3

    # Not in the canvas!
    removeShape!(canvas, box1)
    @test number_of_shapes(canvas) == 1
    @test get_shapes(canvas)[1] === box3

    removeShape!(canvas, box3)
end

# ------------------------------------
function testFetchingShape()
    canvas = RCanvas()
    box = RBox()
    add!(canvas, box)
    translate_to!(box, 50, 50)
    @test pos(box) == (50, 50)

    #@test isPositionWithinEncompassingRectangleOf(box, 50, 50)
    #@test !isPositionWithinEncompassingRectangleOf(box, -50, 50)
    #@test !isPositionWithinEncompassingRectangleOf(box, -50, -50)

    @test get_shape_at_position(canvas, 50, 50) === box
    @test get_shape_at_position(canvas, 50, 50) == box
    @test get_shape_at_position(canvas, -50, -50) == canvas
    @test get_shape_at_position(canvas, -50, -50) === canvas
end

# ------------------------------------
function testCallbacks01()
    box = RBox()
    @test numberOfCallbacks(box) == 0
    add_callback!(box, Callback(:mouseMove, (event, shape) -> println("enter box")))
    @test numberOfCallbacks(box) == 1
end

function testCallbacks02()
    box = RBox()
    a = 0

    # Does not do much since there is no callback
    trigger_callback(box, :mouseMove, "not an event")
    trigger_callback(box, :mouseMove, "not an event")

    add_callback!(box, Callback(:mouseMove, () -> a = a + 1))
    @test numberOfCallbacks(box) == 1
    @test a == 0
    trigger_callback(box, :mouseMove, "not an event")
    @test a == 1
    trigger_callback(box, :mouseMove, "not an event")
    @test a == 2

    trigger_callback(box, :mouseMove, "not an event2")
    @test a == 3

    trigger_callback(box, :mouseMoveNot, "not an event")
    @test a == 3
end

function testCallbacks03()
    canvas = RCanvas()
    @test numberOfCallbacks(canvas) == 0
    a = 0

    # Does not do much since there is no callback
    trigger_callback(canvas, :mouseMove, "not an event")
    trigger_callback(canvas, :mouseMove, "not an event")

    add_callback!(canvas, Callback(:mouseMove, () -> a = a + 1))
    @test numberOfCallbacks(canvas) == 1
    @test a == 0
    trigger_callback(canvas, :mouseMove, "not an event")
    @test a == 1
    trigger_callback(canvas, :mouseMove, "not an event")
    @test a == 2

    trigger_callback(canvas, :mouseMove, "not an event2")
    @test a == 3

    trigger_callback(canvas, :mouseMoveNot, "not an event")
    @test a == 3
end

#= function testCallbacks04()
    canvas = RCanvas()
    t = nothing
    add_callback!(canvas, Callback(:mouseMove, () -> t = (event, shape)))
    @test isnothing(t)
    @test numberOfCallbacks(canvas) == 1

    trigger_callback(canvas, :mouseMove, "not an event")
    @test length(t) == 2
    @test t[1] == "not an event"
    @test t[2] == canvas
end =#

function testCallback05()
    canvas = RCanvas()
    box1 = RBox()
    box2 = RBox()
    add!(canvas, box1)
    add!(canvas, box2)
    add_callback!(get_shapes(canvas), Callback(:mouseMove, () -> 42))
    @test numberOfCallbacks(box1) == 1
    @test numberOfCallbacks(box2) == 1

    add_callback!(get_shapes(canvas)[1], Callback(:mouseMove, () -> 42))
    @test numberOfCallbacks(box1) == 2
    @test numberOfCallbacks(box2) == 1

    add_callback!(get_shapes(canvas), Callback(:mouseMove, () -> 42))
    @test numberOfCallbacks(box1) == 3
    @test numberOfCallbacks(box2) == 2
end

@testset "offset_from_canvas_to_screen" begin
    gtk = GtkCanvas()
    @test offset_from_canvas_to_screen(gtk) != (0, 0)
    @test offset_from_canvas_to_screen(gtk) != (0, 0)
    # @test (offset_from_canvas_to_screen(gtk) .+ offset_from_canvas_to_screen(gtk)) == (0, 0)
end

@testset "Offset" begin
    c = RCanvas()
    @test c.offset_X == 0
    @test c.offset_Y == 0

    translate_to!(c, (10, 15))
    @test c.offset_X == 10
    @test c.offset_Y == 15

    translate_to!(c, (1, -5))
    @test c.offset_X == 11
    @test c.offset_Y == 10
end




# ------------------------------------
@testset "Roassal" begin
    testColor()
    testBox01()
    testBox02()
    testCanvas()
    testFetchingShape()
    testCallbacks01()
    testCallbacks02()
    #testCallbacks04()
end

include("Interaction.jl");
include("Line.jl");
