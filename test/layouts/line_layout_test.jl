
@testset "Horizontal line" begin
    c = RCanvas()

    for _ in 1:4
        add!(c, RBox())
    end

    @test all(b -> pos(b) == (0, 0), get_shapes(c))

    apply(HorizontalLineLayout(), c)
    @test map(pos, get_shapes(c)) == [(0, 0), (15.0, 0), (30.0, 0), (45.0, 0)]
end
