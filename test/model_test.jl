@testset "Default" begin
    @test isnothing(RBox().model)
    @test isnothing(get_model(RBox()))
end

@testset "Initialize" begin
    @test RBox(model=42).model == 42
    @test get_model(RBox(model=42)) == 42
end

@testset "Get model from canvas" begin
    c = RCanvas()
    b = RBox(model=42)
    add!(c, b)
    @test get_shape(c, 42) === b
    @test isnothing(get_shape(c, 41))
end