using AbbreviatedStackTraces
using Genie, FileIO
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
    gif = Text2FFT.text2fft(word, terms, precision)
    gif::String = Text2FFT.text2fft(word, terms, precision)
    gif_data = base64encode(read(gif, String))
    html(response, data=gif_data)
end

up()