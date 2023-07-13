# This was copied directly from `phoenix_live_dashboard`
Logger.configure(level: :debug)

# Configures the endpoint
Application.put_env(:live_flow, LiveFlow.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Hu4qQN3iKzTV4fJxhorPQlA/osH9fAMtbtjVS58PFgfw3ja5Z18Q/WSNR9wP4OfW",
  live_view: [signing_salt: "hMegieSe"],
  http: [port: System.get_env("PORT") || 4000],
  debug_errors: true,
  check_origin: false,
  pubsub_server: Demo.PubSub,
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:default, ~w(--watch)]}
  ],
  live_reload: [
    patterns: [
      ~r"dist/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/phoenix/live_dashboard/(live|views)/.*(ex)$",
      ~r"lib/phoenix/live_dashboard/templates/.*(ex)$"
    ]
  ]
)

defmodule LiveFlow.ExampleNode do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
    <div class="w-full h-full bg-blue-500 text-center select-none">
    <p>
      Hello! Drag me!
    </p>

    <p>
      Id: <%= @node.id %>
    </p>
    <p>
      Position: <%= @node.position.x %>, <%= @node.position.y %>
    </p>
    </div>
    """
  end
end

defmodule LiveFlow.HomeLive do
  use Phoenix.LiveView

  @impl true
  def mount(_params, _, socket) do
    nodes = [
      %LiveFlow.Node{
        component: LiveFlow.ExampleNode,
        handles: [
          %LiveFlow.Node.Handle{location: :bottom, id: "bottom-of-1"},
          ],
        id: "1",
        position: %LiveFlow.Node.Position{
          height: 150,
          width: 150,
          x: 0,
          y: 0
        }
      },
      %LiveFlow.Node{
        component: LiveFlow.ExampleNode,
        handles: [%LiveFlow.Node.Handle{location: :top, id: "top-of-2"}],
        id: "2",
        position: %LiveFlow.Node.Position{
          height: 150,
          width: 150,
          x: 0,
          y: 200
        }
      }
    ]

    edges = [
      %LiveFlow.Edge{
        from: "bottom-of-1",
        to: "top-of-2",
        id: "1-to-2"
      }
    ]

    {:ok, assign(socket, nodes: nodes, edges: edges)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en" class="[scrollbar-gutter:stable]">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={Phoenix.Controller.get_csrf_token()} />
        <link phx-track-static rel="stylesheet" href={"/assets/app.css"} />
        <script defer phx-track-static type="text/javascript" src={"/assets/app.js"}>
        </script>
      </head>
      <body class="bg-white antialiased">
        <.live_component id="flow-example" module={LiveFlow} nodes={@nodes} edges={@edges} on_move={&move/2} />
      </body>
    </html>
    """
  end

  defp move(id, position) do
    send(self(), {:move, id, position})
  end

  def handle_info({:move, id, %{"x" => x, "y" => y}}, socket) do
    {:noreply, assign(socket, nodes: update_node(socket.assigns.nodes, id, fn node ->
      %{node | position: %{node.position | x: x, y: y}}
    end))}
  end

  defp update_node(nodes, id, func) do
    Enum.map(nodes, fn %{id: ^id} = node ->
      func.(node)
      node ->
        node
    end)
  end
end

defmodule LiveFlow.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :fetch_session
    plug :protect_from_forgery
  end

  scope "/" do
    pipe_through :browser
    live "/", LiveFlow.HomeLive, :index
  end
end

defmodule LiveFlow.Endpoint do
  use Phoenix.Endpoint, otp_app: :live_flow

  @session_options [
    store: :cookie,
    key: "_live_view_key",
    signing_salt: "/VEDsdfsffMnp5",
    same_site: "Lax"
  ]

  plug Plug.Static,
    at: "/",
    from: :live_flow,
    gzip: false

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]
  socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket

  plug Phoenix.LiveReloader
  plug Phoenix.CodeReloader

  plug Plug.Session, @session_options

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]
  plug LiveFlow.Router
end

Application.put_env(:phoenix, :serve_endpoints, true)

Task.async(fn ->
  children =
      [
        {Phoenix.PubSub, [name: Demo.PubSub, adapter: Phoenix.PubSub.PG2]},
        LiveFlow.Endpoint
      ]

  {:ok, _} = Supervisor.start_link(children, strategy: :one_for_one)
  Process.sleep(:infinity)
end)
|> Task.await(:infinity)
