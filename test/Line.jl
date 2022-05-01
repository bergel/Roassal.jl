@testset "Line - basic" begin
    c = RCanvas()
    box1 = RBox()
    box2 = RBox()

    @test isempty(box1.outgoing_edges)
    @test isempty(box1.incoming_edges)
    @test isempty(box2.outgoing_edges)
    @test isempty(box2.incoming_edges)

    line = Line(box1, box2)

    @test line.from == box1
    @test line.to == box2
end
