using AbbreviatedStackTraces, Infiltrator
using Compose, Colors, Reel, IterTools, Base.Iterators
import Cairo, Fontconfig

xs = [];
ys = [];

function driver(t,Is,As,Ls,colors)
    speed = 0.11
    max_length = 0.35
    θs = @. speed * t * (Is .+ As) * 2π
    Ds = @. Ls * max_length
    Ds[1] = 0.0
    Vs = zip(cos.(θs) .* Ds, sin.(θs) .* Ds)  
    lines = collect(IterTools.partition(accumulate(.+,Vs),2,1))
    trace = last(lines)
    push!(xs,trace[2][1])
    push!(ys,trace[2][2])
    xs .+= 0.015
    compose(
        context(0.05,0.05,0.9,0.9), 
        (context(units=UnitBox(-.25,-1,2,2)),
            line(lines),stroke("white"), linewidth(3px)),
        (context(units=UnitBox(-.25,-1,2,2)),
            circle(xs,ys,[0.01]),  
            fill(collect(take(cycle(colors),length(xs))))))
end

function main()
    dim = 256px
    set_default_graphic_size(dim, dim)

    colors = distinguishable_colors(20)
    n = 10
    max_speed = 5
    Is = rand(Float16,n) .* 2π
    As = rand(Float16,n) .* 2max_speed .- max_speed
    Ls = sort(rand(Float16,n),rev=true)
    film = roll(fps=30, duration=30) do t, dt
        driver(t,Is,As,Ls,colors)
    end
    write("output.gif", film)
end

main()