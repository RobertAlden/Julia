using AbbreviatedStackTraces
using Colors, ColorVectorSpace, FileIO

function mandle(p::Complex,iterations::Integer)
    z = complex(0,0)
    iters = iterations
    for i=0:iters-1
        z = z^2 + p
        if abs2(z) > 4
            return i/iters
        end
    end
    1
end

function interpolateData(data,in_t) 
    lerp(a,b,t) = (b - a) * t + a
    n = length(data)
    t = in_t * n
    t == n && return data[n]
    subt = (t) - trunc(t)
    ti = trunc(Int,t)
    ti == n-1 && return lerp(data[n-1],data[n],subt)
    lerp(data[ti+1],data[ti+2],subt)
end 

function driver(x_off,y_off,dim,frames)
    iterations = 250
    grid = [mandle(complex(x/dim*(1-t/frames)+x_off,y/dim*(1-t/frames)+y_off),iterations) 
        for x=-dim+1:dim, y=-dim+1:dim, t=1:frames]
    color_range = [colorant"black", colorant"red"]
    [interpolateData(color_range,t) for t in grid]
end

function main()
    film = driver(-0.741,.21,64,300)
    FileIO.save("output.gif", film, fps=15)
end

@time main()