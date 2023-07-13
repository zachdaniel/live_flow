defmodule LiveFlow.Node do
  defmodule Position do
    defstruct [:x, :y, height: :auto, width: :auto, drag?: false, resize?: false]
  end

  defmodule Handle do
    defstruct [:id, :class, :data, location: :top, ratio: 50, primary: false]
  end

  defstruct [:id, :component, :position, :data, handles: []]
end
