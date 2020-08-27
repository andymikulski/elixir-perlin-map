defmodule PerlinMapWeb.PageLive do
  use PerlinMapWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
      socket
      |> assign(
        world_size: 50,
        resize_factor: 0.5,
        water_height: 0.2,
        offset_x: 0,
        offset_y: 0,
        offset_z: 0,
        water_depth: 4,
        show_tiles: true,
        last_time_us: -1,
        terrain: []
      )
      |> generate_terrain()
    }
  end

  defp generate_terrain(socket) do
    options = [
      resize_factor: socket.assigns.resize_factor,
      offset_x: socket.assigns.offset_x,
      offset_y: socket.assigns.offset_y,
      offset_z: socket.assigns.offset_z,
      width: socket.assigns.world_size,
      height: socket.assigns.world_size
    ]

    # This is just a 'deconstructed' way of calling PerlinMap.TerrainGen.generate_terrain(options)
    {uSecs, terrain} = :timer.tc(PerlinMap.TerrainGen, :generate_terrain, [options])

    socket
    |> assign(:last_time_us, if(uSecs <= 0, do: socket.assigns.last_time_us, else: uSecs))
    |> assign(:terrain, terrain)
  end

  @impl true
  def handle_event("change_settings", %{ "_target" => ["show_tiles"] }, socket) do
    {
      :noreply,
      socket
      |> assign(:show_tiles, !socket.assigns.show_tiles)
    }
  end

  @impl true
  def handle_event("change_settings", %{
    "resize_factor" => input_factor,
    "offset_x" => offset_x,
    "offset_y" => offset_y,
    "offset_z" => offset_z,
    "water_height" => water_height,
    "water_depth" => water_depth,
    "world_size" => world_size
  }, socket) do
    {
      :noreply,
      socket
      |> assign(
        resize_factor: input_factor |> Float.parse() |> elem(0),
        offset_x: offset_x |> Float.parse() |> elem(0),
        offset_y: offset_y |> Float.parse() |> elem(0),
        offset_z: offset_z |> Float.parse() |> elem(0),
        water_height: water_height |> Float.parse() |> elem(0),
        water_depth: water_depth |> Float.parse() |> elem(0),
        world_size: world_size |> Float.parse() |> elem(0) |> trunc())
      |> generate_terrain()
    }
  end




  def render_cell(%{ show_tiles: true } = assigns, {x, y}) do
    index = x + (y * (assigns.world_size))
    terrain_cell = assigns.terrain |> Enum.at(index)
    tile = terrain_cell |> Kernel.*(10) |> trunc()
    is_water? = terrain_cell < assigns.water_height

    amount_underwater = (assigns.water_height - terrain_cell) * assigns.water_depth

    # cell_color = "rgb(#{trunc(terrain_cell / 1 * 255)}, #{trunc(terrain_cell / 1 * 255)}, #{trunc(terrain_cell / 1 * 255)})"
    ~L"""
      <div data-x="<%= x %>" data-y="<%= y %>" class="box tiles-<%= tile %>">
        <%= if is_water? do %><div class="water" style="opacity: <%= amount_underwater %>;"></div><% end %>
      </div>
    """
  end

  def render_cell(assigns, {x, y}) do
    index = x + (y * (assigns.world_size))
    terrain_cell = assigns.terrain |> Enum.at(index)
    cell_color = "rgb(#{trunc(terrain_cell / 1 * 255)}, #{trunc(terrain_cell / 1 * 255)}, #{trunc(terrain_cell / 1 * 255)})"
    ~L"""
      <div data-x="<%= x %>" data-y="<%= y %>" class="box" style="background: <%= cell_color %>"></div>
    """
  end

  @impl true
  def render(assigns) do
    mobile_tile_size = (90 / assigns.world_size) |> Float.round(4)
    mobile_grid_style = "grid-template-columns: repeat(#{assigns.world_size}, #{mobile_tile_size}vw); grid-auto-rows: #{mobile_tile_size}vw;"

    desktop_tile_size = (45 / assigns.world_size) |> Float.round(4)
    desktop_grid_style = "grid-template-columns: repeat(#{assigns.world_size}, #{desktop_tile_size}vw); grid-auto-rows: #{desktop_tile_size}vw;"

    ~L"""
    <div phx-update="ignore">
      <link rel="stylesheet" type="text/css" href="<%= Routes.static_path(@socket, "/sprites/env.css") %>" />
    </div>

    <style type="text/css">
      input { width: 100%; }

      .grid { <%= mobile_grid_style %> }
      @media all and (min-width: 640px){
        .grid { <%= desktop_grid_style %> }
      }

      .grid-container {
        display: flex;
        flex-direction: column-reverse;
      }

      @media all and (min-width: 640px){
        .grid-container {
          flex-direction: row;
        }
        .grid-container > div {
          flex-basis: 50%;
        }
      }
    </style>


    <div class="grid-container">
      <div>
        <div>Last grid calculation took <b><%= @last_time_us %>µs (<%= @last_time_us * 0.001 %> ms)</b></div>

        <form phx-change="change_settings">

          <label>
            Show tiles? <%= @show_tiles %>
            <br />
            <input type="checkbox" <%= if @show_tiles do %>checked<% end %> min="0.05" max="1" step="0.01" name="show_tiles" />
          </label>

          <label>
            World size <%= @world_size %>
            <br />
            <input type="range" value="<%= @world_size %>" min="2" max="100" step="1" name="world_size" />
          </label>

          <label>
            Resize factor <%= @resize_factor %>
            <br />
            <input type="range" value="<%= @resize_factor %>" min="0.05" max="1" step="0.01" name="resize_factor" />
          </label>

          <label>
            Offset x <%= @offset_x %>
            <br />
            <input type="range" value="<%= @offset_x %>" min="-20" max="20" step="1" name="offset_x" />
          </label>

          <label>
            Offset Y <%= @offset_y %>
            <br />
            <input type="range" value="<%= @offset_y %>" min="-20" max="20" step="1" name="offset_y" />
          </label>

          <label>
            Offset Z <%= @offset_z %>
            <br />
            <input type="range" value="<%= @offset_z %>" min="-50" max="50" step="0.01" name="offset_z" />
          </label>

          <label>
            Water Height <%= @water_height %>
            <br />
            <input type="range" value="<%= @water_height %>" min="0" max="1.5" step="0.01" name="water_height" />
          </label>

          <label>
            Water Depth <%= @water_depth %>
            <br />
            <input type="range" value="<%= @water_depth %>" min="0" max="10" step="0.5" name="water_depth" />
          </label>
        </form>

      </div>
      <div>
        <div class="grid">
          <%= for y <- 0..(@world_size - 1), x <- 0..(@world_size - 1) do %>
            <%= render_cell(assigns, { x, y }) %>
          <% end %>
        </div>
      </div>

    </div>
    """
  end
end
