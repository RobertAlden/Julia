using Mousetrap

function step(world)
  rotations = [circshift(world, (x, y)) for x ∈ -1:1, y ∈ -1:1]
  world .= sum(rotations) .∈ [3:4]
end

function applyn(f, x, n)
  results = [x]
  for i in 1:n
    val = f(results[end])
    push!(results, val)
  end
  results
end

lerp(v, OldMin, OldMax, NewMin, NewMax) = (((v - OldMin) * (NewMax - NewMin)) / (OldMax - OldMin)) + NewMin



main() do app::Application
  shader = Shader()
  # compile fragment shader
  create_from_string!(
    shader,
    SHADER_TYPE_FRAGMENT,
    """
    #version 330
        
    in vec4 _vertex_color;
    in vec2 _texture_coordinates;
    in vec3 _vertex_position;

    out vec4 _fragment_color;

    void main()
    {
        vec2 pos = _vertex_position.xy;
        _fragment_color = vec4(pos.y, dot(pos.x, pos.y), pos.x, 1);
    }
""")

  render_area = RenderArea()
  frame = Frame()
  size = (64, 64)
  world_scale = 16
  set_size_request!(frame, Vector2f((size .* world_scale)...))
  percent = 0.15
  world = percent .< reshape(rand(Float64, size), size)
  frame_skip = 5
  frame_count = 0
  set_tick_callback!(frame) do clock::FrameClock
    frame_count = frame_count + 1
    if frame_count == frame_skip
      frame_count = 0
      world = step(world)
      scaled_world = repeat(world, inner=(world_scale, world_scale))
      clear_render_tasks!(render_area)
      points = Points([Vector2f(lerp(p[1], 0, size[1] * world_scale, -1.0, 1.0), lerp(p[2], 0, size[2] * world_scale, -1.0, 1.0)) for p ∈ findall(scaled_world)])
      add_render_task!(render_area, RenderTask(points; shader=shader))
      queue_render(render_area)
    end

    # continue callback indefinitely
    return TICK_CALLBACK_RESULT_CONTINUE
  end

  set_child!(frame, render_area)
  click_controller = ClickEventController()

  function on_click_pressed(self::ClickEventController, n_presses::Integer, x::AbstractFloat, y::AbstractFloat)
    if n_presses == 1 && get_current_button(self) == BUTTON_ID_BUTTON_01
      world[trunc(Integer, x)÷world_scale, trunc(Integer, y)÷world_scale] = 1
    end
  end

  connect_signal_click_pressed!(on_click_pressed, click_controller)

  window = Window(app)
  set_child!(window, frame)
  add_controller!(window, click_controller)
  present!(window)
end
