
range_sum(x) = x * (x+1) / 2
range_multiple_sum(limit, multiple::Integer) = range_sum(limit ÷ multiple) * multiple
f(a,b) = mapreduce(x->range_multiple_sum(a, x), +, b)

function products(A)
    if 2:length(A) == 1 
        return A
    end
    vcat([ Iterators.partition(A,i) for i in 2:length(A) ]...) |> collect
end

function main()
    limit = 999
    values = [3, 5, 10]
    prods = setdiff(products(values), values, values.^2)
    println(mapreduce(x->f(limit,x), -, [values, prods]))
end
@time main()