defmodule NxLiveViz.Data.Simulator do
  use GenServer

  @default_interval 100
  @default_anomaly_rate 0.05

  @doc "Generates a normal sine-wave value with small noise for index `i`."
  def normal_value(i) do
    :math.sin(i / 3.0) * 10 + 50 + (:rand.uniform() * 4 - 2)
  end

  # Client API

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def generate_point(opts \\ []) do
    anomaly_rate = Keyword.get(opts, :anomaly_rate, @default_anomaly_rate)
    is_anomaly = :rand.uniform() < anomaly_rate

    base_value = :math.sin(:erlang.system_time(:millisecond) / 1000.0) * 10 + 50
    noise = :rand.normal() * 2

    value =
      if is_anomaly do
        base_value + noise + Enum.random([-30, -20, 20, 30])
      else
        base_value + noise
      end

    %{
      value: value,
      timestamp: DateTime.utc_now(),
      anomaly: is_anomaly
    }
  end

  # Server callbacks

  @impl true
  def init(opts) do
    interval = Keyword.get(opts, :interval, @default_interval)
    schedule_tick(interval)
    {:ok, %{interval: interval}}
  end

  @impl true
  def handle_info(:tick, state) do
    point = generate_point()
    NxLiveViz.broadcast_sensor_data(point)
    schedule_tick(state.interval)
    {:noreply, state}
  end

  defp schedule_tick(interval) do
    Process.send_after(self(), :tick, interval)
  end
end
