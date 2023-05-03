using Match, AbbreviatedStackTraces
using Compose, Colors, Reel, FileIO, ImageFiltering, Images, ImageEdgeDetection 
using ImageEdgeDetection: Percentile
using Random, IterTools
import Cairo, Fontconfig

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
    points = filter(_->rand() < 0.1,points)
    
    points = [Tuple(i) for i in points]
    N = length(points)
    println(N)
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
    (img,points[path])
end

function fourierSeries(imgpath)
    img,path = imgpath
    # note: Cn = ∫01 ℯ^(-2πιnt) f(t)dt
    N = length(path)
    dt = 1/N
    iterations = 10
    xs, ys = (first.(path),last.(path))
    Cxs = []
    Cys = []
    for n=0:iterations-1
        push!(Cxs,sum((xs[i]*cos(-2π*n*((i-1)*dt))*dt) for i=1:N))
        push!(Cys,sum((ys[i]*sin(-2π*n*((i-1)*dt))*dt) for i=1:N))
    end
    (img,Cxs,Cys)
end

function driver(t,N,Cx,Cy,trace)
    Xs = [Cx[x] * cos(x*t) for x=1:N]
    Ys = [Cy[y] * sin(y*t) for y=1:N]
    z = 150
    lines = collect(IterTools.partition(accumulate(.+,zip(Xs,Ys)),2,1))
    push!(trace,last(lines)[2])
    #println(trace)
    trace_lines = collect(IterTools.partition(trace,2,1))
    compose(
        context(0.05,0.05,0.9,0.9), 
        (context(units=UnitBox(-z,-z,2z,2z)),
            line(lines),stroke("grey"), linewidth(1px)),
        (context(units=UnitBox(-z,-z,2z,2z)),
            line(trace_lines),stroke("white"), linewidth(1px)),  
    )

end

function animate(imgconsts)
    dim = 256px
    set_default_graphic_size(dim, dim)

    img,Cxs,Cys = imgconsts
    N = length(Cxs)
    time = 10
    trace = []
    film = roll(fps=30, duration=time) do t, dt
        driver(t*time,N,Cxs,Cys,trace)
    end
    write("output.gif", film)
    img
end

function main()
    input_text = "hello world"
    input_text |> 
    textToImage |> 
    edgeDetection |> 
    edgeSimplification |> 
    TSP |>
    fourierSeries |>
    animate |>
    FileIO.save("out.png")
end

@time main()
