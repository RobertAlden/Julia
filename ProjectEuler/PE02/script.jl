# fibonacci(n) = n <= 2 ? 1 : fibonacci(n - 2) + fibonacci(n - 1)
function fibonacci(x) 
    a, b = 0, 1
    for i in 1:x
        a, b = a + b, a
    end 
    a
end

function main()
    for i in 1:10
        println(i, ' ', fibonacci(i)) 
    end
end
@time main()