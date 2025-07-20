# ------------------------------------
# Animations

using Dates
struct Animation
    start_time::DateTime
    duration::Number
    callback::Function
    is_running::Bool
end

function Animation(callback::Function, duration::Number)
    return Animation(now(), duration, callback, false)
end

function add!(c::RCanvas, a::Animation)
    a.start_time = now()
    a.is_running = true
    push!(c.animations, a)
    return c
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
    function recordColor()
        global highlighted_shapes[shape] = get_color(shape)
        println("Highlight: $(shape.model)")
        set_color!(shape, RColor_BLUE)
    end
    function restoreColor()
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
