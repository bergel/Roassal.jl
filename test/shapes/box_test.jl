@testset "Creation" begin
    @testset "Default" begin
        b = RBox()
        @test pos(b) == (0, 0)
        @test get_width(b) == 10
        @test get_height(b) == 10
    end

    @testset "Size" begin
        b = RBox(; size=20)
        @test pos(b) == (0, 0)
        @test get_width(b) == 20
        @test get_height(b) == 20
    end

end


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

@testset "Extent" begin
    @test get_width(RBox(; width=10, height= 5)) == 10
    @test get_height(RBox(; width=10, height= 5)) == 5
    @test extent(RBox(; width=10, height=5)) == (10, 5)

end
