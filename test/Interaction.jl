
@testset "highlightable - basic, on one shape" begin
    c = RCanvas()
    box = RBox()
    add!(c, box)
    @test pos(box) == (0, 0)

    set_color!(box, RColor_RED)
    @test get_color(box) == RColor_RED
    trigger_callback(box, :mouseEnter)
    @test get_color(box) == RColor_RED

    highlightable(box)
    @test get_color(box) == RColor_RED
    trigger_callback(box, :mouseEnter)
    @test get_color(box) == RColor_BLUE
end

@testset "highlightable - basic, on two shapes, without leaving event" begin
    c = RCanvas()
    box1 = RBox()
    box2 = RBox()
    add!(c, box1)
    add!(c, box2)
    translate_to!(box2, (30, 0))

    set_color!(box1, RColor_RED)
    set_color!(box2, RColor_GREEN)

    highlightable(box1)
    highlightable(box2)

    @test get_color(box1) == RColor_RED
    @test get_color(box2) == RColor_GREEN
    trigger_callback(box1, :mouseEnter)
    @test get_color(box1) == RColor_BLUE
    @test get_color(box2) == RColor_GREEN

    trigger_callback(box1, :mouseLeave)
    @test get_color(box1) == RColor_RED

    @test get_color(box2) == RColor_GREEN
    trigger_callback(box2, :mouseEnter)
    @test get_color(box2) == RColor_BLUE

    trigger_callback(box2, :mouseLeave)
    @test get_color(box2) == RColor_GREEN


end

@testset "highlightable - basic, on two shapes, without leaving event" begin
end
