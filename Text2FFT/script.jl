module Text2FFT
export txt2fft, img2fft

using Compose, Colors, Reel, FileIO, ImageFiltering, Images, ImageEdgeDetection, Match, FFTW, FFTViews
using ImageEdgeDetection: Percentile
import Cairo, Fontconfig

using Random, IterTools

function textToImage(txt::String)
    code = string(sum(Int(c)*1493621697 for c in txt) % 121391351)
    filename = "$code-text.png"
    width = (32*length(txt))

    text_composition = compose(context(),
    (context(), 
    Compose.text(0.5,0.5,txt,hcenter,vcenter),
        fontsize(50px), stroke("red"), font("Fira Code Light")),
    (context(), rectangle(),fill("white"))
    )
    draw(PNG(filename,(width)px, 72px),text_composition)
    data = FileIO.load(filename)
    rm(filename)
    data
end

function edgeDetection(img::Matrix{RGB{N0f8}},scale,h,l)
    alg = Canny(spatial_scale=scale, high=Percentile(h), low=Percentile(l))
    detect_edges(img, alg)
end

function edgeSimplification(img::Matrix{RGB{N0f8}})
    height,width = size(img)
    points = findall(x->x === RGB(1,1,1), img)
    field = zeros(Int,height,width)
    field[points] .= 1
    r = 1
    region = -r:r
    mask1 = [0 1 0; 0 1 0; 0 1 0]
    mask2 = [1 0 0; 0 1 0; 0 0 1]
    mask3 = [1 0 0; 0 1 0; 0 1 0]
    masks = [mask1,mask1',mask2,reverse(mask2),mask3, mask3',reverse(mask3)']
    @views for x=r+1:width-r, y=r+1:height-r
        area = field[y.+region, x.+region]
        if any(masks .== [area]) || sum(area) >= 3 
            field[y,x] = 0
        end
    end
    findall(x->x == 1, field)
end

function distance2(ab) 
    ((ax,ay),(bx,by)) = ab
    (ax-bx)^2 + (ay-by)^2
end

function twoOpt(points::Vector{Tuple{Int,Int}})
    N = length(points)
    path = [1:N;]
    improvement = true
    @inbounds @views while improvement
        improvement = false
        for u=0:N-2, v=u+1:N-1
            i = u + 1
            j = v + 1
            AC = points[path[[i,mod1(i+1,N)]]]
            BD = points[path[[j,mod1(j+1,N)]]]
            AB = points[path[[i,j]]]
            CD = points[path[[mod1(i+1,N),mod1(j+1,N)]]]
            ACBD = (distance2(AC) + distance2(BD))
            ABCD = (distance2(AB) + distance2(CD))
            if -ACBD + ABCD < 0
                path[i+1:j] .= reverse(path[i+1:j])
                improvement = true
            end
        end
    end
    path
end

# function three_opt(points)
#     N = length(points)
#     path = [1:N;]
#     startLength = pathDistance2(points[path])
#     currentLength = startLength
#     improvement = true
#     @inbounds @views while improvement
#         improvement = false
#         for u=1:N-1, v=u+2:N-1, w=v+2:N
#             i = u + 1
#             j = v + 1
#             k = w + 1
#             A,B,C,D,E,F = i-1,i,j-1,j,k-1,mod1(k,N)
#             d0 = distance2(points[path[[A,B]]]) + distance2(points[path[[C,D]]]) + distance2(points[path[[E,F]]])
#             d1 = distance2(points[path[[A,C]]]) + distance2(points[path[[B,D]]]) + distance2(points[path[[E,F]]])
#             d2 = distance2(points[path[[A,B]]]) + distance2(points[path[[C,E]]]) + distance2(points[path[[D,F]]])
#             d3 = distance2(points[path[[A,D]]]) + distance2(points[path[[E,B]]]) + distance2(points[path[[C,F]]])
#             d4 = distance2(points[path[[F,B]]]) + distance2(points[path[[C,D]]]) + distance2(points[path[[E,A]]])
#             lengthDelta = 0
#             if d0 > d1 
#                 path[i-1:j-1] .= reverse(path[i-1:j-1])
#                 lengthDelta = -d0 + d1
#             elseif d0 > d2
#                 path[j-1:k-1] .= reverse(path[j-1:k-1])
#                 lengthDelta = -d0 + d2
#             elseif d0 > d4
#                 path[i-1:k-1] .= reverse(path[i-1:k-1])
#                 lengthDelta = -d0 + d4
#             elseif d0 > d3
#                 tmp = [j-1:k-1;i-1:j-1] 
#                 path[i-1:k-1] .= path[tmp]
#                 lengthDelta = -d0 + d3
#             end
#             if lengthDelta < 0
#                 currentLength += lengthDelta
#                 currentLength < 0 && break
#                 improvement = true
#             end
#         end
#     end
#     path
# end

function TSP(edges::Vector{CartesianIndex{2}})
    points = [Tuple(i) for i in edges]
    twoOptPath = twoOpt(points)
    push!(twoOptPath,first(twoOptPath))
    points[twoOptPath]
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

function fourierSeries(path::Vector{Tuple{Int, Int}},circles::Int,width::Int,height::Int)
    N = length(path)
    dt = 1/N
    Ft = complex.(last.(path)/width,first.(path)/height)
    c = circles
    dc = 1/c
    Fti = [interpolateData(Ft,t) for t=0:dc:1]   
    fs = fft(Fti) |> FFTView
    fs ./= c
    fs
end

remap_idx(i::Int) = (-1)^i * floor(Int, i / 2)

function driver(T,DT,target_dt,Cs,trace)
    N = length(Cs)

    Czs = [Cs[remap_idx(i)]*cispi(remap_idx(i)*-2*T) for i=1:N]
    lines = collect(IterTools.partition(accumulate(.+,zip(real.(Czs),imag.(Czs))),2,1))

    for time=T:DT/target_dt:T+DT
        Czs = [Cs[remap_idx(i)]*cispi(remap_idx(i)*-2*time) for i=1:N]
        tsub = reduce(.+,zip(real.(Czs),imag.(Czs)))
        push!(trace,tsub)
    end
    trace_lines = collect(IterTools.partition(trace,2,1))
    compose(
        context(), 
        (context(),
            Compose.line(lines),stroke("red"), linewidth(1px)),
        (context(),
            Compose.line(trace_lines),stroke("yellow"), linewidth(1px)),
        (context(), rectangle(), fill("black")) 
    )

end

function animate(consts,intermediate_frames,dur,width,height)
    scale = 1
    set_default_graphic_size(width * scale * 1px, height * scale * 1px)
    println("Final dimensions: $([width,height].*scale)px")
    rate = 2
    target_dt = intermediate_frames
    trace = []
    film = roll(fps=30, duration=dur) do t, dt
        driver((t/dur)*rate,(dt/dur),target_dt,consts,trace)
    end
    println("Calcuated $(length(trace)) values in total.")
    film
end

function txt2fft(input_text::String, terms::Integer, subvalues::Integer)
    input_text = input_text
    terms = terms
    subvalues = subvalues
    blur = 2
    time = 10

    img = textToImage(input_text)
    height,width = size(img)
    p3 = edgeDetection(img,blur,80,60) |> edgeSimplification |> TSP 
    p4 = fourierSeries(p3,terms,width,height)
    p5 = animate(p4,subvalues,time,width,height)
    filename = "$input_text-output.gif"
    write(filename, p5)
    "$filename"
end

function img2fft(img::Matrix{RGB{N0f8}}, filename::String, terms::Integer, subvalues::Integer)
    input_text = filename
    terms = terms
    subvalues = subvalues
    blur = 2
    time = 10

    height,width = size(img)
    p3 = edgeDetection(img,blur,80,60) |> edgeSimplification |> TSP 
    p4 = fourierSeries(p3,terms,width,height)
    p5 = animate(p4,subvalues,time,width,height)
    filename = "$input_text-output.gif"
    write(filename, p5)
    "$filename"
end

end