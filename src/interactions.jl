# ------------------------------------
# Animations

using Dates
using Base.Threads

export Animation, add!, oscillate!
export add_key_callback!, add_key_canvas_controller!, add_key_shape_controller!
export center_on_shape!

mutable struct Animation
    start_time::DateTime
    duration::Number
    callback::Function
    is_running::Bool
end

function Animation(callback::Function, duration::Number=1.0)
    return Animation(now(), duration, callback, false)
end

function add!(c::RCanvas, a::Animation)
    a.start_time = now()
    a.is_running = true
    push!(c.animations, a)
    return c
end

function oscillate!(
    s::Shape
    ;
    duration::Number=1.0, # seconds
    distance::Number=50,
    horizontal::Bool=true,
    vertical::Bool=false,
)
    original_pos = pos(s)
    function oscillate_callback(a)
        # In seconds
        running = (now() - a.start_time).value / 1000

        if running > duration
            a.is_running = false
            return
        end
        delta = distance * sin(running * 2 * π / duration)
        if horizontal && vertical
            translate_to!(s, original_pos .+ (delta, delta))
        elseif horizontal
            translate_to!(s, original_pos .+ (delta, 0))
        elseif vertical
            translate_to!(s, original_pos .+ (0, delta))
        end
    end

    add!(s.canvas, Animation(oscillate_callback, duration))
    return s
end

# ------------------------------------
# Interactions

function highlightable(canvas::RCanvas)
    foreach(shape -> highlightable(shape), get_shapes(canvas))
end

function highlightable(shapes::Vector{Shape})
    foreach(shape -> highlightable(shape), shapes)
end

#=
function highlightable(shape::Shape)
    oldColor = nothing
    function recordOld()
        oldColor = get_color(s)
        set_color!(shape, RColor_BLUE)
        print("Recorded!")
        println(oldColor)
    end
    function giveOldColor()
        println("mouse leave!")
        set_color!(shape, oldColor)
    end

    #add_callback!(shape, Callback(:mouseEnter, (event, s) -> recordOld(s)))
    #add_callback!(shape, Callback(:mouseLeave, (event, s) -> giveOldColor(s)))
    add_callback!(shape, Callback(:mouseEnter, recordOld))
    add_callback!(shape, Callback(:mouseLeave, giveOldColor))
    return shape
end =#

highlighted_shapes = Dict{Shape,RColor}()
function highlightable(shape::Shape)
    function recordColor(_, _)
        global highlighted_shapes[shape] = get_color(shape)
        println("Highlight: $(shape.model)")
        set_color!(shape, RColor_BLUE)
    end
    function restoreColor(_, _)
        #println("mouse leave! $(haskey(highlighted_shapes, shape))\n")
        if(haskey(highlighted_shapes, shape))
            set_color!(shape, highlighted_shapes[shape])
            delete!(highlighted_shapes, shape)
        end
    end

    add_callback!(shape, Callback(:mouseEnter, recordColor))
    add_callback!(shape, Callback(:mouseLeave, restoreColor))
    return shape
end

function reset_highlight()
    global highlighted_shapes = Dict{Shape,RColor}()
end

# ------------------------------------
# last_popup = nothing
# # Not sure we need it for now. Text support is necessary.
# function popup(shape::Shape)
#     function addPopup()
#         removePopup()
#         global last_popup = RBox(width=40, height=15)
#         add!(shape.canvas, last_popup)
#         translate_to!(last_popup, pos(shape) .- (20, 20))
#     end
#     function removePopup()
#         if(!isnothing(last_popup))
#             remove_shape!(shape.canvas, last_popup)
#             global last_popup = nothing
#         end
#     end

#     add_callback!(shape, Callback(:mouseEnter, addPopup))
#     add_callback!(shape, Callback(:mouseLeave, removePopup))
#     return shape
# end
# ------------------------------------


function add_key_callback!(
    shape_or_canvas::Union{Shape,RCanvas},
    key_number::Int,
    press_func::Function,
    release_func::Function
)
    is_pressed = false
    add_callback!(shape_or_canvas, Callback(:keyPress, (event, canvas) -> begin
        if event.keyval == key_number && !is_pressed
            is_pressed = true
            press_func(event, canvas)
        end
    end))

    add_callback!(shape_or_canvas, Callback(:keyRelease, (event, canvas) -> begin
        if event.keyval == key_number
            is_pressed = false
            release_func(event, canvas)
        end
    end))
end

function add_key_canvas_controller!(canvas::RCanvas)
    delta_x = Threads.Atomic{Int}(0)
    delta_y = Threads.Atomic{Int}(0)
    function _tmp(a)
        translate_by!(canvas, delta_x[], delta_y[])
    end
    add!(canvas, Animation(_tmp, 100))

    add_key_callback!(canvas, 65363,  # Right arrow
        (event, canvas) -> begin delta_x[] = 1 end,
        (event, canvas) -> begin delta_x[] = 0 end
    )

    add_key_callback!(canvas, 65364,  # Down arrow
        (event, canvas) -> begin delta_y[] = 1 end,
        (event, canvas) -> begin delta_y[] = 0 end
    )

    add_key_callback!(canvas, 65361,  # Left arrow
        (event, canvas) -> begin delta_x[] = -1 end,
        (event, canvas) -> begin delta_x[] = 0 end
    )

    add_key_callback!(canvas, 65362,  # Up arrow
        (event, canvas) -> begin delta_y[] = -1 end,
        (event, canvas) -> begin delta_y[] = 0 end
    )
end

function center_on_shape!(canvas::RCanvas, shape::Shape)
    p = pos(shape)
    translate_to!(canvas, -p[1], -p[2])
end

function add_key_shape_controller!(
    canvas::RCanvas,
    shape::Shape,
    callback::Function=()->nothing
)
    delta_x = Threads.Atomic{Int}(0)
    delta_y = Threads.Atomic{Int}(0)
    function _tmp(a)
        translate_by!(shape, delta_x[], delta_y[])
        callback()
    end
    add!(canvas, Animation(_tmp, 100))

    add_key_callback!(canvas, 65363,  # Right arrow
        (event, canvas) -> begin delta_x[] = 1 end,
        (event, canvas) -> begin delta_x[] = 0 end
    )

    add_key_callback!(canvas, 65364,  # Down arrow
        (event, canvas) -> begin delta_y[] = 1 end,
        (event, canvas) -> begin delta_y[] = 0 end
    )

    add_key_callback!(canvas, 65361,  # Left arrow
        (event, canvas) -> begin delta_x[] = -1 end,
        (event, canvas) -> begin delta_x[] = 0 end
    )

    add_key_callback!(canvas, 65362,  # Up arrow
        (event, canvas) -> begin delta_y[] = -1 end,
        (event, canvas) -> begin delta_y[] = 0 end
    )
end
