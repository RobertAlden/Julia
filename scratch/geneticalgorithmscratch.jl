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

function reproduction(population, elites, mutationRate, fitnessFunction)
    evaluatedPopulation = 1 ./ fitnessFunction.(population)
    normalizedPopulation = evaluatedPopulation ./ sum(evaluatedPopulation)
    newPopulation = sort(population, by=x->fitnessFunction(x))[1:elites]
    n = length(population) - elites
    for i=1:n  
        parent1 = selection(normalizedPopulation)
        parent2 = selection(normalizedPopulation)
        offspring = orderedCrossover(population[parent1], population[parent2])
        offspring = mutation(offspring, mutationRate)
        push!(newPopulation,offspring)
    end
    newPopulation
end

function selection(p)
    while true
        limit = rand()
        x = rand(1:length(p))
        limit < p[x] && return x
    end
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

function orderedCrossover(g1, g2)
    spliceEnd = rand(2:(length(g1)-1))
    spliceBegin = rand(1:spliceEnd)
    splice = g1[spliceBegin:spliceEnd]
    rest = filter(x->x∉splice,g2)
    #println((length(splice),length(rest),(length([splice;rest]))),(length(g1),length(g2))) 
    [rest[1:spliceBegin]; splice; rest[spliceBegin+1:length(rest)];]
end

function TSP(img)
    # genetic algorithm
    Random.seed!(10) #random seed
    mutationRate = 0.00001
    iterations = 500
    numIndividuals = 50
    numElites = 5

    points = findall(x->x === RGB(1,1,1), img)
    points = filter(_->rand() < 0.05,points)
    println(length(points))

    fitnessFunction = x -> fitness(x,points)

    initial = fitnessFunction([1:length(points);])
    
    population = [[1:length(points);] for i=1:numIndividuals]
    for i=1:iterations
        mutationRate *= 1 - (1/iterations)
        population = reproduction(population, numElites, mutationRate, fitnessFunction)
    end
    final = first(sort(population, by=fitnessFunction))
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