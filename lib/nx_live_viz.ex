defmodule NxLiveViz do
  @moduledoc false

  def broadcast_sensor_data(point) do
    Phoenix.PubSub.broadcast(NxLiveViz.PubSub, "sensor:data", {:sensor_data, point})
  end

  def set_data_source(source) do
    # Deactivate all sources first
    NxLiveViz.Data.Simulator.deactivate()
    NxLiveViz.Data.CryptoAPI.deactivate()
    NxLiveViz.Data.SystemMetrics.deactivate()

    # Activate only the requested source
    case source do
      :sine ->
        NxLiveViz.Data.Simulator.set_pattern(:sine)
        NxLiveViz.Data.Simulator.activate()

      :ecg ->
        NxLiveViz.Data.Simulator.set_pattern(:ecg)
        NxLiveViz.Data.Simulator.activate()

      :network ->
        NxLiveViz.Data.Simulator.set_pattern(:network)
        NxLiveViz.Data.Simulator.activate()

      :crypto ->
        NxLiveViz.Data.CryptoAPI.activate()

      :system ->
        NxLiveViz.Data.SystemMetrics.activate()

      _ ->
        {:error, :unknown_source}
    end
  end
end
