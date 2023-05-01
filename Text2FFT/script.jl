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

function fitness(genome)
    sum(distance2(p) for p in partition(Tuple.(vcat(genome,[genome[1]])),2,1))
end

function reproduction(population, elites)
    evaluatedPopulation = 1 ./ fitness.(population)
    normalizedPopulation = evaluatedPopulation ./ sum(evaluatedPopulation)
    newPopulation = sort(population,rev=true)[1:elites]
    n = length(population) - elites
    for i=1:n  
        parent1 = selection(normalizedPopulation)
        parent2 = selection(normalizedPopulation)
        offspring = orderedCrossover(population[parent1], population[parent2])
        offspring = mutation(offspring,0.05)
        push!(newPopulation,offspring)
    end
    newPopulation
end

function selection(p)
    limit = 1
    x = 1
    while limit > 0 
        x = rand(1:length(p))
        limit -= p[x]
    end
    x
end

function mutation(genome, rate)
    genome
end

function orderedCrossover(g1, g2)
    spliceEnd = rand(2:length(g1))
    spliceBegin = rand(1:spliceEnd)
    splice = g1[spliceBegin:spliceEnd]
    rest = [ i for i ∈ g2 if i ∉ splice]
    [rest[1:spliceBegin]; splice; rest[spliceEnd:(length(g1)-(spliceEnd-spliceBegin+1))];]
end

function TSP(img)
    # genetic algorithm
    Random.seed!(10) #random seed
    iterations = 5
    numIndividuals = 5
    numElites = 1

    points = shuffle(findall(x->x === RGB(1,1,1), img))
    initial = fitness(points)
    population = [shuffle([1:length(points);]) for i=1:numIndividuals]
    for i=1:iterations
        population = reproduction(population, numElites)
    end
    final = last(sort(fitness.(population)))
    println("Before: $initial, After: $final")
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
