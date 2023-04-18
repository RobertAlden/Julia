using Compose, Colors, Reel
import Cairo, Fontconfig

function spiral(θ,n,colors)
    P = [0:n;]
    ⦞ =  @. ( P * 2θ * π - θ) / n
    S = P ./ n .* 0.45
    x = @. sin(⦞) * S + .5
    y = @. cos(⦞) * S + .5
    compose(context(),
            circle(x, y, [0.015, 0.02, 0.015, 0.025]),
            fill(colors))
end  

function main()
    dim = 512px
    set_default_graphic_size(dim, dim)
    figsize = 1px
    n = 500
    number_of_colors = 10
    start = HSV(0,1,1)
    stop = HSV(360,1,1)
    inital_colors = range(start,stop=stop, length=number_of_colors)
    final_colors = repeat(inital_colors, n÷number_of_colors+1)[1:n+1]
    film = roll(fps=30, duration=10) do t, dt
        spiral(5t,n,final_colors)
    end
    write("output.gif", film)
end

main()
