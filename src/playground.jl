using Roassal
using Random

function example01()
    canvas = RCanvas()
    box = RBox()
    add!(canvas, box)
    extent!(box, 25, 15)
    translate_to!(box, -20, -20)
    rshow(canvas)
end

function example02()
    canvas = RCanvas()
    Random.seed!(42)
    for x in 1:3
        for y in 1:3
            box = RBox(color=RColor(rand(), rand(), rand()))
            translate_to!(box, x * 20, y * 20)
            add!(canvas, box)
        end
    end
    rshow(canvas)
end

function example03()
    canvas = RCanvas()
    Random.seed!(42)
    for x in 1:3
        for y in 1:3
            box = RBox(color=RColor(rand(), rand(), rand()))
            translate_to!(box, x * 20, y * 20)
            add!(canvas, box)
        end
    end
    highlightable(get_shapes(canvas))
    #add_callback!(get_shapes(canvas), Callback(:mouseClick, (event, shape) -> remove_shape!(canvas, shape)))
    #highlightable(get_shapes(canvas)[1])
    #add_callback!(firstBox, Callback(:mouseMove, (event, shape) -> println("CALLBACK mouse move $(shape)")))
    rshow(canvas)
end

function example04()
    c = RCanvas()
    box1 = RBox(;width=30, height=30)
    box2 = RBox(;width=30, height=30)
    add!(c, box1)
    add!(c, box2)
    translate_to!(box2, (40, 0))

    set_color!(box1, RColor_RED)
    set_color!(box2, RColor_GREEN)

    highlightable(box1)
    highlightable(box2)
    popup(box2)
    rshow(c)
end

function example05()
    c = RCanvas()
    box1 = RBox()
    box2 = RBox()

    add!(c, box1)
    add!(c, box2)

    translate_to!(box2, 50, 30)

    line = RLine(box1, box2)
    add!(c, line)

    rshow(c)
end

example05()

print("Press Enter to exit")
readline()
