using AbbreviatedStackTraces
using Genie, Genie.Router
using Genie.Renderer, Genie.Renderer.Html, Genie.Renderer.Json
using Base64, FileIO


form = """
<form action="/" method="POST" enctype="multipart/form-data">
  <label for="dataFile">Input Text: </label><input type="text" name="word" />
  <br/><input type="submit" value="Fourier this text!" />
</form>
"""

route("/") do
  html(form)
end

route("/", method = POST) do
  data = base64encode(read("test.gif", String))
  html("""<img src="data:image/gif;base64,$data">""")
end

up()