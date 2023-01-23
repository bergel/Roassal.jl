
@testset "Force based simple" begin
    c = RCanvas()

    for _ in 1:4
        add!(c, RBox())
    end

    apply(ForceBasedLayout(), c)
    @test map(pos, get_nodes(c)) == [(5.0, 5.0), (5.0, 20.0), (5.0, 35.0), (5.0, 50.0)]
end
