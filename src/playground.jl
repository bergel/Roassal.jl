using Roassal
using Random

function example01()
    canvas = RCanvas()
    box = RBox()
    add!(canvas, box)
    extent!(box, 25, 15)
    translateTo!(box, -20, -20)
    rshow(canvas)
end

function example02() 
    canvas = RCanvas()
    Random.seed!(42)
    for x in 1:3
        for y in 1:3
            box = RBox(color=RColor(rand(), rand(), rand()))
            translateTo!(box, x * 20, y * 20)
            add!(canvas, box)
        end
    end
    rshow(canvas)
end

example02()

print("Press Enter to exit")
readline()