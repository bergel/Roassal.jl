using Roassal
using Test
# ------------------------------------
function testColor()
    aColor = RColor()
    @test aColor.r == aColor.g
    @test aColor.r == aColor.b 
end

function testBox01() 
    aColor = RColor()
    box1 = RBox(color=aColor)
    @test box1.color == aColor
    @test pos(box1) == (0,0)
    @test extent(box1) == (10,10)
    @test computeEncompassingRectangle(box1) == (-5, -5, 10, 10)
end

function testBox02() 
    box = RBox()
    @test box.x == 0
    @test box.color != RColor()
end

function testCanvas() 
    box1 = RBox(color=RColor(0.4, 0.1, 0.3))
    box = RBox()
    canvas = RCanvas()
    @test numberOfShapes(canvas) == 0
    add!(canvas, box1)
    @test numberOfShapes(canvas) == 1
    add!(canvas, box)
    @test numberOfShapes(canvas) == 2
end

# ------------------------------------
function testFetchingShape()
    canvas = RCanvas()
    box = RBox()
    add!(canvas, box)
    translateTo!(box, 50, 50)
    @test pos(box) == (50, 50)

    #@test isPositionWithinEncompassingRectangleOf(box, 50, 50)
    #@test !isPositionWithinEncompassingRectangleOf(box, -50, 50)
    #@test !isPositionWithinEncompassingRectangleOf(box, -50, -50)

    @test getShapeAtPosition(canvas, 50, 50) === box
    @test getShapeAtPosition(canvas, 50, 50) == box
    @test getShapeAtPosition(canvas, -50, -50) == canvas
    @test getShapeAtPosition(canvas, -50, -50) === canvas
end

function testCallbacks()
    box = RBox()
    @test numberOfCallbacks(box) == 0
end

# ------------------------------------
@testset "Roassal.jl" begin
    testColor()
    testBox01()
    testBox02()
    testCanvas()
    testFetchingShape()
    testCallbacks()
end
