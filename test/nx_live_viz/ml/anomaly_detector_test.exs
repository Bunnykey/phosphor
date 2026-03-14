defmodule NxLiveViz.ML.AnomalyDetectorTest do
  use ExUnit.Case, async: true

  alias NxLiveViz.ML.AnomalyDetector

  test "builds autoencoder model" do
    model = AnomalyDetector.build_model(input_size: 10)
    assert %Axon{} = model
  end

  test "detects anomaly from reconstruction error" do
    # Normal value should have low reconstruction error
    normal_window = List.duplicate(50.0, 10) |> Nx.tensor() |> Nx.reshape({1, 10})
    # For untrained model, just verify it returns a result
    params = AnomalyDetector.init_params(input_size: 10)
    result = AnomalyDetector.predict(params, normal_window)
    assert Map.has_key?(result, :reconstruction_error)
    assert Map.has_key?(result, :is_anomaly)
  end
end
