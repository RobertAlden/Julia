# using Genie to set up a simple website
using Genie, FileIO
using Genie.Router, Genie.Renderer.Html, Genie.Renderer.Json
using Base64
# import render function from Genie.Renderer.Html

# landing page
route("/", method=GET) do
    # load the html file as string
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
    html(response)
end

up()