defmodule NxLiveViz do
  @moduledoc """
  NxLiveViz keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def broadcast_sensor_data(point) do
    Phoenix.PubSub.broadcast(NxLiveViz.PubSub, "sensor:data", {:sensor_data, point})
  end
end
