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

function example06()
    c = RCanvas()
    s1 = RCircle()
    s2 = RCircle()

    add!(c, s1)
    add!(c, s2)

    line = RLine(s1, s2)
    add!(c, line)

    translate_to!(s2, 50, 30)
    rshow(c)
    translate_by!(s2, 20, 20)
    translate_by!(s1, -40, -10)
end

function example07()
    c = RCanvas()
    for i in 1:10
        add!(c, RBox(; size = i * 10, color=RColor(i/10, i/10, i/10)))
    end
    apply(FlowLayout(), c)
    rshow(c)
end


function example08()
    c = RCanvas()
    for i in 1:10
        add!(c, RBox(; color=RColor(i/10, i/10, i/10)))
    end
    apply(ForceBasedLayout(), c) ; rshow(c)
end

function example09()
    c = RCanvas()
    add!(c, RBox(; color=RColor(1.0, 0, 0)))
    add!(c, RBox(; color=RColor(0, 1.0, 0)))
    add!(c, RBox(; color=RColor(0, 0, 1.0)))
    boxes = get_shapes(c)

    add!(c, RLine(boxes[1], boxes[2]))
    add!(c, RLine(boxes[1], boxes[3]))
    add!(c, RLine(boxes[2], boxes[3]))

    apply(ForceBasedLayout(1), c) ; rshow(c)
end

function example10()
    c = RCanvas()
    add!(c, RBox(; color=RColor(1.0, 0, 0)))
    add!(c, RBox(; color=RColor(0, 1.0, 0)))
    add!(c, RBox(; color=RColor(0, 0, 1.0)))
    boxes = get_shapes(c)

    add!(c, RLine(boxes[1], boxes[2]))
    add!(c, RLine(boxes[1], boxes[3]))
    #add!(c, RLine(boxes[2], boxes[3]))

    apply(ForceBasedLayout(1), c) ; rshow(c)
end

function example11()
    c = RCanvas()
    for x in 0.0:0.1:1.0
        for y in 0.0:0.1:1.0
            add!(c, RBox(; color=RColor(x, y, 0.5)))
        end
    end
    apply(GridLayout(2, 10), c) ; rshow(c)
end

function example12()
    # DOES NOT WORK :( TEXT IS NOT YET SUPPORTED
    c = RCanvas()
    #add!(c, RText("Hello"))
    rshow(c)
end

function example13()
    c = RCanvas()
    nb_circles = 100
    for i in 1:nb_circles
        circle = RCircle(; color=RColor(0.7, 0, 0), model=i)
        add!(c, circle)
        set_size!(circle, 20 * sin(i / nb_circles * 3.1415))
    end
    apply(GridLayout(2, 10), c) ; rshow(c)
    highlightable(c)
    rshow(c)
end

function example14()
    c = RCanvas()
    circle = RCircle(; height=50, width=50)
    add!(c, circle)

    function cb()
        set_color!(circle, random_color())
        translate_by!(circle, 5, 4)
    end
    add_callback!(circle, Callback(:mouseEnter, cb))
    rshow(c)
end


function example15()
    c = RCanvas()
    s1 = RCircle()
    s2 = RCircle()

    add!(c, s1)
    add!(c, s2)

    line = RLine(s1, s2)
    add!(c, line)

    translate_to!(s2, 50, 30)
    rshow(c)

    add_callback!(s1, Callback(:mouseEnter, () -> translate_by!(s1, 10, 10)))
    add_callback!(s2, Callback(:mouseEnter, () -> translate_by!(s2, 10, -10)))

end


# example11()

#= print("Press Enter to exit")
readline()
 =#
