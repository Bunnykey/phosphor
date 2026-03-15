defmodule NxLiveViz.Data.SystemMetrics do
  @moduledoc "Collects BEAM memory metrics and broadcasts them as sensor data."

  use NxLiveViz.Data.ActiveSource

  @impl NxLiveViz.Data.ActiveSource
  def source_interval, do: 1_000

  @impl NxLiveViz.Data.ActiveSource
  def init_state(opts) do
    %{active: Keyword.get(opts, :active, false)}
  end

  @impl NxLiveViz.Data.ActiveSource
  def collect(state) do
    value = collect_memory_metric()

    point = %{
      value: Float.round(value, 2),
      timestamp: DateTime.utc_now(),
      anomaly: false
    }

    NxLiveViz.broadcast_sensor_data(point)
    state
  end

  # Use :memsup if :os_mon is running, otherwise fall back to :erlang.memory/1.
  defp collect_memory_metric do
    if Application.get_application(:os_mon) != nil and Process.whereis(:memsup) != nil do
      mem_info = :memsup.get_system_memory_data()
      total = Keyword.get(mem_info, :total_memory, 1)
      free = Keyword.get(mem_info, :free_memory, 0)
      (total - free) / total * 100
    else
      # BEAM total memory in MB — shows relative changes over time
      :erlang.memory(:total) / (1024 * 1024)
    end
  end
end
