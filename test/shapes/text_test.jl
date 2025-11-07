@testset "Creation" begin
    @testset "Default" begin
        b = RText("Hello")
        @test pos(b) == (0, 0)
        @test get_width(b) == 0
        @test get_height(b) == 0

        c = RCanvas()
        add!(c, b)
        @test number_of_shapes(c) == 1
    end
end