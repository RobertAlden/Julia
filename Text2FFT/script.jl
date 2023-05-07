using Compose, Colors, Reel, FileIO, ImageFiltering, Images, ImageEdgeDetection, Match, AbbreviatedStackTraces, FFTW, FFTViews
using ImageEdgeDetection: Percentile
import Cairo, Fontconfig

using Random, IterTools

function textToImage(txt)
    text_composition = compose(context(),
    (context(), 
        text(0.5,0.6,txt,hcenter,vcenter),
        fontsize(55px), stroke("red"), font("consolas")),
    (context(), rectangle(),fill("white"))
    )
    draw(PNG("text.png",(32*length(txt))px, 64px),text_composition)
    FileIO.load("text.png")
end

function edgeDetection(img)
    alg = Canny(spatial_scale=2, high=Percentile(80), low=Percentile(70))
    detect_edges(img, alg)
end

function edgeSimplification(img)
    # TODO: try finding derivatives of parametric functions defining each letter and
    # remove regions of constant derivative 
    # if thats too hard, remove pixels randomly/ use a kernel that finds linear sections and 
    # leaves only endpoints
    img
end

function distance2(ab) 
    ((ax,ay),(bx,by)) = ab
    (ax-bx)^2 + (ay-by)^2
end

function pathDistance2(path)
    sum(distance2.(partition([path;[path[1]]],2,1)))
end

function TSP(img)
    height,width = size(img)
    # genetic algorithm
    Random.seed!(10) #random seed
    points = findall(x->x === RGB(1,1,1), img)

    #ad hoc filter
    points = filter(_->rand() < 1,points)
    
    points = [Tuple(i) for i in points]
    N = length(points)
    path = [1:N;]
    startLength = pathDistance2(points[path])
    currentLength = startLength
    improvement = true
    @views while improvement
        improvement = false
        for u=0:N, v=u+1:N-1
            i = u + 1
            j = v + 1
            AC = points[path[[i,mod1(i+1,N)]]]
            BD = points[path[[j,mod1(j+1,N)]]]
            AB = points[path[[i,j]]]
            CD = points[path[[mod1(i+1,N),mod1(j+1,N)]]]
            ACBD = (distance2(AC) + distance2(BD))
            ABCD = (distance2(AB) + distance2(CD))
            lengthDelta = -ACBD + ABCD
            if lengthDelta < 0
                path[i+1:j] .= reverse(path[i+1:j])
                currentLength += lengthDelta
                currentLength < 0 && break
                improvement = true
            end
        end
    end

    lines::Vector{Tuple{Int64,Int64}} = [(i[2],i[1]) for i in points[path]]
    push!(lines,lines[1])
    composition = compose(
                    context(units=UnitBox(0,0,width,height)), 
                    (context(), line(lines), stroke("white"), linewidth(1px))
                    ,(context(), rectangle(), fill("black"))
                  )
    draw(PNG("3tsp.png", (width)px, (height)px), composition)
    println("Distance reduction: $(trunc((1-pathDistance2(points[path])/startLength)*100))%")
    push!(path,first(path))
    (points[path],width,height)
end

lerp(a,b,t) = (b - a) * t + a

function interpolateData(data,t) 
    n = length(data)
    t == 1.0 && return data[n]
    subt = t - trunc(t)
    ti = trunc(Int,t)
    lerp(data[ti+1],data[ti+2],subt)
end 


function fourierSeries(data)
    # note: Cn = ∫01 ℯ^(-2πιnt) f(t)dt
    path,width,height = data
    N = length(path)
    dt = 1/N
    println("dt/N:$dt $N")
    Ft = complex.(last.(path)/width,first.(path)/height)
    fs = fft(Ft) |> FFTView
    fs ./= N
    fs,width,height
end

remap_idx(i::Int) = (-1)^i * floor(Int, i / 2)
remap_inv(n::Int) = 2n * sign(n) - 1 * (n > 0)

function driver(T,Cs, trace)
    testData = 
    Csp = x-> interpolateData(Cs,x)
    N = length(Cs)
    range = N÷2
    dt = 1/N
    Czs = [Cs[remap_idx(i)]*cispi(remap_idx(i)*-2*T) for i=1:N]
    Xs = 2 .* real.(Czs)
    Ys = 2 .* imag.(Czs)
    z = 2
    lines = collect(IterTools.partition(accumulate(.+,zip(Xs,Ys)),2,1))
    push!(trace,last(lines)[2])
    #println(trace)
    trace_lines = collect(IterTools.partition(trace,2,1))
    compose(
        context(units=UnitBox(0,0,1z,1z)), 
        (context(),
            line(lines),stroke("grey"), linewidth(1px)),
        (context(),
            line(trace_lines),stroke("white"), linewidth(1px)),  
    )

end

function animate(data)
    consts,width,height = data
    dim = 512px
    set_default_graphic_size(width * 1px, height * 1px)
    time = 10
    trace = []
    film = roll(fps=30, duration=time) do t, dt
        driver(t/time,consts,trace)
    end
    write("output.gif", film)
end

function main()
    input_text = "ROBERT"
    input_text |> 
    textToImage |> 
    edgeDetection |> 
    edgeSimplification |> 
    TSP |>
    fourierSeries |>
    animate
end

@time main()
