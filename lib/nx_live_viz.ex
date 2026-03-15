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

  def set_data_source(source) do
    # Deactivate all sources first
    NxLiveViz.Data.CryptoAPI.deactivate()
    NxLiveViz.Data.SystemMetrics.deactivate()

    # Activate the requested source
    case source do
      :crypto -> NxLiveViz.Data.CryptoAPI.activate()
      :system -> NxLiveViz.Data.SystemMetrics.activate()
      :simulator -> :ok  # Simulator is always running
      _ -> :ok
    end
  end
end
