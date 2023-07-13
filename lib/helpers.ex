defmodule LiveFlow.Helpers do
  @moduledoc """
  Tools for working with the nodes and edges lists.
  """

  def move_node(nodes, id, position) do
    Enum.map(nodes, fn node ->
      if node.id == id do
        node = put_in(node.position.x, position["x"])
        put_in(node.position.y, position["y"])
      else
        node
      end
    end)
  end
end
