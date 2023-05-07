using Compose, Colors, Reel, FileIO, ImageFiltering, Images, ImageEdgeDetection, Match, AbbreviatedStackTraces, FFTW, FFTViews
using ImageEdgeDetection: Percentile
import Cairo, Fontconfig

using Random, IterTools

function textToImage(txt)
    text_composition = compose(context(),
    (context(), 
        text(0.5,0.5,txt,hcenter,vcenter),
        fontsize(55px), stroke("red"), font("Bahnschrift")),
    (context(), rectangle(),fill("white"))
    )
    draw(PNG("text.png",(32*length(txt))px, 72px),text_composition)
    FileIO.load("text.png")
end

function edgeDetection(img)
    alg = Canny(spatial_scale=3, high=Percentile(75), low=Percentile(60))
    detect_edges(img, alg)
end

function edgeSimplification(img)
    height,width = size(img)
    points = findall(x->x === RGB(1,1,1), img)
    field = zeros(Int,height,width)
    field[points] .= 1
    r = 1
    region = -r:r
    mask1 = [0 1 0; 0 1 0; 0 1 0]
    mask2 = [1 0 0; 0 1 0; 0 0 1]
    masks = [mask1,mask1',mask2,reverse(mask2)]
    @views for x=r+1:width-r, y=r+1:height-r
        area = field[y.+region, x.+region]
        if sum(area) >= 4 || any(masks .== [area])
            field[y,x] = 0
        end
    end
    points = findall(x->x == 1, field)
    points,width,height
end

function distance2(ab) 
    ((ax,ay),(bx,by)) = ab
    (ax-bx)^2 + (ay-by)^2
end

function pathDistance2(path)
    sum(distance2.(partition([path;[path[1]]],2,1)))
end

function two_opt(points)
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
    path
end

function three_opt(points)
    N = length(points)
    path = [1:N;]
    startLength = pathDistance2(points[path])
    currentLength = startLength
    improvement = true
    @views while improvement
        improvement = false
        for u=1:N-1, v=u+2:N-1, w=v+2:N
            i = u + 1
            j = v + 1
            k = w + 1
            A,B,C,D,E,F = i-1,i,j-1,j,k-1,mod1(k,N)
            d0 = distance2(points[path[[A,B]]]) + distance2(points[path[[C,D]]]) + distance2(points[path[[E,F]]])
            d1 = distance2(points[path[[A,C]]]) + distance2(points[path[[B,D]]]) + distance2(points[path[[E,F]]])
            d2 = distance2(points[path[[A,B]]]) + distance2(points[path[[C,E]]]) + distance2(points[path[[D,F]]])
            d3 = distance2(points[path[[A,D]]]) + distance2(points[path[[E,B]]]) + distance2(points[path[[C,F]]])
            d4 = distance2(points[path[[F,B]]]) + distance2(points[path[[C,D]]]) + distance2(points[path[[E,A]]])
            lengthDelta = 0
            if d0 > d1 
                path[i:j-1] .= reverse(path[i:j-1])
                lengthDelta = -d0 + d1
            elseif d0 > d2
                path[j:k-1] .= reverse(path[j:k-1])
                lengthDelta = -d0 + d2
            elseif d0 > d4
                path[i:k-1] .= reverse(path[i:k-1])
                lengthDelta = -d0 + d4
            elseif d0 > d3
                tmp = [j:k-1;i:j-1] 
                path[i:k-1] .= path[tmp]
                lengthDelta = -d0 + d3
            end
            if lengthDelta < 0
                currentLength += lengthDelta
                currentLength < 0 && break
                improvement = true
            end
        end
    end
    path
end

function TSP(data)
    edges,width,height = data
    points = [Tuple(i) for i in edges]
    intial_distance = pathDistance2(points[[1:length(points);]])
    #points = filter(_->rand() < 1,points)
    two_opt_path = two_opt(points)
    push!(two_opt_path,first(two_opt_path))
    lines2::Vector{Tuple{Int64,Int64}} = [(i[2],i[1]) for i in points[two_opt_path]]
    push!(lines2,lines2[1])
    composition = compose(
                    context(units=UnitBox(0,0,width,height)), 
                    (context(), line(lines2), stroke("white"), linewidth(1px))
                    ,(context(), rectangle(), fill("black"))
                  )
    draw(PNG("2opt-tsp.png", (width)px, (height)px), composition)
    two_opt_distance = pathDistance2(points[two_opt_path])
    println("Distance reduction: $(1-two_opt_distance/intial_distance)% (2opt)")

    # Random.seed!(10) 
    # 
    # three_opt_path = three_opt(points3opt)
    # push!(three_opt_path,first(three_opt_path))
    # lines3::Vector{Tuple{Int64,Int64}} = [(i[2],i[1]) for i in points3opt[three_opt_path]]
    # push!(lines3,lines3[1])
    # composition2 = compose(
    #                 context(units=UnitBox(0,0,width,height)), 
    #                 (context(), line(lines3), stroke("white"), linewidth(1px))
    #                 ,(context(), rectangle(), fill("black"))
    #               )
    # draw(PNG("3opt-tsp.png", (width)px, (height)px), composition2)
    # three_opt_intial_distance = pathDistance2(points3opt[[1:length(points3opt);]])
    # three_opt_distance =  pathDistance2(points3opt[three_opt_path])
    # println("Distance reduction: $(1-three_opt_distance/three_opt_intial_distance)% (3opt)")
    # path = two_opt_distance < three_opt_distance ? points[two_opt_path] : points3opt[three_opt_path]
    (points[two_opt_path],width,height)
end

function interpolateData(data,t) 
    lerp(a,b,t) = (b - a) * t + a
    n = length(data)
    t == 1.0 && return data[n]
    subt = (n*t) - trunc(n*t)
    ti = trunc(Int,n*t)
    ti == n-1 && return lerp(data[n-1],data[n],subt)
    lerp(data[ti+1],data[ti+2],subt)
end 

function fourierSeries(data)
    path,width,height = data
    N = length(path)
    dt = 1/N
    println("dt/N:$dt $N")
    Ft = complex.(last.(path)/width,first.(path)/height)
    c = 2500
    dc = 1/c
    Fti = [interpolateData(Ft,t) for t=0:dc:1]   

    fs = fft(Fti) |> FFTView
    fs ./= c
    fs,width,height
end

remap_idx(i::Int) = (-1)^i * floor(Int, i / 2)
remap_inv(n::Int) = 2n * sign(n) - 1 * (n > 0)

function driver(T,Cs,trace,)
    N = length(Cs)
    Czs = [Cs[remap_idx(i)]*cispi(remap_idx(i)*-2*T) for i=1:N]
    Xs = 2 .* real.(Czs)
    Ys = 2 .* imag.(Czs)
    z = 2
    lines = collect(IterTools.partition(accumulate(.+,zip(Xs,Ys)),2,1))

    push!(trace,reduce(.+,zip(Xs,Ys)))
    trace_lines = collect(IterTools.partition(trace,2,1))
    compose(
        context(units=UnitBox(0,0,1z,1z)), 
        (context(),
            line(lines),stroke("grey"), linewidth(2px)),
        (context(),
            line(trace_lines),stroke("yellow"), linewidth(3px)),
        (context(), rectangle(), fill("black")) 
    )

end

function animate(data)
    consts,width,height = data
    scale = 2
    set_default_graphic_size(width * scale * 1px, height * scale * 1px)
    println("Final dimensions: $([width,height].*scale)px")
    time = 30
    trace = []
    film = roll(fps=30, duration=time) do t, dt
        driver(t/time*2,consts,trace)
    end
    write("output.gif", film)
end

function main()
    input_text = "Poggers"
    input_text |> 
    textToImage |> 
    edgeDetection |> 
    edgeSimplification |> 
    TSP |>
    fourierSeries |>
    animate
end

@time main()
