using Genie, Genie.Renderer.Html, Genie.Requests, Genie.Router
using Base64, FileIO


form = """
<form action="/fourier" method="POST" enctype="multipart/form-data">
  <input type="text" name="word" value="" placeholder="Enter a word you want to turn into a gif." />
  <input type="submit" value="Fourier Me!" />
</form>
"""

route("/") do
  html(form)
end

route("/fourier", method=POST) do
    pwd() * "\\Text2FFT\\public\\4645-output.gif"
end
  
down()
up()