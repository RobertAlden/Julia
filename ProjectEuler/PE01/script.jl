using Curry
range_sum(x) = x * (x+1) / 2
range_multiple_sum(limit, multiple::Integer) = range_sum(limit ÷ multiple) * multiple
f(a,b) = mapreduce(curry(range_multiple_sum)(a), +, b)

function products(A)
    [cumprod(A[i:length(A)]) for i in 1:length(A)-1] |> Iterators.flatten |> collect
end

function main()
    limit = 999
    values = [3, 5]
    prods = setdiff(products(values), values)
    println(mapreduce(curry(f)(limit), -, [values, prods]))
end
@time main()