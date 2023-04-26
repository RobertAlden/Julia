using Match
using Compose, Colors, Reel, FileIO, ImageFiltering, Images, ImageEdgeDetection
using ImageEdgeDetection: Percentile
import Cairo, Fontconfig

rgbToGrey(rgb::RGB) = 0.299 * rgb.r + 0.587 * rgb.g + 0.114 * rgb.b
greyToRGB(f) = RGB(f,f,f)

function textToImage(txt)
    text_composition = compose(context(),
    (context(), 
        text(0.5,0.6,txt,hcenter,vcenter),
        fontsize(55px), stroke("red"), font("consolas")),
    (context(), rectangle(),fill("white"))
    )
    draw(PNG("text.png",(32*length(txt))px, 64px),text_composition)
    FileIO.load("text.png")
end

function edgeDetection(img)
    alg = Canny(spatial_scale=2, high=Percentile(80), low=Percentile(70))
    detect_edges(img, alg)
end

function edgeSimplification(img)
    # TODO: try finding derivatives of parametric functions defining each letter and
    # remove regions of constant derivative 
    # if thats too hard, remove pixels randomly/ use a kernel that finds linear sections and 
    # leaves only endpoints
    img
end



function TSP(img)
    # genetic algorithm
    fitness(genome) = inds = Tuple.(genome); first.(inds).^2 .+ last.(inds).^2
    points = Tuple.(findall(x->x === RGB(1,1,1), img))
    println(points)
    img 
end

function fourierSeries(img)
    # note: Cn = ∫01 ℯ^(-2πιnt) f(t)dt
    #average points
    img 
end

function animate(img)
    img 
end

function main()
    input_text = "hello world"
    input_text |> 
    textToImage |> 
    edgeDetection |> 
    edgeSimplification |> 
    TSP |>
    fourierSeries |>
    animate |>
    FileIO.save("out.png")
end

@time main()