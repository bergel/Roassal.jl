
@testset "Example 01" begin
    c = RCanvas()

    for _ in 1:10
        add!(c, RBox())
    end
    apply(FlowLayout(), c)
    @test map(pos, get_nodes(c)) == [(5.0, 5.0), (20.0, 5.0), (35.0, 5.0), (50.0, 5.0), (5.0, 20.0), (20.0, 20.0), (35.0, 20.0), (50.0, 20.0), (5.0, 35.0), (20.0, 35.0)]
end

@testset "Example 02" begin
    c = RCanvas()

    for i in 1:10
        add!(c, RBox(; size = i * 10, color=RColor(i/10, i/10, i/10)))
    end
    apply(FlowLayout(), c)
    @test map(pos, get_nodes(c)) == [(5.0, 5.0), (25.0, 10.0), (55.0, 15.0), (95.0, 20.0), (145.0, 25.0), (205.0, 30.0), (35.0, 100.0), (115.0, 105.0), (205.0, 110.0), (50.0, 210.0)]
end
