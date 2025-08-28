using Roassal: compute_encompassing_rectangle, is_intersecting

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

@testset "Nodes and Shapes" begin
    c = RCanvas()
    add!(c, RBox(; color=RColor(1.0, 0, 0)))
    add!(c, RBox(; color=RColor(0, 1.0, 0)))
    add!(c, RBox(; color=RColor(0, 0, 1.0)))

    boxes = get_shapes(c)
    add!(c, RLine(boxes[1], boxes[2]))
    add!(c, RLine(boxes[1], boxes[3]))
    add!(c, RLine(boxes[2], boxes[3]))

    @test length(get_shapes(c)) == 6
    @test length(get_nodes(c)) == 3
    @test all(n -> n isa RBox, get_nodes(c))
    @test length(get_edges(c)) == 3
    @test all(n -> n isa RLine, get_edges(c))
end

@testset "Encompassing rectangle" begin
    @testset "Empty canvas" begin
        c = RCanvas()
        @test compute_encompassing_rectangle(get_shapes(c)) == (0.0, 0.0, 0.0, 0.0)
    end

    @testset "With shapes" begin
        c = RCanvas()
        add!(c, translate_to!(RBox(), 10, 10))
        add!(c, translate_to!(RBox(), 100, 10))
        add!(c, translate_to!(RBox(), 10, 150))

        @test compute_encompassing_rectangle(get_shapes(c)) == (5.0, 5.0, 105.0, 155.0)

        center!(c)
        @test c.offset_X == -55
        @test c.offset_Y == -80
    end
end

@testset "RCanvas show" begin
    c = RCanvas()
    io = IOBuffer()
    show(io, c)
    @test String(take!(io)) == "RCanvas{ 0 shapes, offset:(0, 0), size:(0, 0)) }"

    add!(c, RBox())
    io = IOBuffer()
    show(io, c)

    @test String(take!(io)) == "RCanvas{ 1 shapes, offset:(0, 0), size:(0, 0)) }"

    add!(c, RBox())
    io = IOBuffer()
    show(io, c)

    @test String(take!(io)) == "RCanvas{ 2 shapes, offset:(0, 0), size:(0, 0)) }"
end

# @testset "BoundedShape intersection" begin
#     c = RCanvas()
#     s1 = RBox(; x=10, y=10, width=20, height=20, color=RColor(1.0, 0, 0))
#     s2 = RBox(; x=15, y=15, width=20, height=20, color=RColor(0, 1.0, 0))
#     s3 = RBox(; x=50, y=50, width=20, height=20, color=RColor(0, 0, 1.0))

#     add!(c, s1)
#     add!(c, s2)
#     add!(c, s3)

#     # Between shapes
#     @test is_intersecting(s1, s2) == true
#     @test is_intersecting(s2, s1) == true
#     @test is_intersecting(s1, s3) == false
#     @test is_intersecting(s3, s1) == false
#     @test is_intersecting(s2, s3) == false
#     @test is_intersecting(s3, s2) == false

#     # Manually set the canvas size (it is not set since not rendered)
#     # Sanity checks
#     c.width = 200
#     c.height = 200
#     center!(c)
#     @test c.offset_X == -30
#     @test c.offset_Y == -30

#     # Intersection with canvas offset
#     @test is_intersecting(s1, c) == true
#     @test is_intersecting(s2, c) == true
#     @test is_intersecting(s3, c) == true

#     # Move a shape outside the canvas
#     translate_to!(s3, 300, 300)
#     @test is_intersecting(s3, c) == false
#     @test is_intersecting(c, s3) == false

#     # Move it back
#     translate_to!(s3, 50, 50)
#     @test is_intersecting(s3, c) == true
#     @test is_intersecting(c, s3) == true

#     # Move the canvas offset
#     translate_by!(c, (110, 110))
#     @test c.offset_X == 80
#     @test c.offset_Y == 80
#     @test is_intersecting(s1, c) == false
#     @test is_intersecting(c, s1) == false
#     @test is_intersecting(s2, c) == false
#     @test is_intersecting(c, s2) == false
#     @test is_intersecting(s3, c) == false
#     @test is_intersecting(c, s3) == false

#     @test compute_encompassing_rectangle(c) == (80.0, 80.0, 280.0, 280.0)

#     # Move the shape at the edge of the canvas
#     translate_to!(s3, 80, 80)
#     @test is_intersecting(s3, c) == true
#     @test is_intersecting(c, s3) == true
# end