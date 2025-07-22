@testset "Shape show" begin
    io = IOBuffer()
    show(io, RBox())
    @test String(take!(io)) == "RBox{ pos:(0, 0), width: 10, height: 10, color:RColor(0.8, 0.8, 0.8), model:nothing }"

    io = IOBuffer()
    show(io, RCircle())
    @test String(take!(io)) == "RCircle{ pos:(0, 0), color:RColor(0.8, 0.8, 0.8), model:nothing }"

end