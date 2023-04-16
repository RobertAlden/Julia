using Compose, Colors, Reel
import Cairo, Fontconfig

function spiral(θ,n,colors)
    P = [0:n;]
    Data =  @. ( P * 2θ * π - θ) / n
    Scale = P ./ n .* 0.5
    x = @. sin(Data) * Scale + .5
    y = @. cos(Data) * Scale + .5
    compose(context(),
            circle(x, y, [0.01]),
            fill(colors))
end  

function main()
    set_default_graphic_size(128px, 128px)
    figsize = 1px
    n = 100
    colors = distinguishable_colors(n+1)
    film = roll(fps=30, duration=10.0) do t, dt
        spiral(3t,n,colors)
    end
    write("output.gif", film)
end

@time main()