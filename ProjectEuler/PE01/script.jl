using Curry
using Base.Iterators
range_sum(x) = x * (x+1) / 2
range_multiple_sum(limit::Integer, multiple::Integer) = range_sum(limit ÷ multiple) * multiple
f(a,b) = mapreduce(curry(range_multiple_sum)(a), +, b)

function products(A)
    ([cumprod(A[i:length(A)]) for i in 1:length(A)-1] 
    |> flatten 
    |> collect)
end

function main()
    limit = 999
    values = [3, 5]
    prods = setdiff(products(values), values)
    mapreduce(curry(f)(limit), -, [values, prods])
end
@time main()