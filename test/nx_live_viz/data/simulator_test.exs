defmodule NxLiveViz.Data.SimulatorTest do
  use ExUnit.Case, async: true

  alias NxLiveViz.Data.Simulator

  test "generates sensor data point with value and timestamp" do
    point = Simulator.generate_point()
    assert is_map(point)
    assert Map.has_key?(point, :value)
    assert Map.has_key?(point, :timestamp)
    assert is_float(point.value)
  end

  test "injects anomalies at configured rate" do
    # Generate 1000 points, roughly 5% should be anomalies
    points = for _ <- 1..1000, do: Simulator.generate_point(anomaly_rate: 0.05)
    anomalies = Enum.count(points, & &1.anomaly)
    # Allow generous range: 1-15% (randomness)
    assert anomalies > 10 and anomalies < 150
  end

  test "starts as GenServer and broadcasts via PubSub" do
    Phoenix.PubSub.subscribe(NxLiveViz.PubSub, "sensor:data")
    {:ok, _pid} = Simulator.start_link(interval: 50, name: :test_simulator)

    assert_receive {:sensor_data, %{value: _, timestamp: _, anomaly: _}}, 500
    GenServer.stop(:test_simulator)
  end
end
