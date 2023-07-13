defmodule LiveFlow do
  use Phoenix.LiveComponent

  attr(:nodes, :list, default: [])
  attr(:edges, :list, default: [])
  attr(:on_move, :any)

  def render(assigns) do
    ~H"""
    <div class="relative w-full h-full">
      <%= for edge <- @edges do %>
        <svg data-flow-is="edge" version="1.1"
            style="position: absolute"
            width="100%"
            height="100%"
            xmlns="http://www.w3.org/2000/svg"
            id={"live-flow-edge-#{edge.id}"} data-to={edge.to} data-from={edge.from} class={"live-flow-edge-#{@id} live-flow-edge-#{@id}-from-#{edge.from}"}
            >
        </svg>
      <% end %>
      <div id={@id} class="relative w-full h-full select-none" phx-hook="LiveFlow" data-ids={@node_ids} >
        <div id={"#{@id}-canvas-wrapper"} style="width: 100%; height: 100%" class="relative" phx-update="ignore">
          <canvas width="100%" height="100%" id={"#{@id}-canvas"} phx-update="ignore">
            Canvas Not Supported
          </canvas>
        </div>
        <svg id="live_flowdragging-edge" style="position: absolute;" width="100%" heigh="100%">
          <line x1="272" y1="213" x2="525" y2="228" stroke="black"></line>
        </svg>
      </div>
      <%= for node <- @nodes do %>
        <div style={"position: absolute; display: none;#{height_and_width(node)}"} id={"live-flow-node-#{node.id}-container"} data-node-id={node.id} data-flow-id={@id} phx-hook="LiveFlowNode">
          <%= for handle <- node.handles do %>
            <.handle handle={handle} node={node} />
          <% end %>
          <div
            id={"live-flow-node-#{node.id}"}
            data-flow-is="node"
            data-node-id={node.id}
            data-position-x={to_string(node.position.x)}
            data-position-y={to_string(node.position.y)}
          >
            <.live_component id={"live-flow-node-component-#{node.id}"} module={node.component} node={node} />
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  def handle(assigns) do
    ~H"""
    <%= case @handle.location do %>
      <% :top -> %>
        <div id={"live-flow-handle-#{@handle.id}"} data-flow-is="handle" data-node={@node.id} style={"height: 12px; width: 12px; position: absolute; background-color: gray; top: 0; left: #{@handle.ratio || 50}%; transform: translate(-50%, -50%)"} class={"live-flow-handle#{if @handle.primary, do: " live-flow-handle-primary"} #{@handle.class}"}/>
      <% :bottom -> %>
        <div id={"live-flow-handle-#{@handle.id}"} data-flow-is="handle" data-node={@node.id} style={"height: 12px; width: 12px; position: absolute; background-color: gray; bottom: 0; left: #{@handle.ratio || 50}%; transform: translate(-50%, 50%)"} class={"live-flow-handle#{if @handle.primary, do: " live-flow-handle-primary"} #{@handle.class}"}/>
      <% :right -> %>
        <div id={"live-flow-handle-#{@handle.id}"} data-flow-is="handle" data-node={@node.id} style={"height: 12px; width: 12px; position: absolute; background-color: gray; right: 0; top: #{@handle.ratio || 50}%; transform: translate(50%, -50%)"} class={"live-flow-handle#{if @handle.primary, do: " live-flow-handle-primary"} #{@handle.class}"}/>
      <% :left -> %>
        <div id={"live-flow-handle-#{@handle.id}"} data-flow-is="handle" data-node={@node.id} style={"height: 12px; width: 12px; position: absolute; background-color: gray; left: 0; top: #{@handle.ratio || 50}%;  transform: translate(-50%, -50%)"} class={"live-flow-handle#{if @handle.primary, do: " live-flow-handle-primary"} #{@handle.class}"}/>
    <% end %>
    """
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_node_ids()}
  end

  def handle_event("new-position", %{"id" => id, "position" => position}, socket) do
    if socket.assigns[:on_move] do
      socket.assigns.on_move.(id, position)
    end

    {:noreply, socket}
  end

  defp assign_node_ids(socket) do
    assign(socket, :node_ids, Enum.map_join(socket.assigns.nodes, ",", & &1.id))
  end

  defp height_and_width(node) do
    " "
    |> add_property("height", node.position && node.position.height)
    |> add_property("width", node.position && node.position.width)
  end

  defp add_property(style, _name, nil), do: style

  defp add_property(style, name, value) do
    "#{style} #{name}: #{value};"
  end
end
