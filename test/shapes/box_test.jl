
@testset "Encompassing" begin
    aColor = RColor()
    box1 = RBox(color=aColor)
    @test box1.color == aColor
    @test pos(box1) == (0,0)
    @test extent(box1) == (10,10)
    @test compute_encompassing_rectangle(box1) == (-5, -5, 10, 10)

    c = get_color(box1)
    @test c === aColor
    anotherColor = RColor(1.0, 1.0, 0.5)
    set_color!(box1, anotherColor)
    @test get_color(box1) === anotherColor
end

@testset "Simple" begin
    box = RBox()
    @test box.x == 0
    @test box.color != RColor()
end
