using Compose, Colors, Reel, IterTools
import Cairo, Fontconfig

xs = [];
ys = [];

function driver(t,x,d,colors)
    speed = 1
    max_length = 0.7
    θ = @. speed * t * x * 2 * π
    m = @. d * max_length
    m[1] = 0.0
    v = zip(cos.(θ) .* m, sin.(θ) .* m)  
    points = collect(partition(accumulate(.+,v),2,1))
    trace = last(points)
    push!(xs,trace[2][1])
    push!(ys,trace[2][2])
    compose(
        context(), 
        (context(units=UnitBox(-1,-1,2,2)),
            line(points),stroke("black"), linewidth(3px),
            circle(xs,ys,[0.01]), fill(colors)))
end

function main()
    dim = 512px
    set_default_graphic_size(dim, dim)
    figsize = 1px

    colors = distinguishable_colors(20)
    n = 5
    x = rand(Float16,n) .* 2 .- 1
    f = rand(Float16,n)
    film = roll(fps=30, duration=5.0) do t, dt
        driver(t,x,f,colors)
    end
    write("output.gif", film)
end

main()