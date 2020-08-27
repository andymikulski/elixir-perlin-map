defmodule PerlinMap.TerrainGen do
  def generate_terrain(options) do
    # `options` under the hood comes in looking like [{:width, 123}, {:height, 123}, {:resize_factor, 1}, ...]
    # but the Keyword module lets us pick the values easily, as well as provides a default value fallback
    width = options |> Keyword.get(:width, 1)
    height = options |> Keyword.get(:height, 1)
    resize_factor = options |> Keyword.get(:resize_factor, 1)
    offset_x = options |> Keyword.get(:offset_x, 0)
    offset_y = options |> Keyword.get(:offset_y, 0)
    offset_z = options |> Keyword.get(:offset_z, 0)


    # The "adjusted" dimensions dictate how 'zoomed' the perlin noise appears
    adjusted_width = width * resize_factor
    adjusted_height = height * resize_factor


    # Loops through (0,0) -> (width - 1, height - 1)
    # for(let y = 0; y <= height - 1; y++){
    #   for(let y = 0; y <= height - 1; y++){
    #     // calculate perlin noise value here
    #   }
    # }
    for y <- 0..(height - 1), x <- 0..(width - 1) do
      # Create a tuple with the x/y/z coords for this point
      {
        (x + offset_x) / adjusted_width,
        (y + offset_y) / adjusted_height,
        offset_z
      }
      # Get the perlin noise value (between -0.5 and 0.5)
      |> PerlinNoise.noise()
      # Normalize the value to be between 0 and 1
      |> Kernel.+(0.5)
      # For some reason there are occasionally values over 1 and under 0,
      # so I clamp it with `min/max` to be safe.
      |> min(1)
      |> max(0)
    end
  end
end