@testset "Simple 01" begin
    aColor = RColor()
    @test aColor.r == aColor.g
    @test aColor.r == aColor.b
end
