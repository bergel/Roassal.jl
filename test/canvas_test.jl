@testset "Offset" begin
    c = RCanvas()
    @test c.offset_X == 0
    @test c.offset_Y == 0

    translate_by!(c, (10, 15))
    @test c.offset_X == 10
    @test c.offset_Y == 15

    translate_by!(c, (1, -5))
    @test c.offset_X == 11
    @test c.offset_Y == 10

    translate_to!(c, (10, -50))
    @test c.offset_X == 10
    @test c.offset_Y == -50
end

@testset "offset_from_canvas_to_screen" begin
    gtk = GtkCanvas()
    @test offset_from_canvas_to_screen(gtk) != (0, 0)
    @test offset_from_canvas_to_screen(gtk) != (0, 0)
    # @test (offset_from_canvas_to_screen(gtk) .+ offset_from_canvas_to_screen(gtk)) == (0, 0)
end


@testset "Shape lookup" begin
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

@testset "Shape removing" begin
    canvas = RCanvas()
    box1 = RBox()
    box2 = RBox()
    box3 = RBox()
    add!(canvas, box1)
    add!(canvas, box2)
    add!(canvas, box3)

    remove_shape!(canvas, box2)
    @test number_of_shapes(canvas) == 2
    @test get_shapes(canvas)[1] === box1
    @test get_shapes(canvas)[2] === box3

    remove_shape!(canvas, box1)
    @test number_of_shapes(canvas) == 1
    @test get_shapes(canvas)[1] === box3

    # Not in the canvas!
    remove_shape!(canvas, box1)
    @test number_of_shapes(canvas) == 1
    @test get_shapes(canvas)[1] === box3

    remove_shape!(canvas, box3)
end


@testset "Simple 01" begin
    box1 = RBox(color=RColor(0.4, 0.1, 0.3))
    box = RBox()
    canvas = RCanvas()
    @test number_of_shapes(canvas) == 0
    add!(canvas, box1)
    @test number_of_shapes(canvas) == 1
    add!(canvas, box)
    @test number_of_shapes(canvas) == 2
end

@testset "Simple 02" begin
    canvas = RCanvas()
    @test isempty(get_shapes(canvas))
    box1 = RBox()
    box2 = RBox()
    add!(canvas, box1)
    add!(canvas, box2)
    @test number_of_shapes(canvas) == 2
    @test get_shapes(canvas)[1] === box1
    @test get_shapes(canvas)[2] === box2
end
