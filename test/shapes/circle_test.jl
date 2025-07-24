@testset "Extent" begin
    @test get_width(RCircle(; width=10, height= 5)) == 10
    @test get_height(RCircle(; width=10, height= 5)) == 5
    @test extent(RCircle(; width=10, height=5)) == (10, 5)

    @test extent(RCircle(; radius=25)) == (50, 50)
    @test pos(RCircle(; radius=25)) == (0, 0)
end