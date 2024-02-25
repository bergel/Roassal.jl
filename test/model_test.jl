@testset "Default" begin
    @test isnothing(RBox().model)
    @test isnothing(get_model(RBox()))
end

@testset "Initialize" begin
    @test RBox(model=42).model == 42
    @test get_model(RBox(model=42)) == 42
end