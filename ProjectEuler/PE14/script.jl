collatz(n, i=0) = n == 1 ? i : n % 2 == 0 ? collatz(n/2, i+1) : collatz((3n+1)/2, i+2)

function main()
    collatz.([1:10^6;]) |> findmax
end
main()

@time main()