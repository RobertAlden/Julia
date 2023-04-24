using AbbreviatedStackTraces, Infiltrator
using Compose, Colors, Reel, FileIO, ImageFiltering
import Cairo, Fontconfig

rgbToGrey(rgb::RGB) = 0.299 * rgb.r + 0.587 * rgb.g + 0.114 * rgb.b
greyToRGB(f) = RGB(f,f,f)
threshold(x,tl,th) = x > tl ? (x < th ? x : 1) : 0

function nonMaximumSuppression(m_dir, m_mag)

end

function quantize(n,start,stop,v)
    dist = stop - start
    width = (dist / v)
    round(Integer, n / width) * dist
end

function textToImage(txt)
    text_composition = compose(context(),
    (context(), 
        text(0.5,0.6,txt,hcenter,vcenter),
        fontsize(55px), stroke("black"), font("consolas")),
    (context(), rectangle(),fill("white"))
    )
    draw(PNG("text.png",(32*length(txt))px, 64px),text_composition)
    data = FileIO.load("text.png")
    round.(rgbToGrey.(data))
end

function edgeDetection(im)
    G = 1/159 .* [2 4 5 4 2; 4 9 12 9 4; 5 12 15 12 5; 4 9 12 9 4; 2 4 5 4 2]
    I₀ = imfilter(im,G)
    K = [1 0 -1; 2 0 -2; 1 0 -1]
    Iᵢ = imfilter(I₀, K)
    Iₖ = imfilter(I₀, K')
    Iᵢₖ = @. √(Iᵢ^2 + Iₖ^2)
    Iₐ = @. atan(Iₖ/Iᵢ)
    Iᵩ = quantize.(Iₐ,0,2π,8)
    Iₙₘ = nonMaximumSuppression(Iᵢₖ, Iᵩ)
    Iₜ = threshold.(Iₙₘ,0.99,1)
    greyToRGB.(Iₜ)
end

function main()
    input_text = "hello world"
    input_text |> textToImage |> edgeDetection |> FileIO.save("out.png")
end

main()