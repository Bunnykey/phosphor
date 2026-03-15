defmodule NxLiveViz.Data.SystemMetrics do
  @moduledoc "Collects BEAM memory metrics and broadcasts them as sensor data."

  use GenServer

  @interval 1_000

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def init(opts) do
    active = Keyword.get(opts, :active, false)
    if active, do: schedule_collect()
    {:ok, %{active: active}}
  end

  def activate(server \\ __MODULE__) do
    GenServer.cast(server, :activate)
  end

  def deactivate(server \\ __MODULE__) do
    GenServer.cast(server, :deactivate)
  end

  @impl true
  def handle_cast(:activate, %{active: true} = state) do
    {:noreply, state}
  end

  def handle_cast(:activate, state) do
    schedule_collect()
    {:noreply, %{state | active: true}}
  end

  def handle_cast(:deactivate, state) do
    {:noreply, %{state | active: false}}
  end

  @impl true
  def handle_info(:collect, %{active: false} = state), do: {:noreply, state}

  def handle_info(:collect, state) do
    value = collect_memory_metric()

    point = %{
      value: Float.round(value, 2),
      timestamp: DateTime.utc_now(),
      anomaly: false
    }

    NxLiveViz.broadcast_sensor_data(point)
    schedule_collect()
    {:noreply, state}
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

  defp schedule_collect do
    Process.send_after(self(), :collect, @interval)
  end
end
