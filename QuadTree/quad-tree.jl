using Colors, Compose


struct Quad
  x::Integer
  y::Integer
  width::Integer
  height::Integer
  quads::Vector{Quad}
end

struct Point
  x::Integer
  y::Integer
end

function QuadTree(x, y, w, h)
  if w > 8 && h > 8
    newW = w // 2
    newH = h // 2
    q = Quad(x, y, w, h,
      [QuadTree(x + newW, y, newW, newH), # top right
        QuadTree(x, y, newW, newH), # top left
        QuadTree(x, y + newH, newW, newH), # bottom left
        QuadTree(x + newW, y + newH, newW, newH)]) # bottom right
  else
    q = Quad(x, y, w, h, [])
  end
  q
end

function is_inside(q::Quad, p::Point)
  p.x >= q.x && p.x < q.x + q.width &&
    p.y >= q.y && p.y < q.y + q.height
end

function is_inside(x, y, w, h, p::Point)
  p.x >= x && p.x < x + w &&
    p.y >= y && p.y < y + h
end

function get_index(q::Quad, p::Point)
  m = findfirst(is_inside.(q.quads, [p]))
  if !isnothing(m)
    return [m; get_index(q.quads[m], p)]
  end
  []
end

function drawQuad(q::Quad, p::Vector{Point}, l)


  function quadComp(q::Quad, x)
    q.quads == [] && return compose(context(), rectangle(q.x, q.y, q.width, q.height))
    compose(context(units=UnitBox(0, 0, l, l)),
      (context(),
        rectangle(q.x, q.y, q.width, q.height),
        fill("transparent"), stroke("black")),
      (context(),
        quadComp.(q.quads, x + 1),
        fill("transparent"),
        stroke("black"))
    )
  end

  function pointComp(p::Vector{Point})
    colors = HSVA.([0:25:255;], 1, 1, 0.05)
    compose(context(units=UnitBox(0, 0, l, l)),
      (context(),
        circle(
          [point.x for point in p],
          [point.y for point in p], [3]),
        fill("red"),
        stroke("white")
      )
    )
  end

  compose(context(), pointComp(p), quadComp(q, 1))
end

function digits_number(d)::Integer
  v = 0
  for i in d
    if !isnothing(i)
      v = v * 10 + i
    end
  end
  v
end

function query(q, i)
  ref = q
  for x in [string(i)...]
    ref = ref.quads[x]
  end
end

function main()
  l = 128
  set_default_graphic_size(1024px, 1024px)

  q = QuadTree(0, 0, l, l)
  number_of_points = 50
  points = Point.(rand(1:l, number_of_points), rand(1:l, number_of_points))
  indexes = digits_number.(get_index.([q], points))
  spatial_hash = Dict(digits_number(get_index(q, p)) => p for p in points)
  println.(sort(indexes))
  drawQuad(q, points, l)
  #println(spatial_hash)
end

main()