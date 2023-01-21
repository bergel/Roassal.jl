
@testset "Simple 01" begin
    c = RCanvas()

    for _ in 1:4
        add!(c, RBox())
    end

    boxes = get_shapes(c)
    @test length(boxes) == 4
    @test all(b -> pos(b) == (0, 0), boxes)

    apply(GridLayout(), c)
    @test pos(boxes[1]) == (0, 0)
    @test all(b -> pos(b) != (0, 0), boxes[2:end])
end

@testset "Line count" begin
    l = GridLayout()
    @test 2 == Roassal._get_line_count(l, [RBox() for _ in 1:4])
    @test 4 == Roassal._get_line_count(l, [RBox() for _ in 1:10])
    @test 3 == Roassal._get_line_count(l, [RBox() for _ in 1:9])
end
