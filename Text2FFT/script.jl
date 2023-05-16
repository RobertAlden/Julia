using Compose, Colors, Reel, FileIO, ImageFiltering, Images, ImageEdgeDetection, Match, AbbreviatedStackTraces, FFTW, FFTViews
using ImageEdgeDetection: Percentile
import Cairo, Fontconfig

# webapp stuff
using AbbreviatedStackTraces
using Genie, Base64
using Genie.Router, Genie.Requests, Genie.Renderer, Genie.Renderer.Html, Genie.Renderer.Json

using Random, IterTools

function textToImage(txt)
    code = string(sum(Int(c)*932931 for c in txt) % 10000)
    header = "output-$code"
    tag = "$header/$code"
    filename = "$tag-text.png"
    width = (32*length(txt))
    #isfile(filename) && return (tag,FileIO.load(filename)),(width,72)

    text_composition = compose(context(),
    (context(), 
    Compose.text(0.5,0.5,txt,hcenter,vcenter),
        fontsize(50px), stroke("red"), font("Fira Code Light")),
    (context(), rectangle(),fill("white"))
    )
    isdir(header) || mkdir(header)
    draw(PNG(filename,(width)px, 72px),text_composition)
    (tag,FileIO.load(filename)),(width,72)
end

function edgeDetection(tag,img,scale,h,l)
    alg = Canny(spatial_scale=scale, high=Percentile(h), low=Percentile(l))
    res = detect_edges(img, alg)
    FileIO.save("$tag-edge.png", res)
    res
end

function edgeSimplification(img,tag)
    filename = "$tag-edge-simple.png"
    height,width = size(img)
    #isfile(filename) && return findall(map(x->x==RGB(1,1,1),FileIO.load(filename)))
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
    FileIO.save(filename, map(x->RGB(x,x,x),field))
    findall(x->x == 1, field)
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

function TSP(edges,tag,width,height)
    points = [Tuple(i) for i in edges]
    two_opt_path = two_opt(points)
    push!(two_opt_path,first(two_opt_path))
    lines2::Vector{Tuple{Int64,Int64}} = [(i[2],i[1]) for i in points[two_opt_path]]
    push!(lines2,lines2[1])
    composition = compose(
                    context(units=UnitBox(0,0,width,height)), 
                    (context(), Compose.line(lines2), stroke("white"), linewidth(1px))
                    ,(context(), rectangle(), fill("black"))
                  )
    draw(PNG("$tag-2opt-tsp.png", (width)px, (height)px), composition)
    points[two_opt_path]
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

function fourierSeries(path,circles,width,height)
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

function process(input_text::String, terms::Integer, subvalues::Integer)
    input_text = input_text
    terms = terms
    subvalues = subvalues
    blur = 2
    time = 10

    ((tag,img),(width,height)) = textToImage(input_text)
    p1 = edgeDetection(tag,img,blur,80,60)
    p2 = edgeSimplification(p1,tag)
    p3 = TSP(p2,tag,width,height) 
    p4 = fourierSeries(p3,terms,width,height)
    p5 = animate(p4,subvalues,time,width,height)
    filename = "$tag-output.gif"
    write(filename, p5)
    "$filename"
end

form = """
<form action="/" method="POST" enctype="multipart/form-data">
    <label for="word">Input Text: </label><input type="text" name="word" /><br>
    <label for="terms">Epicycle #: </label>
    <input type="number" name="terms" min="1" max="1000"><br>
    <label for="terms">Precision: </label>
    <input type="number" name="precision" min="1" max="100"><br>
    <br/><input type="submit" value="Fourier this text!" />
</form>
"""

route("/") do
    html(form)
end

route("/", method = POST) do
    word = postpayload(:word, "null")
    terms = parse(Int, postpayload(:terms, "100"))
    precision = parse(Int, postpayload(:precision, "5"))
    gif::String = process(word, terms, precision)
    data = base64encode(read(gif, String))
    results = """<br><label></label><img src="data:image/gif;base64,$data">"""
    html(form * results)
end

up(8000, "127.0.0.1")