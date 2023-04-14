using Base.Filesystem


function main()
    s = readlines("ProjectEuler\\PE13\\input.txt")
    sum([parse(BigInt, i) for i in s])
end
main()