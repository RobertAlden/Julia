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

function distance2(p) 
    a,b = first(p), last(p)
    ax,ay = first(a), last(a)
    bx,by = first(b), last(b)
    (bx - ax)^2 + (by - ay)^2
end

function fitness(genome,points)
    g = points[genome]
    sum(distance2(p) for p ∈ partition(Tuple.(vcat(g,[g[1]])),2,1))
end

function mutation(genome, rate)
    for i in eachindex(genome)
        if rand() < rate
            swap = rand(1:length(genome))
            genome[i], genome[swap] = genome[swap], genome[i]
        end
    end
    genome
end

function TSP(img)
    # genetic algorithm
    Random.seed!(10) #random seed

    points = findall(x->x === RGB(1,1,1), img)
    points = filter(_->rand() < 0.05,points)
    N = length(points)
    println(N)

    fitnessFunction = x -> fitness(x,points)
    startLength = fitnessFunction([1:N;])
    currentLength = startLength
    path = [1:N;]
    improvement = true
    while improvement
        improvement = false
        for i=1:N-1, j=i+1:N
            lengthDelta = (-distance2(Tuple.(points[path[[i,i+1]]])) -
                            distance2(Tuple.(points[path[[j,j+1]]])) +
                            distance2(Tuple.(points[path[[i,j]]]))   +
                            distance2(Tuple.(points[path[[i+1,j+1]]])))
            if lengthDelta > 0
                path[i:j] .= reverse(path[i:j])
                currentLength += lengthDelta
                improvement = true
            end
        end
    end

    lines::Vector{Tuple{Int64,Int64}} = [(i[2],i[1]) for i in points[final]]
    push!(lines,lines[1])
    composition = compose(
                    context(units=UnitBox(0,0,352,64)), 
                    (context(), line(lines), stroke("white"), linewidth(1px))
                    #,(context(), rectangle(), fill("white"))
                  )
    draw(PNG("lines.png", 352px, 64px), composition)
    println("Distance reduction: $(trunc((1-fitnessFunction(final)/initial)*100))%")
    img 
end

function fourierSeries(img)
    # note: Cn = ∫01 ℯ^(-2πιnt) f(t)dt
    #average points
    img 
end

function animate(img)
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
