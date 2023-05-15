using HTTP, Gumbo, AbstractTrees


function main()
    stringlist = []
    file = open("./spotifyURIconverter/songtitles.txt","a")
    @async for link in readlines("spotifyURIconverter/spotifylinks.txt")
        response = HTTP.request("GET", link)
        body = response.body |> String
        r_parsed = parsehtml(body)
        for elem in PreOrderDFS(r_parsed.root)
            try
                if tag(elem) == :title
                    title::String = string(AbstractTrees.children(elem)[1])
                    println(title)
                    push!(stringlist,title)
                end
            catch
                # Nothing needed here
            end
        end
    end
    [write(file, str * '\n') for str in stringlist]
end

main()

