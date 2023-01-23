
@testset "Example 01" begin
    c = RCanvas()

    for _ in 1:10
        add!(c, RBox())
    end
    apply(GridLayout(), c)
    @test map(pos, get_nodes(c)) == [(5.0, 5.0), (20.0, 5.0), (35.0, 5.0), (50.0, 5.0), (5.0, 20.0), (20.0, 20.0), (35.0, 20.0), (50.0, 20.0), (5.0, 35.0), (20.0, 35.0)]
end

@testset "Example 02" begin
    c = RCanvas()

    for i in 1:10
        add!(c, RBox(; size = i * 10, color=RColor(i/10, i/10, i/10)))
    end
    apply(GridLayout(), c)
    @test map(pos, get_nodes(c)) == [(5.0, 5.0), (25.0, 10.0), (55.0, 15.0), (95.0, 20.0), (25.0, 70.0), (85.0, 75.0), (155.0, 80.0), (235.0, 85.0), (45.0, 175.0), (145.0, 180.0)]
end

@testset "Line count" begin
    l = GridLayout()
    @test 2 == Roassal._get_line_count(l, [RBox() for _ in 1:4])
    @test 4 == Roassal._get_line_count(l, [RBox() for _ in 1:10])
    @test 3 == Roassal._get_line_count(l, [RBox() for _ in 1:9])
end
