using Compose, Colors, Reel, IterTools
import Cairo, Fontconfig


points_to_line(points) = collect(partition(accumulate(.+,points),2,1))

function driver(t)
    composition = recursed(2,2)  
end

function recursed(n,depth)
    depth == 1 && return compose(context(-1,-1,1,1),circle(),fill("blue"))
    leaf = recursed(n,depth-1)
    compose(context(), [(context(i/n,k/n,1/n,1/n),leaf) for i = 1:n, k = 1:n]...)
end

function main()
    dim = 512px
    set_default_graphic_size(dim, dim)
    colors = distinguishable_colors(20)
    n = 2
    composition = compose(context(),recursed(2,3)...)
    draw(SVG("output.svg",dim,dim), composition)

end

main()