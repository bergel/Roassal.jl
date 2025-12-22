@testset "Simple 01" begin
    box = RBox()
    @test numberOfCallbacks(box) == 0
    add_callback!(box, Callback(:mouseMove, (event, shape) -> println("enter box")))
    @test numberOfCallbacks(box) == 1
end

@testset "Simple 02" begin
    box = RBox()
    a = 0

    # Does not do much since there is no callback
    trigger_callback(box, :mouseMove, "not an event")
    trigger_callback(box, :mouseMove, "not an event")

    add_callback!(box, Callback(:mouseMove, (event, shape) -> a = a + 1))
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

@testset "Simple 03" begin
    canvas = RCanvas()
    @test numberOfCallbacks(canvas) == 0
    a = 0

    # Does not do much since there is no callback
    trigger_callback(canvas, :mouseMove, "not an event")
    trigger_callback(canvas, :mouseMove, "not an event")

    add_callback!(canvas, Callback(:mouseMove, (event, shape) -> a = a + 1))
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

#= @testset testCallbacks04() begin
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

@testset "Simple 05" begin
    canvas = RCanvas()
    box1 = RBox()
    box2 = RBox()
    add!(canvas, box1)
    add!(canvas, box2)
    add_callback!(get_shapes(canvas), Callback(:mouseMove, (event, shape) -> 42))
    @test numberOfCallbacks(box1) == 1
    @test numberOfCallbacks(box2) == 1

    add_callback!(get_shapes(canvas)[1], Callback(:mouseMove, (event, shape) -> 42))
    @test numberOfCallbacks(box1) == 2
    @test numberOfCallbacks(box2) == 1

    add_callback!(get_shapes(canvas), Callback(:mouseMove, (event, shape) -> 42))
    @test numberOfCallbacks(box1) == 3
    @test numberOfCallbacks(box2) == 2
end
