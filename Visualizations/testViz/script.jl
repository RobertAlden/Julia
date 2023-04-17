using Compose, Colors, Reel, IterTools
import Cairo, Fontconfig

function driver(t,x,d)
    speed = 5
    max_length = 0.5
    θ = @. speed * t * x * 2 * π
    m = @. d * max_length
    m[1] = 0.0
    v = [cos.(θ), sin.(θ)] .* m
    points = collect(partition(accumulate(+,v),2,1))
    compose(
        context(), 
        (context(units=UnitBox(-1,-1,2,2)),
            line(points),stroke("black"), linewidth(3px))
    )
end

function main()
    dim = 512px
    set_default_graphic_size(dim, dim)
    figsize = 1px

    n = 5
    x = rand(Float16,n)
    f = rand(Float16,n)
    film = roll(fps=30, duration=5.0) do t, dt
        driver(t,x,f)
    end
    write("output.gif", film)
end

@time main()