using IterTools


function produceNext(input::String, dict::Dict, tokenLength::Int)
    str = length(input) > tokenLength ? last(input,tokenLength) : input
    relevantKeys = [ k for k in keys(dict) if startswith(k,str)]
    rand([(collect(dict[key] for key in relevantKeys)...)...])
end

function markovMap(text::String,tokenLength::Int)
    tokens = collect.(collect(IterTools.partition(text,tokenLength)))
    tokenGroups = collect.(collect(IterTools.partition(join.(tokens),2)))
    D = Dict()
    for (k,v) in tokenGroups
        !haskey(D,k) && (D[k] = [])
        push!(D[k],v)
    end
    D
end

function main()
    text = join(readlines("markov-goober/raw-text.txt"))
    context = 35
    map = markovMap(lowercase(text), context)
    output = ""
    for i=1:50
        output *= produceNext("", map, context)
    end
    output
end
    

@show main()