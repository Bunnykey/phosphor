defmodule NxLiveViz.Data.Simulator do
  use GenServer

  @default_interval 100
  @default_anomaly_rate 0.05

  @doc "Generates a normal value with small noise for index `i` using the given pattern."
  def normal_value(i, pattern \\ :sine)

  def normal_value(i, :sine) do
    :math.sin(i / 3.0) * 10 + 50 + (:rand.uniform() * 4 - 2)
  end

  def normal_value(i, :ecg) do
    # ECG-like P-QRS-T wave pattern
    phase = rem(i, 20)
    base = 50.0

    signal =
      cond do
        phase in 3..4 -> base + 5.0
        phase == 7 -> base - 8.0
        phase == 8 -> base + 35.0
        phase == 9 -> base - 12.0
        phase in 12..14 -> base + 8.0
        true -> base
      end

    signal + (:rand.uniform() * 3 - 1.5)
  end

  def normal_value(i, :network) do
    # Network traffic: base load + periodic bursts
    base = 30.0 + :math.sin(i / 10.0) * 5
    burst = if rem(i, 15) in 0..2, do: :rand.uniform() * 40, else: 0.0
    spike = if :rand.uniform() < 0.05, do: :rand.uniform() * 60, else: 0.0
    base + burst + spike + (:rand.uniform() * 3 - 1.5)
  end

  # Client API

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def set_pattern(pattern, server \\ __MODULE__) do
    GenServer.cast(server, {:set_pattern, pattern})
  end

  def generate_point(opts \\ []) do
    anomaly_rate = Keyword.get(opts, :anomaly_rate, @default_anomaly_rate)
    pattern = Keyword.get(opts, :pattern, :sine)
    is_anomaly = :rand.uniform() < anomaly_rate

    base_value = normal_value(:erlang.system_time(:millisecond), pattern)
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
    {:ok, %{interval: interval, tick: 0, pattern: :sine}}
  end

  @impl true
  def handle_info(:tick, state) do
    point = generate_point(pattern: state.pattern)
    NxLiveViz.broadcast_sensor_data(point)
    schedule_tick(state.interval)
    {:noreply, %{state | tick: state.tick + 1}}
  end

  @impl true
  def handle_cast({:set_pattern, pattern}, state) do
    {:noreply, %{state | pattern: pattern}}
  end

  defp schedule_tick(interval) do
    Process.send_after(self(), :tick, interval)
  end
end
