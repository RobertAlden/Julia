using AbbreviatedStackTraces
using Genie, FileIO, Images
using Genie.Router, Genie.Renderer.Html, Genie.Renderer.Json, Genie.Requests
using Base64

include("../Text2FFT/script.jl")
using .Text2FFT

# landing page
route("/", method=GET) do
    response = join(readlines("copilot-test/index.html"))
    html(response)
end

# about page
route("/about", method=GET) do
    response = join(readlines("copilot-test/about.html"))
    html(response)
end

# route for Fourier toy
route("/fourier", method=GET) do
    response = join(readlines("copilot-test/fourier.html"))
    html(response, data = "")
end

# handle response from Fourier toy
route("/fourier", method = POST) do
    response = join(readlines("copilot-test/fourier.html"))
    word = postpayload(:word, "null")
    terms = parse(Int, postpayload(:terms, "100"))
    precision = parse(Int, postpayload(:precision, "5"))
    if infilespayload(:userFile)
        userFile = filespayload(:userFile)
        data::Vector{UInt8} = userFile.data
        img = Images.load(IOBuffer(data))
        gif = Text2FFT.img2fft(img, userFile.name, terms, precision)
    else    
        gif = Text2FFT.txt2fft(word, terms, precision)
    end
    html(response, data=base64encode(read(gif, String)))
end

up()