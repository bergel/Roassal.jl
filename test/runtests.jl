using Roassal
using Test
using Gtk

@testset "Canvas" begin
    include("canvas_test.jl");
end

@testset "Callback" begin
    include("callbacks_test.jl");
end

@testset "Interation" begin
    include("interaction_test.jl");
end

@testset "Shape" begin
    include("shapes/line_test.jl");
    include("shapes/box_test.jl")
end

@testset "Color" begin
    include("color_test.jl");
end

@testset "Layout" begin
    include("layouts/grid_test.jl");
    include("layouts/flow_test.jl");
    include("layouts/line_layout_test.jl");
    include("layouts/force_based_test.jl")
end
