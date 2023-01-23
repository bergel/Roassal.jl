
@testset "Horizontal line" begin
    c = RCanvas()

    for _ in 1:4
        add!(c, RBox())
    end

    @test all(b -> pos(b) == (0, 0), get_shapes(c))

    apply(HorizontalLineLayout(), c)
    @test map(pos, get_nodes(c)) == [(5.0, 5.0), (20.0, 5.0), (35.0, 5.0), (50.0, 5.0)]
end

@testset "Vertical line" begin
    c = RCanvas()

    for _ in 1:4
        add!(c, RBox())
    end

    apply(VerticalLineLayout(), c)
    @test map(pos, get_nodes(c)) == [(5.0, 5.0), (5.0, 20.0), (5.0, 35.0), (5.0, 50.0)]
end
